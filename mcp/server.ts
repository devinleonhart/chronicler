import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { z } from 'zod'

const BASE_URL = process.env.CHRONICLER_URL ?? 'http://localhost:3000'
const API_KEY = process.env.CHRONICLER_API_KEY

async function api(method: string, path: string, body?: unknown) {
  const headers: Record<string, string> = {}
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  if (API_KEY) headers['Authorization'] = `Bearer ${API_KEY}`

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })
  const contentType = res.headers.get('content-type') ?? ''
  const data = contentType.includes('application/json') ? await res.json() : await res.text()
  return { ok: res.ok, status: res.status, data }
}

function result(data: unknown) {
  return { content: [{ type: 'text' as const, text: JSON.stringify(data, null, 2) }] }
}

const server = new McpServer({ name: 'chronicler', version: '1.0.0' })

// ── Characters ────────────────────────────────────────────────────────────────

server.tool('list_characters', 'List all characters with their group memberships', {
  name: z.string().optional().describe('Filter by name (case-insensitive partial match)'),
  groupId: z.number().int().positive().optional().describe('Filter to characters belonging to this group ID'),
  birthYear: z.number().int().positive().optional().describe('Filter to characters born in this year'),
}, async ({ name, groupId, birthYear }) => {
  const params = new URLSearchParams()
  if (name) params.set('name', name)
  if (groupId !== undefined) params.set('groupId', String(groupId))
  if (birthYear !== undefined) params.set('birthYear', String(birthYear))
  const qs = params.toString()
  const { data } = await api('GET', `/api/characters${qs ? `?${qs}` : ''}`)
  return result(data)
})

server.tool('get_character', 'Get a single character by ID', {
  id: z.number().int().positive().describe('Character ID'),
}, async ({ id }) => {
  const { data } = await api('GET', `/api/characters/${id}`)
  return result(data)
})

server.tool('get_character_events', 'Get all events for a character, ordered chronologically', {
  id: z.number().int().positive().describe('Character ID'),
}, async ({ id }) => {
  const { data } = await api('GET', `/api/characters/${id}/events`)
  return result(data)
})

server.tool('create_character', 'Create a new character', {
  name: z.string().min(1).describe('Character name'),
  birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).describe('Birth date (YYYY-MM-DD)'),
  deathDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('Death date (YYYY-MM-DD), omit if alive'),
  groupIds: z.array(z.number().int().positive()).optional().describe('Group IDs to assign this character to'),
}, async ({ name, birthDate, deathDate, groupIds }) => {
  const { data } = await api('POST', '/api/characters', { name, birthDate, deathDate, groupIds })
  return result(data)
})

server.tool('update_character', 'Update an existing character', {
  id: z.number().int().positive().describe('Character ID'),
  name: z.string().min(1).optional().describe('New name'),
  birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('New birth date (YYYY-MM-DD)'),
  deathDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullable().optional().describe('New death date (YYYY-MM-DD), or null to clear'),
  groupIds: z.array(z.number().int().positive()).optional().describe('Full replacement list of group IDs (replaces existing)'),
}, async ({ id, name, birthDate, deathDate, groupIds }) => {
  const { data } = await api('PUT', `/api/characters/${id}`, { name, birthDate, deathDate, groupIds })
  return result(data)
})

server.tool('bulk_update_characters', 'Update multiple characters in a single transaction', {
  updates: z.array(z.object({
    id: z.number().int().positive().describe('Character ID'),
    name: z.string().min(1).optional().describe('New name'),
    birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('New birth date (YYYY-MM-DD)'),
    deathDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullable().optional().describe('New death date (YYYY-MM-DD), or null to clear'),
    groupIds: z.array(z.number().int().positive()).optional().describe('Full replacement list of group IDs'),
  })).min(1).describe('List of character updates to apply'),
}, async ({ updates }) => {
  const { data } = await api('PUT', '/api/characters/bulk', { updates })
  return result(data)
})

server.tool('delete_character', 'Delete a character by ID', {
  id: z.number().int().positive().describe('Character ID'),
}, async ({ id }) => {
  const { ok, status } = await api('DELETE', `/api/characters/${id}`)
  return result({ success: ok, status })
})

// ── Groups ────────────────────────────────────────────────────────────────────

server.tool('list_groups', 'List all groups with their members', {}, async () => {
  const { data } = await api('GET', '/api/groups')
  return result(data)
})

server.tool('get_group', 'Get a single group by ID', {
  id: z.number().int().positive().describe('Group ID'),
}, async ({ id }) => {
  const { data } = await api('GET', `/api/groups/${id}`)
  return result(data)
})

server.tool('create_group', 'Create a new group', {
  name: z.string().min(1).describe('Group name'),
  description: z.string().nullable().optional().describe('Optional description'),
}, async ({ name, description }) => {
  const { data } = await api('POST', '/api/groups', { name, description })
  return result(data)
})

server.tool('update_group', 'Update an existing group', {
  id: z.number().int().positive().describe('Group ID'),
  name: z.string().min(1).optional().describe('New name'),
  description: z.string().nullable().optional().describe('New description, or null to clear'),
}, async ({ id, name, description }) => {
  const { data } = await api('PUT', `/api/groups/${id}`, { name, description })
  return result(data)
})

server.tool('delete_group', 'Delete a group by ID (does not delete its members)', {
  id: z.number().int().positive().describe('Group ID'),
}, async ({ id }) => {
  const { ok, status } = await api('DELETE', `/api/groups/${id}`)
  return result({ success: ok, status })
})

