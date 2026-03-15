import { eventHandler } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'

export default eventHandler(async (event) => {
  try {
    const groups = await db.query.group.findMany({
      with: {
        characterGroups: {
          with: { character: true }
        }
      },
      orderBy: (g, { asc }) => [asc(g.name)]
    })
    return groups
  } catch (error) {
    return handleUnknownError(event, 'fetching groups', error)
  }
})
