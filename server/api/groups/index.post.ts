import { eventHandler, readBody, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { group } from '../../db/index.js'

export default eventHandler(async (event) => {
  try {
    const { name, description } = await readBody<Record<string, unknown>>(event) ?? {}

    if (!name || typeof name !== 'string' || name.trim() === '') {
      setResponseStatus(event, 400)
      return { error: 'Group name is required' }
    }

    if (description !== undefined && description !== null && typeof description !== 'string') {
      setResponseStatus(event, 400)
      return { error: 'Description must be a string or null' }
    }

    const [row] = await db.insert(group).values({
      name: (name as string).trim(),
      description: (description as string | null | undefined) ?? null,
      updatedAt: new Date().toISOString()
    }).returning()

    const result = await db.query.group.findFirst({
      where: (g, { eq }) => eq(g.id, row!.id),
      with: {
        characterGroups: {
          with: { character: true }
        }
      }
    })

    setResponseStatus(event, 201)
    return result
  } catch (error) {
    return handleUnknownError(event, 'creating group', error)
  }
})
