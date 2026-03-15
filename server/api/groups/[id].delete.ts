import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { parseId } from '../../utils/parseId.js'
import { group } from '../../db/index.js'
import { eq } from 'drizzle-orm'

export default eventHandler(async (event) => {
  try {
    const id = parseId(getRouterParam(event, 'id'))
    if (id === null) {
      setResponseStatus(event, 400)
      return { error: 'Invalid group ID' }
    }

    const [row] = await db.delete(group).where(eq(group.id, id)).returning()
    if (!row) {
      setResponseStatus(event, 404)
      return { error: 'Group not found' }
    }

    setResponseStatus(event, 204)
    return null
  } catch (error) {
    return handleUnknownError(event, 'deleting group', error)
  }
})