// ── Events ────────────────────────────────────────────────────────────────────

server.tool('list_events', 'List all events with their characters', {
  name: z.string().optional().describe('Filter by name (case-insensitive partial match)'),
  characterId: z.number().int().positive().optional().describe('Filter to events featuring this character ID'),
  startAfter: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('Filter to events starting on or after this date (YYYY-MM-DD)'),
  startBefore: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('Filter to events starting on or before this date (YYYY-MM-DD)'),
}, async ({ name, characterId, startAfter, startBefore }) => {
  const params = new URLSearchParams()
  if (name) params.set('name', name)
  if (characterId !== undefined) params.set('characterId', String(characterId))
  if (startAfter) params.set('startAfter', startAfter)
  if (startBefore) params.set('startBefore', startBefore)
  const qs = params.toString()
  const { data } = await api('GET', `/api/events${qs ? `?${qs}` : ''}`)
  return result(data)
})

server.tool('get_event', 'Get a single event by ID', {
  id: z.number().int().positive().describe('Event ID'),
}, async ({ id }) => {
  const { data } = await api('GET', `/api/events/${id}`)
  return result(data)
})

server.tool('create_event', 'Create a new event', {
  name: z.string().min(1).describe('Event name'),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).describe('Start date (YYYY-MM-DD)'),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullable().optional().describe('End date (YYYY-MM-DD), omit for single-day events'),
  characterIds: z.array(z.number().int().positive()).optional().describe('Character IDs to attach to this event'),
}, async ({ name, startDate, endDate, characterIds }) => {
  const { data } = await api('POST', '/api/events', { name, startDate, endDate, characterIds })
  return result(data)
})

server.tool('update_event', 'Update an existing event', {
  id: z.number().int().positive().describe('Event ID'),
  name: z.string().min(1).optional().describe('New name'),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('New start date (YYYY-MM-DD)'),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).nullable().optional().describe('New end date (YYYY-MM-DD), or null to clear'),
  characterIds: z.array(z.number().int().positive()).optional().describe('Full replacement list of character IDs (replaces existing)'),
}, async ({ id, name, startDate, endDate, characterIds }) => {
  const { data } = await api('PUT', `/api/events/${id}`, { name, startDate, endDate, characterIds })
  return result(data)
})

server.tool('add_character_to_event', 'Add a single character to an existing event', {
  eventId: z.number().int().positive().describe('Event ID'),
  characterId: z.number().int().positive().describe('Character ID to add'),
}, async ({ eventId, characterId }) => {
  const { data } = await api('POST', `/api/events/${eventId}/characters`, { characterId })
  return result(data)
})

server.tool('remove_character_from_event', 'Remove a single character from an existing event', {
  eventId: z.number().int().positive().describe('Event ID'),
  characterId: z.number().int().positive().describe('Character ID to remove'),
}, async ({ eventId, characterId }) => {
  const { data } = await api('DELETE', `/api/events/${eventId}/characters/${characterId}`)
  return result(data)
})

server.tool('add_group_to_character', 'Add a single group membership to a character', {
  characterId: z.number().int().positive().describe('Character ID'),
  groupId: z.number().int().positive().describe('Group ID to add'),
}, async ({ characterId, groupId }) => {
  const { data } = await api('POST', `/api/characters/${characterId}/groups`, { groupId })
  return result(data)
})

server.tool('remove_group_from_character', 'Remove a single group membership from a character', {
  characterId: z.number().int().positive().describe('Character ID'),
  groupId: z.number().int().positive().describe('Group ID to remove'),
}, async ({ characterId, groupId }) => {
  const { data } = await api('DELETE', `/api/characters/${characterId}/groups/${groupId}`)
  return result(data)
})

server.tool('delete_event', 'Delete an event by ID (cannot delete the Current Day event)', {
  id: z.number().int().positive().describe('Event ID'),
}, async ({ id }) => {
  const { ok, status } = await api('DELETE', `/api/events/${id}`)
  return result({ success: ok, status })
})

// ── Settings ──────────────────────────────────────────────────────────────────

server.tool('get_settings', 'Get universe settings (name, date bounds, current day)', {}, async () => {
  const { data } = await api('GET', '/api/settings')
  return result(data)
})

server.tool('update_settings', 'Update universe settings', {
  name: z.string().min(1).optional().describe('Universe name'),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('Universe start date (YYYY-MM-DD)'),
  endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('Universe end date (YYYY-MM-DD)'),
  currentDay: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe('Current day reference date (YYYY-MM-DD); also updates the Current Day event'),
}, async ({ name, startDate, endDate, currentDay }) => {
  const { data } = await api('PUT', '/api/settings', { name, startDate, endDate, currentDay })
  return result(data)
})

// ── Summary ───────────────────────────────────────────────────────────────────

server.tool('get_summary', 'Generate a plain-text narrative summary of events for one or more characters', {
  characterIds: z.array(z.number().int().positive()).min(1).describe('Character IDs to include in the summary'),
}, async ({ characterIds }) => {
  const { data } = await api('GET', `/api/summary?characterIds=${characterIds.join(',')}`)
  return { content: [{ type: 'text' as const, text: typeof data === 'string' ? data : JSON.stringify(data, null, 2) }] }
})

// ── Start ─────────────────────────────────────────────────────────────────────

const transport = new StdioServerTransport()
await server.connect(transport)
