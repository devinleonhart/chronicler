import { eventHandler, getQuery } from 'h3'
import { and, eq, ilike, inArray, like } from 'drizzle-orm'
import { db } from '../../utils/db.js'
import { character, characterGroup } from '../../db/schema.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'

export default eventHandler(async (event) => {
  try {
    const query = getQuery(event)
    const nameFilter = typeof query.name === 'string' ? query.name : undefined
    const groupId = typeof query.groupId === 'string' ? parseInt(query.groupId, 10) : undefined
    const birthYear = typeof query.birthYear === 'string' ? parseInt(query.birthYear, 10) : undefined

    const conditions = []
    if (nameFilter) conditions.push(ilike(character.name, `%${nameFilter}%`))
    if (birthYear) conditions.push(like(character.birthDate, `${birthYear}-%`))
    if (groupId) {
      conditions.push(inArray(
        character.id,
        db.select({ id: characterGroup.characterId }).from(characterGroup).where(eq(characterGroup.groupId, groupId))
      ))
    }

    const characters = await db.query.character.findMany({
      where: conditions.length ? and(...conditions) : undefined,
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
