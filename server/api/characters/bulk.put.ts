import { eventHandler, readBody, setResponseStatus } from 'h3'
import { eq, inArray } from 'drizzle-orm'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { validateUniverseDates } from '../../utils/validateUniverseDates.js'
import { character, characterGroup } from '../../db/index.js'

interface CharacterUpdate {
  id: number
  name?: string
  birthDate?: string
  deathDate?: string | null
  groupIds?: number[]
}

export default eventHandler(async (event) => {
  try {
    const { updates } = await readBody<Record<string, unknown>>(event) ?? {}

    if (!Array.isArray(updates) || updates.length === 0) {
      setResponseStatus(event, 400)
      return { error: 'updates must be a non-empty array' }
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/

    // Validate each update entry before touching the database
    for (const u of updates as CharacterUpdate[]) {
      if (typeof u.id !== 'number' || !Number.isInteger(u.id) || u.id <= 0) {
        setResponseStatus(event, 400)
        return { error: `Each update must have a positive integer id (got: ${JSON.stringify(u.id)})` }
      }
      if (u.name !== undefined && (typeof u.name !== 'string' || u.name.trim() === '')) {
        setResponseStatus(event, 400)
        return { error: `Character ${u.id}: name must be a non-empty string` }
      }
      if (u.birthDate !== undefined && (typeof u.birthDate !== 'string' || !dateRegex.test(u.birthDate))) {
        setResponseStatus(event, 400)
        return { error: `Character ${u.id}: birthDate must be YYYY-MM-DD` }
      }
      if (u.deathDate !== undefined && u.deathDate !== null && (typeof u.deathDate !== 'string' || !dateRegex.test(u.deathDate))) {
        setResponseStatus(event, 400)
        return { error: `Character ${u.id}: deathDate must be YYYY-MM-DD or null` }
      }
      if (u.groupIds !== undefined && !Array.isArray(u.groupIds)) {
        setResponseStatus(event, 400)
        return { error: `Character ${u.id}: groupIds must be an array` }
      }
    }

    // Validate universe dates across all updates in one settings fetch
    const datesToValidate: Array<{ label: string; date: string }> = []
    for (const u of updates as CharacterUpdate[]) {
      if (u.birthDate) datesToValidate.push({ label: `Character ${u.id} birthDate`, date: u.birthDate })
      if (u.deathDate) datesToValidate.push({ label: `Character ${u.id} deathDate`, date: u.deathDate })
    }
    if (datesToValidate.length > 0) {
      const universeDateError = await validateUniverseDates(datesToValidate)
      if (universeDateError) {
        setResponseStatus(event, 400)
        return { error: universeDateError }
      }
    }

    // Verify all IDs exist before modifying anything
    const ids = (updates as CharacterUpdate[]).map(u => u.id)
    const existing = await db.select({ id: character.id }).from(character).where(inArray(character.id, ids))
    const existingIds = new Set(existing.map(r => r.id))
    const missing = ids.filter(id => !existingIds.has(id))
    if (missing.length > 0) {
      setResponseStatus(event, 404)
      return { error: `Characters not found: ${missing.join(', ')}` }
    }

    // Run all updates in a single transaction
    await db.transaction(async (tx) => {
      for (const u of updates as CharacterUpdate[]) {
        const updateData: { name?: string; birthDate?: string; deathDate?: string | null; updatedAt: string } = {
          updatedAt: new Date().toISOString()
        }
        if (u.name !== undefined) updateData.name = u.name.trim()
        if (u.birthDate !== undefined) updateData.birthDate = u.birthDate
        if (u.deathDate !== undefined) updateData.deathDate = u.deathDate ?? null

        await tx.update(character).set(updateData).where(eq(character.id, u.id))

        if (u.groupIds !== undefined) {
          await tx.delete(characterGroup).where(eq(characterGroup.characterId, u.id))
          if (u.groupIds.length > 0) {
            await tx.insert(characterGroup).values(u.groupIds.map(groupId => ({ characterId: u.id, groupId })))
          }
        }
      }
    })

    // Return all updated characters with their groups
    return db.query.character.findMany({
      where: (c, { inArray }) => inArray(c.id, ids),
      with: { characterGroups: { with: { group: true } } },
      orderBy: (c, { asc }) => [asc(c.name)]
    })
  } catch (error) {
    return handleUnknownError(event, 'bulk updating characters', error)
  }
})
