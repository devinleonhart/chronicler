import { eventHandler } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'

export default eventHandler(async (eventObj) => {
  try {
    const events = await db.query.event.findMany({
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
