import { eventHandler } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { universeSettings, event } from '../../db/index.js'

export default eventHandler(async (eventObj) => {
  try {
    let settings = await db.query.universeSettings.findFirst()

    if (!settings) {
      const defaultStart = '0001-01-01'
      const defaultEnd = '1000-12-31'
      const defaultCurrent = '0500-06-15'

      const [row] = await db.insert(universeSettings).values({
        name: 'My Universe',
        startDate: defaultStart,
        endDate: defaultEnd,
        currentDay: defaultCurrent,
        updatedAt: new Date().toISOString()
      }).returning()

      settings = row!

      // Create the Current Day event
      await db.insert(event).values({
        name: 'Current Day',
        startDate: defaultCurrent,
        isCurrentDay: true,
        updatedAt: new Date().toISOString()
      })
    } else {
      // Ensure Current Day event exists
      const currentDayEvent = await db.query.event.findFirst({
        where: (e, { eq }) => eq(e.isCurrentDay, true)
      })
      if (!currentDayEvent) {
        await db.insert(event).values({
          name: 'Current Day',
          startDate: settings.currentDay,
          isCurrentDay: true,
          updatedAt: new Date().toISOString()
        })
      }
    }

    return settings
  } catch (error) {
    return handleUnknownError(eventObj, 'fetching settings', error)
  }
})
