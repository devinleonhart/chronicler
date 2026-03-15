import { eventHandler, getQuery, setResponseStatus, setHeader } from 'h3'
import { db } from '../../utils/db.js'
import { handleUnknownError } from '../../utils/handleUnknownError.js'
import { eventCharacter } from '../../db/index.js'
import { inArray } from 'drizzle-orm'

function ageAt(birthDate: string, referenceDate: string): number {
  const birth = new Date(birthDate)
  const ref = new Date(referenceDate)
  let years = ref.getFullYear() - birth.getFullYear()
  const monthDiff = ref.getMonth() - birth.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && ref.getDate() < birth.getDate())) years--
  return Math.max(0, years)
}

export default eventHandler(async (h3Event) => {
  try {
    const query = getQuery(h3Event)
    const raw = typeof query.characterIds === 'string' ? query.characterIds : ''
    const characterIds = raw
      .split(',')
      .map(s => parseInt(s.trim(), 10))
      .filter(n => !isNaN(n) && n > 0)

    if (characterIds.length === 0) {
      setResponseStatus(h3Event, 400)
      return { error: 'At least one characterId is required' }
    }

    const characters = await db.query.character.findMany({
      where: (c, { inArray: inA }) => inA(c.id, characterIds),
      orderBy: (c, { asc }) => [asc(c.name)]
    })

    if (characters.length === 0) {
      setResponseStatus(h3Event, 404)
      return { error: 'No characters found for the given IDs' }
    }

    let events: Array<{
      id: number
      name: string
      startDate: string
      endDate: string | null
      isCurrentDay: boolean
      eventCharacters: Array<{
        characterId: number
        character: { id: number; name: string; birthDate: string; deathDate: string | null }
      }>
    }> = []

    const eventRows = await db
      .selectDistinct({ eventId: eventCharacter.eventId })
      .from(eventCharacter)
      .where(inArray(eventCharacter.characterId, characterIds))

    const eventIds = eventRows.map(r => r.eventId)

    if (eventIds.length > 0) {
      events = await db.query.event.findMany({
        where: (e, { and, inArray: inA, eq }) =>
          and(inA(e.id, eventIds), eq(e.isCurrentDay, false)),
        with: {
          eventCharacters: { with: { character: true } }
        },
        orderBy: (e, { asc }) => [asc(e.startDate)]
      }) as typeof events
    }

    const selectedIds = new Set(characterIds)
    const lines: string[] = []

    if (characters.length === 1) {
      const c = characters[0]!
      const status = c.deathDate ? `Died: ${c.deathDate}` : 'Living'
      lines.push(`CHARACTER SUMMARY: ${c.name}`)
      lines.push(`Born: ${c.birthDate}  |  ${status}`)
      lines.push('')
      lines.push('Events participated in (chronological):')
    } else {
      lines.push(`SUMMARY: ${characters.map(c => c.name).join(', ')}`)
      lines.push(`Generated: ${new Date().toISOString().slice(0, 10)}`)
      lines.push('')
      lines.push('Characters:')
      for (const c of characters) {
        const status = c.deathDate ? `Died: ${c.deathDate}` : 'Living'
        lines.push(`  ${c.name.padEnd(24)}Born: ${c.birthDate}  |  ${status}`)
      }
      lines.push('')
      lines.push('Events involving any selected character (chronological):')
    }

    if (events.length === 0) {
      lines.push('')
      lines.push('  (no events found)')
    } else {
      for (let i = 0; i < events.length; i++) {
        const ev = events[i]!
        const dateRange = ev.endDate ? `${ev.startDate} – ${ev.endDate}` : ev.startDate
        lines.push('')
        lines.push(`${i + 1}. ${ev.name}  [${dateRange}]`)

        const selected = ev.eventCharacters.filter(ec => selectedIds.has(ec.characterId))
        const others = ev.eventCharacters.filter(ec => !selectedIds.has(ec.characterId))

        if (characters.length === 1) {
          const c = characters[0]!
          const age = ageAt(c.birthDate, ev.startDate)
          const othersStr = others.length > 0
            ? others.map(ec => `${ec.character.name} (age ${ageAt(ec.character.birthDate, ev.startDate)})`).join(', ')
            : 'none'
          lines.push(`   Age: ${age}  |  Also present: ${othersStr}`)
        } else {
          const selectedStr = selected.length > 0
            ? selected.map(ec => `${ec.character.name} (age ${ageAt(ec.character.birthDate, ev.startDate)})`).join(', ')
            : 'none'
          lines.push(`   Selected present:  ${selectedStr}`)
          if (others.length > 0) {
            const othersStr = others.map(ec => `${ec.character.name} (age ${ageAt(ec.character.birthDate, ev.startDate)})`).join(', ')
            lines.push(`   Others present:    ${othersStr}`)
          }
        }
      }
    }

    lines.push('')
    setHeader(h3Event, 'Content-Type', 'text/plain; charset=utf-8')
    return lines.join('\n')
  } catch (error) {
    return handleUnknownError(h3Event, 'generating summary', error)
  }
})
