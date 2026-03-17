import { defineEventHandler, getRequestHeader, setResponseStatus, send } from 'h3'

const API_KEY = process.env.API_KEY

export default defineEventHandler(async (event) => {
  // Only enforce auth on API routes, and only when API_KEY is configured
  if (!API_KEY || !event.path.startsWith('/api/')) return

  const header = getRequestHeader(event, 'authorization') ?? ''
  const token = header.startsWith('Bearer ') ? header.slice(7) : ''

  if (token !== API_KEY) {
    setResponseStatus(event, 401)
    await send(event, JSON.stringify({ error: 'Unauthorized' }), 'application/json')
  }
})
