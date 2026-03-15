import pg from 'pg'
import { drizzle } from 'drizzle-orm/node-postgres'
import * as schema from './index.js'
import { getDatabaseUrl } from '../utils/databaseUrls.js'

const { Pool } = pg
const pool = new Pool({ connectionString: getDatabaseUrl() })
const db = drizzle(pool, { schema })

console.log('Seeding database...')

// Create universe settings
const [settings] = await db.insert(schema.universeSettings).values({
  name: 'My Universe',
  startDate: '0001-01-01',
  endDate: '1000-12-31',
  currentDay: '0500-06-15',
  updatedAt: new Date().toISOString()
}).returning()

console.log('Created universe settings:', settings?.id)

// Create Current Day event
const [currentDayEvent] = await db.insert(schema.event).values({
  name: 'Current Day',
  startDate: '0500-06-15',
  isCurrentDay: true,
  updatedAt: new Date().toISOString()
}).returning()

console.log('Created Current Day event:', currentDayEvent?.id)

console.log('Seed complete.')
await pool.end()
