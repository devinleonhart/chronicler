import { db } from './db.js'
import { inArray } from 'drizzle-orm'
import { character } from '../db/index.js'

/**
 * Validates that each character's lifespan overlaps with the event's date range.
 * A character can participate in an event if they were alive at any point during it:
 *   - born on or before the event ends
 *   - alive (no death date) or died on or after the event starts
 */
export async function validateCharacterLifespans(
  characterIds: number[],
  eventStartDate: string,
  eventEndDate: string | null | undefined
): Promise<string | null> {
  if (characterIds.length === 0) return null

  const effectiveEventEnd = eventEndDate ?? eventStartDate

  const characters = await db.select().from(character).where(inArray(character.id, characterIds))

  for (const char of characters) {
    if (char.birthDate > effectiveEventEnd) {
      return `Character "${char.name}" was not yet born when this event ended (born ${char.birthDate}, event ends ${effectiveEventEnd})`
    }
    if (char.deathDate && char.deathDate < eventStartDate) {
      return `Character "${char.name}" had already died before this event started (died ${char.deathDate}, event starts ${eventStartDate})`
    }
  }

  return null
}
