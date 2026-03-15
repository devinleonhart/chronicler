import { beforeAll, afterAll, beforeEach } from 'vitest'
import { drizzle } from 'drizzle-orm/node-postgres'
import pg from 'pg'
import * as schema from '../db/index.js'
import {
  universeSettings,
  character,
  characterGroup,
  group,
  event,
  eventCharacter
} from '../db/index.js'
import { sql } from 'drizzle-orm'
import { getTestDatabaseUrl } from '../utils/databaseUrls.js'

const { Pool } = pg
const testConnectionString = getTestDatabaseUrl()
const testPool = new Pool({ connectionString: testConnectionString })
export const testDb = drizzle(testPool, { schema })

beforeAll(async () => {
  await cleanDatabase()
})

beforeEach(async () => {
  await cleanDatabase()
})

afterAll(async () => {
  await testPool.end().catch(() => {})
})

export async function cleanDatabase() {
  await testDb.delete(eventCharacter).catch(() => {})
  await testDb.delete(characterGroup).catch(() => {})
  await testDb.delete(event).catch(() => {})
  await testDb.delete(character).catch(() => {})
  await testDb.delete(group).catch(() => {})
  await testDb.delete(universeSettings).catch(() => {})

  try {
    await testDb.execute(sql`
      DO $$
      BEGIN
        ALTER SEQUENCE "UniverseSettings_id_seq" RESTART WITH 1;
        ALTER SEQUENCE "Character_id_seq" RESTART WITH 1;
        ALTER SEQUENCE "Group_id_seq" RESTART WITH 1;
        ALTER SEQUENCE "Event_id_seq" RESTART WITH 1;
      END $$;
    `)
  } catch (error) {
    console.error('Error resetting sequences:', error)
  }
}

export async function createTestCharacter(data: {
  name: string
  birthDate: string
  deathDate?: string | null
}) {
  const [row] = await testDb.insert(character).values({
    name: data.name,
    birthDate: data.birthDate,
    deathDate: data.deathDate ?? null,
    updatedAt: new Date().toISOString()
  }).returning()
  return row
}

export async function createTestGroup(data: {
  name: string
  description?: string | null
}) {
  const [row] = await testDb.insert(group).values({
    name: data.name,
    description: data.description ?? null,
    updatedAt: new Date().toISOString()
  }).returning()
  return row
}

export async function createTestEvent(data: {
  name: string
  startDate: string
  endDate?: string | null
  isCurrentDay?: boolean
}) {
  const [row] = await testDb.insert(event).values({
    name: data.name,
    startDate: data.startDate,
    endDate: data.endDate ?? null,
    isCurrentDay: data.isCurrentDay ?? false,
    updatedAt: new Date().toISOString()
  }).returning()
  return row
}

export async function createTestSettings(data: {
  name?: string
  startDate: string
  endDate: string
  currentDay: string
}) {
  const [row] = await testDb.insert(universeSettings).values({
    name: data.name ?? 'Test Universe',
    startDate: data.startDate,
    endDate: data.endDate,
    currentDay: data.currentDay,
    updatedAt: new Date().toISOString()
  }).returning()
  return row
}
