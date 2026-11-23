import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { and, eq } from 'drizzle-orm'
import { db } from '../../../../utils/db.js'
import { handleUnknownError } from '../../../../utils/handleUnknownError.js'
import { parseId } from '../../../../utils/parseId.js'
import { eventCharacter } from '../../../../db/index.js'

export default eventHandler(async (eventObj) => {
  try {
    const id = parseId(getRouterParam(eventObj, 'id'))
    if (id === null) {
      setResponseStatus(eventObj, 400)
      return { error: 'Invalid event ID' }
    }

    const characterId = parseId(getRouterParam(eventObj, 'characterId'))
    if (characterId === null) {
      setResponseStatus(eventObj, 400)
      return { error: 'Invalid character ID' }
    }

    const existing = await db.query.event.findFirst({ where: (e, { eq }) => eq(e.id, id) })
    if (!existing) {
      setResponseStatus(eventObj, 404)
      return { error: 'Event not found' }
    }

    await db.delete(eventCharacter)
      .where(and(eq(eventCharacter.eventId, id), eq(eventCharacter.characterId, characterId)))

    return db.query.event.findFirst({
      where: (e, { eq }) => eq(e.id, id),
      with: { eventCharacters: { with: { character: true } } }
    })
  } catch (error) {
    return handleUnknownError(eventObj, 'removing character from event', error)
  }
})
