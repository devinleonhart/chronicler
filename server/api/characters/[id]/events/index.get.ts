import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { eq, inArray } from 'drizzle-orm'
import { db } from '../../../../utils/db.js'
import { handleUnknownError } from '../../../../utils/handleUnknownError.js'
import { parseId } from '../../../../utils/parseId.js'
import { eventCharacter } from '../../../../db/index.js'

export default eventHandler(async (event) => {
  try {
    const id = parseId(getRouterParam(event, 'id'))
    if (id === null) {
      setResponseStatus(event, 400)
      return { error: 'Invalid character ID' }
    }

    const existing = await db.query.character.findFirst({ where: (c, { eq }) => eq(c.id, id) })
    if (!existing) {
      setResponseStatus(event, 404)
      return { error: 'Character not found' }
    }

    return db.query.event.findMany({
      where: (e, { inArray }) => inArray(
        e.id,
        db.select({ id: eventCharacter.eventId }).from(eventCharacter).where(eq(eventCharacter.characterId, id))
      ),
      with: { eventCharacters: { with: { character: true } } },
      orderBy: (e, { asc }) => [asc(e.startDate)]
    })
  } catch (error) {
    return handleUnknownError(event, 'fetching character events', error)
  }
})
