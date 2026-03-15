import { eventHandler, readBody, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { validateUniverseDates } from '../../utils/validateUniverseDates.js'
import { character, characterGroup } from '../../db/index.js'

export default eventHandler(async (event) => {
  try {
    const { name, birthDate, deathDate, groupIds } = await readBody<Record<string, unknown>>(event) ?? {}

    if (!name || typeof name !== 'string' || name.trim() === '') {
      setResponseStatus(event, 400)
      return { error: 'Character name is required' }
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/
    if (!birthDate || typeof birthDate !== 'string' || !dateRegex.test(birthDate)) {
      setResponseStatus(event, 400)
      return { error: 'birthDate is required and must be a valid date string (YYYY-MM-DD)' }
    }

    if (deathDate !== undefined && deathDate !== null && (typeof deathDate !== 'string' || !dateRegex.test(deathDate))) {
      setResponseStatus(event, 400)
      return { error: 'deathDate must be a valid date string (YYYY-MM-DD) or null' }
    }

    if (groupIds !== undefined && !Array.isArray(groupIds)) {
      setResponseStatus(event, 400)
      return { error: 'groupIds must be an array' }
    }

    const universeDateError = await validateUniverseDates([
      { label: 'birthDate', date: birthDate as string },
      ...(deathDate ? [{ label: 'deathDate', date: deathDate as string }] : [])
    ])
    if (universeDateError) {
      setResponseStatus(event, 400)
      return { error: universeDateError }
    }

    const [row] = await db.insert(character).values({
      name: (name as string).trim(),
      birthDate: birthDate as string,
      deathDate: (deathDate as string | null | undefined) ?? null,
      updatedAt: new Date().toISOString()
    }).returning()

    if (Array.isArray(groupIds) && groupIds.length > 0) {
      await db.insert(characterGroup).values(
        (groupIds as number[]).map(groupId => ({
          characterId: row!.id,
          groupId
        }))
      )
    }

    const result = await db.query.character.findFirst({
      where: (c, { eq }) => eq(c.id, row!.id),
      with: {
        characterGroups: {
          with: { group: true }
        }
      }
    })

    setResponseStatus(event, 201)
    return result
  } catch (error) {
    return handleUnknownError(event, 'creating character', error)
  }
})
