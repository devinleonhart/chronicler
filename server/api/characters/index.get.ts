import { eventHandler } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'

export default eventHandler(async (event) => {
  try {
    const characters = await db.query.character.findMany({
      with: {
        characterGroups: {
          with: { group: true }
        }
      },
      orderBy: (c, { asc }) => [asc(c.name)]
    })
    return characters
  } catch (error) {
    return handleUnknownError(event, 'fetching characters', error)
  }
})
