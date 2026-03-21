import { eventHandler, getQuery } from 'h3'
import { and, eq, gte, ilike, inArray, lte } from 'drizzle-orm'
import { db } from '../../utils/db.js'
import { event, eventCharacter } from '../../db/schema.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'

export default eventHandler(async (eventObj) => {
  try {
    const query = getQuery(eventObj)
    const nameFilter = typeof query.name === 'string' ? query.name : undefined
    const characterId = typeof query.characterId === 'string' ? parseInt(query.characterId, 10) : undefined
    const startAfter = typeof query.startAfter === 'string' ? query.startAfter : undefined
    const startBefore = typeof query.startBefore === 'string' ? query.startBefore : undefined

    const conditions = []
    if (nameFilter) conditions.push(ilike(event.name, `%${nameFilter}%`))
    if (startAfter) conditions.push(gte(event.startDate, startAfter))
    if (startBefore) conditions.push(lte(event.startDate, startBefore))
    if (characterId) {
      conditions.push(inArray(
        event.id,
        db.select({ id: eventCharacter.eventId }).from(eventCharacter).where(eq(eventCharacter.characterId, characterId))
      ))
    }

    const events = await db.query.event.findMany({
      where: conditions.length ? and(...conditions) : undefined,
      with: {
        eventCharacters: {
          with: { character: true }
        }
      },
      orderBy: (e, { asc }) => [asc(e.startDate)]
    })
    return events
  } catch (error) {
    return handleUnknownError(eventObj, 'fetching events', error)
  }
})
