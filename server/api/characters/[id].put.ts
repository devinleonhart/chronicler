import { eventHandler, getRouterParam, readBody, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { parseId } from '../../utils/parseId.js'
import { validateUniverseDates } from '../../utils/validateUniverseDates.js'
import { character, characterGroup } from '../../db/index.js'
import { eq } from 'drizzle-orm'

export default eventHandler(async (event) => {
  try {
    const id = parseId(getRouterParam(event, 'id'))
    if (id === null) {
      setResponseStatus(event, 400)
      return { error: 'Invalid character ID' }
    }

    const { name, birthDate, deathDate, groupIds } = await readBody<Record<string, unknown>>(event) ?? {}

    if (name !== undefined && (typeof name !== 'string' || name.trim() === '')) {
      setResponseStatus(event, 400)
      return { error: 'Character name is required' }
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/
    if (birthDate !== undefined && (typeof birthDate !== 'string' || !dateRegex.test(birthDate))) {
      setResponseStatus(event, 400)
      return { error: 'birthDate must be a valid date string (YYYY-MM-DD)' }
    }

    if (deathDate !== undefined && deathDate !== null && (typeof deathDate !== 'string' || !dateRegex.test(deathDate as string))) {
      setResponseStatus(event, 400)
      return { error: 'deathDate must be a valid date string (YYYY-MM-DD) or null' }
    }

    if (groupIds !== undefined && !Array.isArray(groupIds)) {
      setResponseStatus(event, 400)
      return { error: 'groupIds must be an array' }
    }

    const datesToValidate: Array<{ label: string; date: string }> = []
    if (birthDate !== undefined) datesToValidate.push({ label: 'birthDate', date: birthDate as string })
    if (deathDate !== undefined && deathDate !== null) datesToValidate.push({ label: 'deathDate', date: deathDate as string })
    if (datesToValidate.length > 0) {
      const universeDateError = await validateUniverseDates(datesToValidate)
      if (universeDateError) {
        setResponseStatus(event, 400)
        return { error: universeDateError }
      }
    }

    const updateData: {
      name?: string
      birthDate?: string
      deathDate?: string | null
      updatedAt: string
    } = { updatedAt: new Date().toISOString() }

    if (name !== undefined) updateData.name = (name as string).trim()
    if (birthDate !== undefined) updateData.birthDate = birthDate as string
    if (deathDate !== undefined) updateData.deathDate = (deathDate as string | null) ?? null

    const [row] = await db.update(character)
      .set(updateData)
      .where(eq(character.id, id))
      .returning()

    if (!row) {
      setResponseStatus(event, 404)
      return { error: 'Character not found' }
    }

    if (groupIds !== undefined) {
      await db.delete(characterGroup).where(eq(characterGroup.characterId, id))
      if ((groupIds as number[]).length > 0) {
        await db.insert(characterGroup).values(
          (groupIds as number[]).map(groupId => ({
            characterId: id,
            groupId
          }))
        )
      }
    }

    return db.query.character.findFirst({
      where: (c, { eq }) => eq(c.id, id),
      with: {
        characterGroups: {
          with: { group: true }
        }
      }
    })
  } catch (error) {
    return handleUnknownError(event, 'updating character', error)
  }
})
