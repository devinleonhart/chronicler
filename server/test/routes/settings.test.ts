import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { createTestApp } from '../helpers.js'
import { testDb, createTestSettings } from '../setup.js'
import * as tables from '../../db/index.js'

const app = createTestApp()

describe('Settings Routes', () => {
  describe('GET /api/settings', () => {
    it('should auto-create settings if none exist', async () => {
      const response = await request(app)
        .get('/api/settings')
        .expect(200)

      expect(response.body.name).toBe('My Universe')
      expect(response.body.startDate).toBeTruthy()
      expect(response.body.currentDay).toBeTruthy()

      // Should also create Current Day event
      const currentDayEvent = await testDb.query.event.findFirst({
        where: (e, { eq }) => eq(e.isCurrentDay, true)
      })
      expect(currentDayEvent).toBeTruthy()
    })

    it('should return existing settings', async () => {
      await createTestSettings({
        startDate: '0100-01-01',
        endDate: '0900-12-31',
        currentDay: '0500-06-15'
      })

      const response = await request(app)
        .get('/api/settings')
        .expect(200)

      expect(response.body.startDate).toBe('0100-01-01')
      expect(response.body.currentDay).toBe('0500-06-15')
    })
  })

  describe('PUT /api/settings', () => {
    it('should update settings', async () => {
      await createTestSettings({
        startDate: '0100-01-01',
        endDate: '0900-12-31',
        currentDay: '0500-06-15'
      })

      const response = await request(app)
        .put('/api/settings')
        .send({ name: 'New Name', currentDay: '0600-01-01' })
        .expect(200)

      expect(response.body.name).toBe('New Name')
      expect(response.body.currentDay).toBe('0600-01-01')
    })

    it('should sync Current Day event when currentDay changes', async () => {
      await createTestSettings({
        startDate: '0100-01-01',
        endDate: '0900-12-31',
        currentDay: '0500-06-15'
      })
      await testDb.insert(tables.event).values({
        name: 'Current Day',
        startDate: '0500-06-15',
        isCurrentDay: true,
        updatedAt: new Date().toISOString()
      })

      await request(app)
        .put('/api/settings')
        .send({ currentDay: '0600-01-01' })
        .expect(200)

      const currentDayEvent = await testDb.query.event.findFirst({
        where: (e, { eq }) => eq(e.isCurrentDay, true)
      })
      expect(currentDayEvent?.startDate).toBe('0600-01-01')
    })

    it('should return 400 for invalid date format', async () => {
      await createTestSettings({
        startDate: '0100-01-01',
        endDate: '0900-12-31',
        currentDay: '0500-06-15'
      })

      await request(app)
        .put('/api/settings')
        .send({ currentDay: 'not-a-date' })
        .expect(400)
    })
  })
})
