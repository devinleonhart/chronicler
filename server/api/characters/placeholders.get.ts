import { eventHandler, getQuery } from 'h3'
import { eq } from 'drizzle-orm'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { character } from '../../db/index.js'

export default eventHandler(async (event) => {
  try {
    const query = getQuery(event)
    const birthDate = typeof query.birthDate === 'string' ? query.birthDate : '2200-01-01'

    return db.query.character.findMany({
      where: eq(character.birthDate, birthDate),
      with: { characterGroups: { with: { group: true } } },
      orderBy: (c, { asc }) => [asc(c.name)]
    })
  } catch (error) {
    return handleUnknownError(event, 'fetching placeholder characters', error)
  }
})
