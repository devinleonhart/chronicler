import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { createTestApp } from '../helpers.js'
import { testDb, createTestEvent, createTestCharacter, createTestSettings } from '../setup.js'
import { eq } from 'drizzle-orm'
import * as tables from '../../db/index.js'

const app = createTestApp()

describe('Event Routes', () => {
  describe('GET /api/events', () => {
    it('should return empty array when no events', async () => {
      const response = await request(app)
        .get('/api/events')
        .expect(200)

      expect(response.body).toEqual([])
    })

    it('should return events with characters', async () => {
      await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })

      const response = await request(app)
        .get('/api/events')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('The Battle')
      expect(response.body[0].eventCharacters).toEqual([])
    })

    it('should list Current Day first', async () => {
      await createTestEvent({ name: 'Early Event', startDate: '0100-01-01' })
      await createTestEvent({ name: 'Current Day', startDate: '0500-06-15', isCurrentDay: true })

      const response = await request(app)
        .get('/api/events')
        .expect(200)

      expect(response.body[0].name).toBe('Current Day')
    })
  })

  describe('POST /api/events', () => {
    it('should create an event', async () => {
      const response = await request(app)
        .post('/api/events')
        .send({ name: 'The Battle', startDate: '0450-06-01' })
        .expect(201)

      expect(response.body.name).toBe('The Battle')
      expect(response.body.startDate).toBe('0450-06-01')
      expect(response.body.endDate).toBeNull()
      expect(response.body.isCurrentDay).toBe(false)
    })

    it('should create an event with characters', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      const response = await request(app)
        .post('/api/events')
        .send({ name: 'The Battle', startDate: '0450-06-01', characterIds: [char!.id] })
        .expect(201)

      expect(response.body.eventCharacters).toHaveLength(1)
      expect(response.body.eventCharacters[0].character.name).toBe('Aria')
    })

    it('should create an event with end date', async () => {
      const response = await request(app)
        .post('/api/events')
        .send({ name: 'Long War', startDate: '0450-06-01', endDate: '0455-12-31' })
        .expect(201)

      expect(response.body.endDate).toBe('0455-12-31')
    })

    it('should return 400 if name is missing', async () => {
      await request(app)
        .post('/api/events')
        .send({ startDate: '0450-06-01' })
        .expect(400)
    })

    it('should return 400 if startDate is missing', async () => {
      await request(app)
        .post('/api/events')
        .send({ name: 'The Battle' })
        .expect(400)
    })

    it('should return 400 if startDate is before universe start', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Ancient Event', startDate: '0050-06-01' })
        .expect(400)
    })

    it('should return 400 if startDate is after universe end', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Future Event', startDate: '1000-01-01' })
        .expect(400)
    })

    it('should return 400 if endDate is outside universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Long War', startDate: '0800-01-01', endDate: '0950-12-31' })
        .expect(400)
    })

    it('should allow dates within universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'The Battle', startDate: '0450-06-01' })
        .expect(201)
    })

    it('should return 400 if a character was not yet born when the event ended', async () => {
      const char = await createTestCharacter({ name: 'Lyra', birthDate: '0460-01-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Early Battle', startDate: '0450-01-01', endDate: '0455-12-31', characterIds: [char!.id] })
        .expect(400)
    })

    it('should return 400 if a character was already dead when the event started', async () => {
      const char = await createTestCharacter({ name: 'Old Mage', birthDate: '0300-01-01', deathDate: '0400-12-31' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Later Battle', startDate: '0450-01-01', characterIds: [char!.id] })
        .expect(400)
    })

    it('should allow a character born mid-event', async () => {
      // Event runs 0450–0460, character born 0455 — overlaps, so valid
      const char = await createTestCharacter({ name: 'Young Hero', birthDate: '0455-06-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Long Campaign', startDate: '0450-01-01', endDate: '0460-12-31', characterIds: [char!.id] })
        .expect(201)
    })

    it('should allow a character who dies mid-event', async () => {
      // Event runs 0450–0460, character dies 0455 — overlaps, so valid
      const char = await createTestCharacter({ name: 'Fallen Hero', birthDate: '0400-01-01', deathDate: '0455-06-01' })

      await request(app)
        .post('/api/events')
        .send({ name: 'Long Campaign', startDate: '0450-01-01', endDate: '0460-12-31', characterIds: [char!.id] })
        .expect(201)
    })
  })

  describe('GET /api/events/:id', () => {
    it('should return event by id', async () => {
      const ev = await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })

      const response = await request(app)
        .get(`/api/events/${ev!.id}`)
        .expect(200)

      expect(response.body.name).toBe('The Battle')
    })

    it('should return 404 for non-existent event', async () => {
      await request(app)
        .get('/api/events/9999')
        .expect(404)
    })
  })

  describe('PUT /api/events/:id', () => {
    it('should update an event', async () => {
      const ev = await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })

      const response = await request(app)
        .put(`/api/events/${ev!.id}`)
        .send({ name: 'The Great Battle', endDate: '0450-06-15' })
        .expect(200)

      expect(response.body.name).toBe('The Great Battle')
      expect(response.body.endDate).toBe('0450-06-15')
    })

    it('should update character assignments', async () => {
      const ev = await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      const response = await request(app)
        .put(`/api/events/${ev!.id}`)
        .send({ characterIds: [char!.id] })
        .expect(200)

      expect(response.body.eventCharacters).toHaveLength(1)
    })

    it('should return 404 for non-existent event', async () => {
      await request(app)
        .put('/api/events/9999')
        .send({ name: 'Ghost Event' })
        .expect(404)
    })

    it('should return 400 if updated startDate is outside universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })
      const ev = await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })

      await request(app)
        .put(`/api/events/${ev!.id}`)
        .send({ startDate: '0050-01-01' })
        .expect(400)
    })

    it('should return 400 if updated endDate is outside universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })
      const ev = await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })

      await request(app)
        .put(`/api/events/${ev!.id}`)
        .send({ endDate: '1000-01-01' })
        .expect(400)
    })

    it('should return 400 when assigning a character not yet born at event time', async () => {
      const ev = await createTestEvent({ name: 'Early Battle', startDate: '0450-01-01' })
      const char = await createTestCharacter({ name: 'Lyra', birthDate: '0500-01-01' })

      await request(app)
        .put(`/api/events/${ev!.id}`)
        .send({ characterIds: [char!.id] })
        .expect(400)
    })

    it('should return 400 when assigning a character already dead before event starts', async () => {
      const ev = await createTestEvent({ name: 'Later Battle', startDate: '0450-01-01' })
      const char = await createTestCharacter({ name: 'Old Mage', birthDate: '0300-01-01', deathDate: '0400-12-31' })

      await request(app)
        .put(`/api/events/${ev!.id}`)
        .send({ characterIds: [char!.id] })
        .expect(400)
    })
  })

  describe('DELETE /api/events/:id', () => {
    it('should delete an event', async () => {
      const ev = await createTestEvent({ name: 'The Battle', startDate: '0450-06-01' })

      await request(app)
        .delete(`/api/events/${ev!.id}`)
        .expect(204)

      const found = await testDb.select().from(tables.event).where(eq(tables.event.id, ev!.id))
      expect(found).toHaveLength(0)
    })

    it('should return 400 when trying to delete Current Day event', async () => {
      const ev = await createTestEvent({ name: 'Current Day', startDate: '0500-06-15', isCurrentDay: true })

      await request(app)
        .delete(`/api/events/${ev!.id}`)
        .expect(400)
    })

    it('should return 404 for non-existent event', async () => {
      await request(app)
        .delete('/api/events/9999')
        .expect(404)
    })
  })
})
