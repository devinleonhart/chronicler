import { db } from './db.js'

export async function validateUniverseDates(
  dates: Array<{ label: string; date: string }>
): Promise<string | null> {
  const settings = await db.query.universeSettings.findFirst()
  if (!settings) return null

  for (const { label, date } of dates) {
    if (date < settings.startDate) {
      return `${label} cannot be before the universe start date (${settings.startDate})`
    }
    if (date > settings.endDate) {
      return `${label} cannot be after the universe end date (${settings.endDate})`
    }
  }
  return null
}
