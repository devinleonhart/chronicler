/**
 * Merges character data from the Blackbook CSV export into the dev database.
 *
 * - Updates 10 DB character names to their full CSV names
 * - Maps CSV Affiliation → existing DB groups (creating new groups as needed)
 * - Inserts new characters not already in the DB
 * - New characters get a placeholder birthDate of 2200-01-01 (update manually as needed)
 * - Skips characters with empty names or affiliation of "None" / "Unaffiliated"
 */

import { readFileSync } from 'fs'
import { resolve } from 'path'
import pg from 'pg'
import { drizzle } from 'drizzle-orm/node-postgres'
import * as schema from './index.js'
import { getDatabaseUrl } from '../utils/databaseUrls.js'
import { eq } from 'drizzle-orm'

const { Pool } = pg
const pool = new Pool({ connectionString: getDatabaseUrl() })
const db = drizzle(pool, { schema })

const { character, group, characterGroup } = schema

const CSV_PATH = resolve(
  process.env.HOME!,
  'Downloads/Characters 5b23832da41e4ccda07480598831efab_all.csv'
)

const PLACEHOLDER_BIRTH_DATE = '2200-01-01'

// Names in the DB that need to be updated to their CSV full names
const NAME_CORRECTIONS: Record<string, string> = {
  'Catherine':      'Catherine Wainright',
  'Fio Maple':      'Fiona "Fio" Maple',
  'Max Lionheart':  'Maximilian Lionheart',
  'Sammy Maclean':  'Samantha "Sammy" Maclean',
  'Taffy':          'Ria "Taffy" Rudiger',
  'Tiggs':          'Traci "Tiggs" Biggs',
  'Tila':           'Tila Sunrise',
  'Toby':           'Tobias "Toby" Wainwright',
  'Penka Orlav':    'Penka Orlov',
}

// CSV affiliation values that should be skipped (no group assigned)
const SKIP_AFFILIATIONS = new Set(['None', 'Unaffiliated', ''])

// Map CSV affiliation names → DB group names (for groups that already exist with different names)
const AFFILIATION_TO_GROUP: Record<string, string> = {
  'Gossamer Cell (Las Lindas)': 'Gossamer Cell / Las Lindas',
  'Ingrium':                    'Ingrium Cell',
  'Crystalis':                  'Crystalis Cell',
  'Nomad':                      'Nomad Cell',
}

function parseCSV(raw: string): Array<Record<string, string>> {
  const lines = raw.split('\n').filter(l => l.trim())
  const headers = parseCSVLine(lines[0]!)
  return lines.slice(1).map(line => {
    const values = parseCSVLine(line)
    return Object.fromEntries(headers.map((h, i) => [h, values[i] ?? '']))
  })
}

function parseCSVLine(line: string): string[] {
  const result: string[] = []
  let current = ''
  let inQuotes = false
  for (let i = 0; i < line.length; i++) {
    const ch = line[i]!
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') { current += '"'; i++ }
      else inQuotes = !inQuotes
    } else if (ch === ',' && !inQuotes) {
      result.push(current.trim())
      current = ''
    } else {
      current += ch
    }
  }
  result.push(current.trim())
  return result
}

async function main() {
  const raw = readFileSync(CSV_PATH, 'utf-8')
  const rows = parseCSV(raw).filter(r => r['Name']?.trim())

  console.log(`CSV rows: ${rows.length}`)

  // ── Step 1: Apply name corrections to existing characters ──────────────────
  const existing = await db.select({ id: character.id, name: character.name }).from(character)
  const existingByName = new Map(existing.map(c => [c.name, c.id]))

  let corrected = 0
  for (const [oldName, newName] of Object.entries(NAME_CORRECTIONS)) {
    const id = existingByName.get(oldName)
    if (id !== undefined) {
      await db.update(character).set({ name: newName }).where(eq(character.id, id))
      existingByName.delete(oldName)
      existingByName.set(newName, id)
      console.log(`  Renamed: "${oldName}" → "${newName}"`)
      corrected++
    } else {
      console.log(`  WARNING: "${oldName}" not found in DB — skipping rename`)
    }
  }
  console.log(`\nRenamed ${corrected} characters`)

  // ── Step 2: Ensure all needed groups exist ─────────────────────────────────
  const allGroups = await db.select({ id: group.id, name: group.name }).from(group)
  const groupByName = new Map(allGroups.map(g => [g.name, g.id]))

  const csvAffiliations = new Set(rows.map(r => r['Affiliation']?.trim() ?? ''))
  for (const affiliation of csvAffiliations) {
    if (SKIP_AFFILIATIONS.has(affiliation)) continue
    const dbName = AFFILIATION_TO_GROUP[affiliation] ?? affiliation
    if (!groupByName.has(dbName)) {
      const now = new Date()
      const [created] = await db.insert(group).values({ name: dbName, createdAt: now, updatedAt: now }).returning({ id: group.id })
      groupByName.set(dbName, created!.id)
      console.log(`  Created group: "${dbName}"`)
    }
  }

  // ── Step 3: Insert new characters ─────────────────────────────────────────
  // Re-read current names after corrections
  const currentChars = await db.select({ id: character.id, name: character.name }).from(character)
  const currentNames = new Set(currentChars.map(c => c.name))
  const currentByName = new Map(currentChars.map(c => [c.name, c.id]))

  const toInsert = rows.filter(r => !currentNames.has(r['Name']!.trim()))
  console.log(`\nInserting ${toInsert.length} new characters...`)

  for (const row of toInsert) {
    const name = row['Name']!.trim()
    const now = new Date()
    const [inserted] = await db.insert(character)
      .values({ name, birthDate: PLACEHOLDER_BIRTH_DATE, createdAt: now, updatedAt: now })
      .returning({ id: character.id })
    currentByName.set(name, inserted!.id)
    process.stdout.write('.')
  }
  console.log('\nDone inserting.')

  // ── Step 4: Assign group memberships ──────────────────────────────────────
  // Get existing characterGroup assignments to avoid duplicates
  const existingMemberships = await db.select({
    characterId: characterGroup.characterId,
    groupId: characterGroup.groupId
  }).from(characterGroup)
  const membershipSet = new Set(existingMemberships.map(m => `${m.characterId}:${m.groupId}`))

  let assigned = 0
  for (const row of rows) {
    const name = row['Name']!.trim()
    const affiliation = row['Affiliation']?.trim() ?? ''
    if (SKIP_AFFILIATIONS.has(affiliation)) continue

    const charId = currentByName.get(name)
    const dbGroupName = AFFILIATION_TO_GROUP[affiliation] ?? affiliation
    const grpId = groupByName.get(dbGroupName)

    if (!charId || !grpId) continue

    const key = `${charId}:${grpId}`
    if (!membershipSet.has(key)) {
      await db.insert(characterGroup).values({ characterId: charId, groupId: grpId })
      membershipSet.add(key)
      assigned++
    }
  }

  console.log(`Assigned ${assigned} new group memberships`)

  // ── Summary ────────────────────────────────────────────────────────────────
  const finalCount = await db.select({ id: character.id }).from(character)
  console.log(`\n✓ Merge complete. Total characters in DB: ${finalCount.length}`)
  console.log(`  Note: ${toInsert.length} new characters have placeholder birthDate ${PLACEHOLDER_BIRTH_DATE}`)

  process.exit(0)
}

main().catch(err => { console.error(err); process.exit(1) })
