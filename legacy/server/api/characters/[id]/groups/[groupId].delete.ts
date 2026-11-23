import { eventHandler, getRouterParam, setResponseStatus } from 'h3'
import { and, eq } from 'drizzle-orm'
import { db } from '../../../../utils/db.js'
import { handleUnknownError } from '../../../../utils/handleUnknownError.js'
import { parseId } from '../../../../utils/parseId.js'
import { characterGroup } from '../../../../db/index.js'

export default eventHandler(async (event) => {
  try {
    const id = parseId(getRouterParam(event, 'id'))
    if (id === null) {
      setResponseStatus(event, 400)
      return { error: 'Invalid character ID' }
    }

    const groupId = parseId(getRouterParam(event, 'groupId'))
    if (groupId === null) {
      setResponseStatus(event, 400)
      return { error: 'Invalid group ID' }
    }

    const existing = await db.query.character.findFirst({ where: (c, { eq }) => eq(c.id, id) })
    if (!existing) {
      setResponseStatus(event, 404)
      return { error: 'Character not found' }
    }

    await db.delete(characterGroup)
      .where(and(eq(characterGroup.characterId, id), eq(characterGroup.groupId, groupId)))

    return db.query.character.findFirst({
      where: (c, { eq }) => eq(c.id, id),
      with: { characterGroups: { with: { group: true } } }
    })
  } catch (error) {
    return handleUnknownError(event, 'removing group from character', error)
  }
})
