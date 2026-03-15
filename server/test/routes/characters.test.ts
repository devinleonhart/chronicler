import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { createTestApp } from '../helpers.js'
import { testDb, createTestCharacter, createTestGroup, createTestSettings } from '../setup.js'
import { eq } from 'drizzle-orm'
import * as tables from '../../db/index.js'

const app = createTestApp()

describe('Character Routes', () => {
  describe('GET /api/characters', () => {
    it('should return empty array when no characters', async () => {
      const response = await request(app)
        .get('/api/characters')
        .expect(200)

      expect(response.body).toEqual([])
    })

    it('should return characters with groups', async () => {
      await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      const response = await request(app)
        .get('/api/characters')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Aria')
      expect(response.body[0].characterGroups).toEqual([])
    })
  })

  describe('POST /api/characters', () => {
    it('should create a character', async () => {
      const response = await request(app)
        .post('/api/characters')
        .send({ name: 'Aria', birthDate: '0400-03-15' })
        .expect(201)

      expect(response.body.name).toBe('Aria')
      expect(response.body.birthDate).toBe('0400-03-15')
      expect(response.body.deathDate).toBeNull()
    })

    it('should create a character with groups', async () => {
      const grp = await createTestGroup({ name: 'Heroes' })

      const response = await request(app)
        .post('/api/characters')
        .send({ name: 'Aria', birthDate: '0400-03-15', groupIds: [grp!.id] })
        .expect(201)

      expect(response.body.characterGroups).toHaveLength(1)
      expect(response.body.characterGroups[0].group.name).toBe('Heroes')
    })

    it('should create a character with death date', async () => {
      const response = await request(app)
        .post('/api/characters')
        .send({ name: 'Fallen Hero', birthDate: '0300-01-01', deathDate: '0450-12-31' })
        .expect(201)

      expect(response.body.deathDate).toBe('0450-12-31')
    })

    it('should return 400 if name is missing', async () => {
      await request(app)
        .post('/api/characters')
        .send({ birthDate: '0400-03-15' })
        .expect(400)
    })

    it('should return 400 if birthDate is missing', async () => {
      await request(app)
        .post('/api/characters')
        .send({ name: 'Aria' })
        .expect(400)
    })

    it('should return 400 for invalid birthDate format', async () => {
      await request(app)
        .post('/api/characters')
        .send({ name: 'Aria', birthDate: 'not-a-date' })
        .expect(400)
    })

    it('should return 400 if birthDate is before universe start', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/characters')
        .send({ name: 'Ancient One', birthDate: '0050-03-15' })
        .expect(400)
    })

    it('should return 400 if birthDate is after universe end', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/characters')
        .send({ name: 'Future One', birthDate: '1000-01-01' })
        .expect(400)
    })

    it('should return 400 if deathDate is outside universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/characters')
        .send({ name: 'Fallen Hero', birthDate: '0400-01-01', deathDate: '0950-12-31' })
        .expect(400)
    })

    it('should allow dates within universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })

      await request(app)
        .post('/api/characters')
        .send({ name: 'Aria', birthDate: '0400-03-15' })
        .expect(201)
    })
  })

  describe('GET /api/characters/:id', () => {
    it('should return character by id', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      const response = await request(app)
        .get(`/api/characters/${char!.id}`)
        .expect(200)

      expect(response.body.name).toBe('Aria')
    })

    it('should return 404 for non-existent character', async () => {
      await request(app)
        .get('/api/characters/9999')
        .expect(404)
    })

    it('should return 400 for invalid id', async () => {
      await request(app)
        .get('/api/characters/abc')
        .expect(400)
    })
  })

  describe('PUT /api/characters/:id', () => {
    it('should update a character', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      const response = await request(app)
        .put(`/api/characters/${char!.id}`)
        .send({ name: 'Aria Updated', deathDate: '0490-01-01' })
        .expect(200)

      expect(response.body.name).toBe('Aria Updated')
      expect(response.body.deathDate).toBe('0490-01-01')
    })

    it('should update group assignments', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const grp = await createTestGroup({ name: 'Heroes' })

      const response = await request(app)
        .put(`/api/characters/${char!.id}`)
        .send({ groupIds: [grp!.id] })
        .expect(200)

      expect(response.body.characterGroups).toHaveLength(1)
    })

    it('should return 404 for non-existent character', async () => {
      await request(app)
        .put('/api/characters/9999')
        .send({ name: 'Ghost' })
        .expect(404)
    })

    it('should return 400 if updated birthDate is outside universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      await request(app)
        .put(`/api/characters/${char!.id}`)
        .send({ birthDate: '0050-01-01' })
        .expect(400)
    })

    it('should return 400 if updated deathDate is outside universe range', async () => {
      await createTestSettings({ startDate: '0100-01-01', endDate: '0900-12-31', currentDay: '0500-01-01' })
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      await request(app)
        .put(`/api/characters/${char!.id}`)
        .send({ deathDate: '1000-01-01' })
        .expect(400)
    })
  })

  describe('DELETE /api/characters/:id', () => {
    it('should delete a character', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      await request(app)
        .delete(`/api/characters/${char!.id}`)
        .expect(204)

      const found = await testDb.select().from(tables.character).where(eq(tables.character.id, char!.id))
      expect(found).toHaveLength(0)
    })

    it('should return 404 for non-existent character', async () => {
      await request(app)
        .delete('/api/characters/9999')
        .expect(404)
    })
  })
})
