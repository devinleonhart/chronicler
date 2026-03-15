import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { parseId } from '../../utils/parseId.js'

export default eventHandler(async (event) => {
  try {
    const id = parseId(getRouterParam(event, 'id'))
    if (id === null) {
      setResponseStatus(event, 400)
      return { error: 'Invalid group ID' }
    }

    const result = await db.query.group.findFirst({
      where: (g, { eq }) => eq(g.id, id),
      with: {
        characterGroups: {
          with: { character: true }
        }
      }
    })

    if (!result) {
      setResponseStatus(event, 404)
      return { error: 'Group not found' }
    }

    return result
  } catch (error) {
    return handleUnknownError(event, 'fetching group', error)
  }
})
