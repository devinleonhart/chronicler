import { eventHandler, readBody, setResponseStatus } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { universeSettings, event } from '../../db/index.js'
import { eq } from 'drizzle-orm'

export default eventHandler(async (eventObj) => {
  try {
    const { name, startDate, endDate, currentDay } = await readBody<Record<string, unknown>>(eventObj) ?? {}

    if (name !== undefined && (typeof name !== 'string' || name.trim() === '')) {
      setResponseStatus(eventObj, 400)
      return { error: 'Name must be a non-empty string' }
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/
    if (startDate !== undefined && (typeof startDate !== 'string' || !dateRegex.test(startDate))) {
      setResponseStatus(eventObj, 400)
      return { error: 'startDate must be a valid date string (YYYY-MM-DD)' }
    }
    if (endDate !== undefined && (typeof endDate !== 'string' || !dateRegex.test(endDate))) {
      setResponseStatus(eventObj, 400)
      return { error: 'endDate must be a valid date string (YYYY-MM-DD)' }
    }
    if (currentDay !== undefined && (typeof currentDay !== 'string' || !dateRegex.test(currentDay))) {
      setResponseStatus(eventObj, 400)
      return { error: 'currentDay must be a valid date string (YYYY-MM-DD)' }
    }

    const updateData: {
      name?: string
      startDate?: string
      endDate?: string
      currentDay?: string
      updatedAt: string
    } = { updatedAt: new Date().toISOString() }

    if (name !== undefined) updateData.name = (name as string).trim()
    if (startDate !== undefined) updateData.startDate = startDate as string
    if (endDate !== undefined) updateData.endDate = endDate as string
    if (currentDay !== undefined) updateData.currentDay = currentDay as string

    const existing = await db.query.universeSettings.findFirst()
    let row
    if (existing) {
      const [updated] = await db.update(universeSettings)
        .set(updateData)
        .where(eq(universeSettings.id, existing.id))
        .returning()
      row = updated
    } else {
      setResponseStatus(eventObj, 404)
      return { error: 'Settings not found' }
    }

    // Sync Current Day event date if currentDay changed
    if (currentDay !== undefined) {
      await db.update(event)
        .set({ startDate: currentDay as string, updatedAt: new Date().toISOString() })
        .where(eq(event.isCurrentDay, true))
    }

    return row
  } catch (error) {
    return handleUnknownError(eventObj, 'updating settings', error)
  }
})
