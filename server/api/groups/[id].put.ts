import { eventHandler, getRouterParam, readBody, setResponseStatus } from 'h3'
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

    const { name, description } = await readBody<Record<string, unknown>>(event) ?? {}

    if (name !== undefined && (typeof name !== 'string' || name.trim() === '')) {
      setResponseStatus(event, 400)
      return { error: 'Group name is required' }
    }

    if (description !== undefined && description !== null && typeof description !== 'string') {
      setResponseStatus(event, 400)
      return { error: 'Description must be a string or null' }
    }

    const updateData: {
      name?: string
      description?: string | null
      updatedAt: string
    } = { updatedAt: new Date().toISOString() }

    if (name !== undefined) updateData.name = (name as string).trim()
    if (description !== undefined) updateData.description = (description as string | null) ?? null

    const [row] = await db.update(group)
      .set(updateData)
      .where(eq(group.id, id))
      .returning()

    if (!row) {
      setResponseStatus(event, 404)
      return { error: 'Group not found' }
    }

    return db.query.group.findFirst({
      where: (g, { eq }) => eq(g.id, id),
      with: {
        characterGroups: {
          with: { character: true }
        }
      }
    })
  } catch (error) {
    return handleUnknownError(event, 'updating group', error)
  }
})
