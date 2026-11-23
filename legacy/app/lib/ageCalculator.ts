export interface AgeResult {
  years: number
  deceased: boolean
}

/**
 * Calculate a character's age at a given reference date.
 * All dates are YYYY-MM-DD strings.
 * If the reference date is after the character's death date, returns age at death
 * and marks deceased = true.
 */
export function calculateAge(birthDate: string, referenceDate: string, deathDate?: string | null): AgeResult {
  const birth = new Date(birthDate)
  const ref = new Date(referenceDate)

  let deceased = false
  let effectiveRef = ref

  if (deathDate) {
    const death = new Date(deathDate)
    if (ref > death) {
      effectiveRef = death
      deceased = true
    }
  }

  let years = effectiveRef.getFullYear() - birth.getFullYear()
  const monthDiff = effectiveRef.getMonth() - birth.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && effectiveRef.getDate() < birth.getDate())) {
    years--
  }

  return { years: Math.max(0, years), deceased }
}

/**
 * Format an age result as a display string.
 */
export function formatAge(age: AgeResult): string {
  if (age.deceased) {
    return `${age.years} (deceased)`
  }
  return `${age.years}`
}
