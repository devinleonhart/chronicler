import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { parseId } from '../../utils/parseId.js'
import { event } from '../../db/index.js'
import { eq } from 'drizzle-orm'

export default eventHandler(async (eventObj) => {
  try {
    const id = parseId(getRouterParam(eventObj, 'id'))
    if (id === null) {
      setResponseStatus(eventObj, 400)
      return { error: 'Invalid event ID' }
    }

    const existing = await db.query.event.findFirst({
      where: (e, { eq }) => eq(e.id, id)
    })

    if (!existing) {
      setResponseStatus(eventObj, 404)
      return { error: 'Event not found' }
    }

    if (existing.isCurrentDay) {
      setResponseStatus(eventObj, 400)
      return { error: 'Cannot delete the Current Day event' }
    }

    await db.delete(event).where(eq(event.id, id))

    setResponseStatus(eventObj, 204)
    return null
  } catch (error) {
    return handleUnknownError(eventObj, 'deleting event', error)
  }
})
