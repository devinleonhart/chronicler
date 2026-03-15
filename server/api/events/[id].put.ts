import { eventHandler, getRouterParam, readBody, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { parseId } from '../../utils/parseId.js'
import { validateUniverseDates } from '../../utils/validateUniverseDates.js'
import { validateCharacterLifespans } from '../../utils/validateCharacterLifespans.js'
import { event, eventCharacter } from '../../db/index.js'
import { eq } from 'drizzle-orm'

export default eventHandler(async (eventObj) => {
  try {
    const id = parseId(getRouterParam(eventObj, 'id'))
    if (id === null) {
      setResponseStatus(eventObj, 400)
      return { error: 'Invalid event ID' }
    }

    const { name, startDate, endDate, characterIds } = await readBody<Record<string, unknown>>(eventObj) ?? {}

    if (name !== undefined && (typeof name !== 'string' || name.trim() === '')) {
      setResponseStatus(eventObj, 400)
      return { error: 'Event name is required' }
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/
    if (startDate !== undefined && (typeof startDate !== 'string' || !dateRegex.test(startDate))) {
      setResponseStatus(eventObj, 400)
      return { error: 'startDate must be a valid date string (YYYY-MM-DD)' }
    }

    if (endDate !== undefined && endDate !== null && (typeof endDate !== 'string' || !dateRegex.test(endDate as string))) {
      setResponseStatus(eventObj, 400)
      return { error: 'endDate must be a valid date string (YYYY-MM-DD) or null' }
    }

    if (characterIds !== undefined && !Array.isArray(characterIds)) {
      setResponseStatus(eventObj, 400)
      return { error: 'characterIds must be an array' }
    }

    const datesToValidate: Array<{ label: string; date: string }> = []
    if (startDate !== undefined) datesToValidate.push({ label: 'startDate', date: startDate as string })
    if (endDate !== undefined && endDate !== null) datesToValidate.push({ label: 'endDate', date: endDate as string })
    if (datesToValidate.length > 0) {
      const universeDateError = await validateUniverseDates(datesToValidate)
      if (universeDateError) {
        setResponseStatus(eventObj, 400)
        return { error: universeDateError }
      }
    }

    if (Array.isArray(characterIds) && characterIds.length > 0) {
      // Determine effective event dates: use incoming values if provided, else look up current
      let effectiveStart = startDate as string | undefined
      let effectiveEnd = endDate as string | null | undefined
      if (effectiveStart === undefined || effectiveEnd === undefined) {
        const existing = await db.query.event.findFirst({ where: (e, { eq }) => eq(e.id, id) })
        if (!existing) {
          setResponseStatus(eventObj, 404)
          return { error: 'Event not found' }
        }
        if (effectiveStart === undefined) effectiveStart = existing.startDate
        if (effectiveEnd === undefined) effectiveEnd = existing.endDate
      }
      const lifespanError = await validateCharacterLifespans(
        characterIds as number[],
        effectiveStart!,
        effectiveEnd
      )
      if (lifespanError) {
        setResponseStatus(eventObj, 400)
        return { error: lifespanError }
      }
    }

    const updateData: {
      name?: string
      startDate?: string
      endDate?: string | null
      updatedAt: string
    } = { updatedAt: new Date().toISOString() }

    if (name !== undefined) updateData.name = (name as string).trim()
    if (startDate !== undefined) updateData.startDate = startDate as string
    if (endDate !== undefined) updateData.endDate = (endDate as string | null) ?? null

    const [row] = await db.update(event)
      .set(updateData)
      .where(eq(event.id, id))
      .returning()

    if (!row) {
      setResponseStatus(eventObj, 404)
      return { error: 'Event not found' }
    }

    if (characterIds !== undefined) {
      await db.delete(eventCharacter).where(eq(eventCharacter.eventId, id))
      if ((characterIds as number[]).length > 0) {
        await db.insert(eventCharacter).values(
          (characterIds as number[]).map(characterId => ({
            eventId: id,
            characterId
          }))
        )
      }
    }

    return db.query.event.findFirst({
      where: (e, { eq }) => eq(e.id, id),
      with: {
        eventCharacters: {
          with: { character: true }
        }
      }
    })
  } catch (error) {
    return handleUnknownError(eventObj, 'updating event', error)
  }
})
