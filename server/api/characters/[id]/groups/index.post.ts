import { eventHandler, getRouterParam, readBody, setResponseStatus } from 'h3'
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

    const { groupId } = await readBody<Record<string, unknown>>(event) ?? {}

    if (typeof groupId !== 'number' || !Number.isInteger(groupId) || groupId <= 0) {
      setResponseStatus(event, 400)
      return { error: 'groupId must be a positive integer' }
    }

    const existing = await db.query.character.findFirst({ where: (c, { eq }) => eq(c.id, id) })
    if (!existing) {
      setResponseStatus(event, 404)
      return { error: 'Character not found' }
    }

    const group = await db.query.group.findFirst({ where: (g, { eq }) => eq(g.id, groupId) })
    if (!group) {
      setResponseStatus(event, 404)
      return { error: 'Group not found' }
    }

    await db.insert(characterGroup)
      .values({ characterId: id, groupId })
      .onConflictDoNothing()

    return db.query.character.findFirst({
      where: (c, { eq }) => eq(c.id, id),
      with: { characterGroups: { with: { group: true } } }
    })
  } catch (error) {
    return handleUnknownError(event, 'adding group to character', error)
  }
})
