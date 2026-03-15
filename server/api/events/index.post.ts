import { eventHandler, readBody, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { validateUniverseDates } from '../../utils/validateUniverseDates.js'
import { event, eventCharacter } from '../../db/index.js'

export default eventHandler(async (eventObj) => {
  try {
    const { name, startDate, endDate, characterIds } = await readBody<Record<string, unknown>>(eventObj) ?? {}

    if (!name || typeof name !== 'string' || name.trim() === '') {
      setResponseStatus(eventObj, 400)
      return { error: 'Event name is required' }
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/
    if (!startDate || typeof startDate !== 'string' || !dateRegex.test(startDate)) {
      setResponseStatus(eventObj, 400)
      return { error: 'startDate is required and must be a valid date string (YYYY-MM-DD)' }
    }

    if (endDate !== undefined && endDate !== null && (typeof endDate !== 'string' || !dateRegex.test(endDate as string))) {
      setResponseStatus(eventObj, 400)
      return { error: 'endDate must be a valid date string (YYYY-MM-DD) or null' }
    }

    if (characterIds !== undefined && !Array.isArray(characterIds)) {
      setResponseStatus(eventObj, 400)
      return { error: 'characterIds must be an array' }
    }

    const universeDateError = await validateUniverseDates([
      { label: 'startDate', date: startDate as string },
      ...(endDate ? [{ label: 'endDate', date: endDate as string }] : [])
    ])
    if (universeDateError) {
      setResponseStatus(eventObj, 400)
      return { error: universeDateError }
    }

    const [row] = await db.insert(event).values({
      name: (name as string).trim(),
      startDate: startDate as string,
      endDate: (endDate as string | null | undefined) ?? null,
      isCurrentDay: false,
      updatedAt: new Date().toISOString()
    }).returning()

    if (Array.isArray(characterIds) && characterIds.length > 0) {
      await db.insert(eventCharacter).values(
        (characterIds as number[]).map(characterId => ({
          eventId: row!.id,
          characterId
        }))
      )
    }

    const result = await db.query.event.findFirst({
      where: (e, { eq }) => eq(e.id, row!.id),
      with: {
        eventCharacters: {
          with: { character: true }
        }
      }
    })

    setResponseStatus(eventObj, 201)
    return result
  } catch (error) {
    return handleUnknownError(eventObj, 'creating event', error)
  }
})
