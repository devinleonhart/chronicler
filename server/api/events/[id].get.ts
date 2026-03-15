import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { parseId } from '../../utils/parseId.js'

export default eventHandler(async (eventObj) => {
  try {
    const id = parseId(getRouterParam(eventObj, 'id'))
    if (id === null) {
      setResponseStatus(eventObj, 400)
      return { error: 'Invalid event ID' }
    }

    const result = await db.query.event.findFirst({
      where: (e, { eq }) => eq(e.id, id),
      with: {
        eventCharacters: {
          with: { character: true }
        }
      }
    })

    if (!result) {
      setResponseStatus(eventObj, 404)
      return { error: 'Event not found' }
    }

    return result
  } catch (error) {
    return handleUnknownError(eventObj, 'fetching event', error)
  }
})
