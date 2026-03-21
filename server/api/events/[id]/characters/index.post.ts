import { eventHandler, getRouterParam, readBody, setResponseStatus } from 'h3'
import { eq } from 'drizzle-orm'
import { db } from '../../../../utils/db.js'
import { handleUnknownError } from '../../../../utils/handleUnknownError.js'
import { parseId } from '../../../../utils/parseId.js'
import { validateCharacterLifespans } from '../../../../utils/validateCharacterLifespans.js'
import { eventCharacter } from '../../../../db/index.js'

export default eventHandler(async (eventObj) => {
  try {
    const id = parseId(getRouterParam(eventObj, 'id'))
    if (id === null) {
      setResponseStatus(eventObj, 400)
      return { error: 'Invalid event ID' }
    }

    const { characterId } = await readBody<Record<string, unknown>>(eventObj) ?? {}

    if (typeof characterId !== 'number' || !Number.isInteger(characterId) || characterId <= 0) {
      setResponseStatus(eventObj, 400)
      return { error: 'characterId must be a positive integer' }
    }

    const existing = await db.query.event.findFirst({ where: (e, { eq }) => eq(e.id, id) })
    if (!existing) {
      setResponseStatus(eventObj, 404)
      return { error: 'Event not found' }
    }

    const lifespanError = await validateCharacterLifespans([characterId], existing.startDate, existing.endDate)
    if (lifespanError) {
      setResponseStatus(eventObj, 400)
      return { error: lifespanError }
    }

    await db.insert(eventCharacter)
      .values({ eventId: id, characterId })
      .onConflictDoNothing()

    return db.query.event.findFirst({
      where: (e, { eq }) => eq(e.id, id),
      with: { eventCharacters: { with: { character: true } } }
    })
  } catch (error) {
    return handleUnknownError(eventObj, 'adding character to event', error)
  }
})
