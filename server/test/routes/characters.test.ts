import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { createTestApp } from '../helpers.js'
import { testDb, createTestCharacter, createTestGroup, createTestEvent, createTestSettings } from '../setup.js'
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

  describe('GET /api/characters (filters)', () => {
    it('should filter by name (case-insensitive partial match)', async () => {
      await createTestCharacter({ name: 'Aria the Bold', birthDate: '0400-03-15' })
      await createTestCharacter({ name: 'Bran the Wise', birthDate: '0410-05-01' })

      const response = await request(app)
        .get('/api/characters?name=aria')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Aria the Bold')
    })

    it('should filter by groupId', async () => {
      const grp = await createTestGroup({ name: 'Heroes' })
      const char1 = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      await createTestCharacter({ name: 'Bran', birthDate: '0410-05-01' })
      await testDb.insert(tables.characterGroup).values({ characterId: char1!.id, groupId: grp!.id })

      const response = await request(app)
        .get(`/api/characters?groupId=${grp!.id}`)
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Aria')
    })

    it('should filter by birthYear', async () => {
      await createTestCharacter({ name: 'Aria', birthDate: '1999-03-15' })
      await createTestCharacter({ name: 'Bran', birthDate: '2001-05-01' })

      const response = await request(app)
        .get('/api/characters?birthYear=2001')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Bran')
    })
  })

  describe('GET /api/characters/placeholders', () => {
    it('should return characters with default placeholder date 2200-01-01', async () => {
      await createTestCharacter({ name: 'Placeholder', birthDate: '2200-01-01' })
      await createTestCharacter({ name: 'Real', birthDate: '0400-03-15' })

      const response = await request(app)
        .get('/api/characters/placeholders')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Placeholder')
    })

    it('should return characters with a custom placeholder date', async () => {
      await createTestCharacter({ name: 'Placeholder', birthDate: '1111-01-01' })
      await createTestCharacter({ name: 'Real', birthDate: '0400-03-15' })

      const response = await request(app)
        .get('/api/characters/placeholders?birthDate=1111-01-01')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Placeholder')
    })

    it('should return empty array when no placeholders exist', async () => {
      await createTestCharacter({ name: 'Real', birthDate: '0400-03-15' })

      const response = await request(app)
        .get('/api/characters/placeholders')
        .expect(200)

      expect(response.body).toEqual([])
    })
  })

  describe('GET /api/characters/:id/events', () => {
    it('should return events for a character ordered by startDate', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const ev1 = await createTestEvent({ name: 'Late Battle', startDate: '0500-06-01' })
      const ev2 = await createTestEvent({ name: 'Early Battle', startDate: '0450-01-01' })
      await testDb.insert(tables.eventCharacter).values({ eventId: ev1!.id, characterId: char!.id })
      await testDb.insert(tables.eventCharacter).values({ eventId: ev2!.id, characterId: char!.id })

      const response = await request(app)
        .get(`/api/characters/${char!.id}/events`)
        .expect(200)

      expect(response.body).toHaveLength(2)
      expect(response.body[0].name).toBe('Early Battle')
      expect(response.body[1].name).toBe('Late Battle')
    })

    it('should return empty array when character has no events', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      const response = await request(app)
        .get(`/api/characters/${char!.id}/events`)
        .expect(200)

      expect(response.body).toEqual([])
    })

    it('should return 404 for non-existent character', async () => {
      await request(app)
        .get('/api/characters/9999/events')
        .expect(404)
    })

    it('should return 400 for invalid character id', async () => {
      await request(app)
        .get('/api/characters/abc/events')
        .expect(400)
    })
  })

  describe('POST /api/characters/:id/groups', () => {
    it('should add a group to a character', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const grp = await createTestGroup({ name: 'Heroes' })

      const response = await request(app)
        .post(`/api/characters/${char!.id}/groups`)
        .send({ groupId: grp!.id })
        .expect(200)

      expect(response.body.characterGroups).toHaveLength(1)
      expect(response.body.characterGroups[0].group.name).toBe('Heroes')
    })

    it('should be idempotent (adding same group twice is fine)', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const grp = await createTestGroup({ name: 'Heroes' })

      await request(app).post(`/api/characters/${char!.id}/groups`).send({ groupId: grp!.id }).expect(200)
      const response = await request(app).post(`/api/characters/${char!.id}/groups`).send({ groupId: grp!.id }).expect(200)

      expect(response.body.characterGroups).toHaveLength(1)
    })

    it('should return 404 for non-existent character', async () => {
      const grp = await createTestGroup({ name: 'Heroes' })
      await request(app)
        .post('/api/characters/9999/groups')
        .send({ groupId: grp!.id })
        .expect(404)
    })

    it('should return 404 for non-existent group', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      await request(app)
        .post(`/api/characters/${char!.id}/groups`)
        .send({ groupId: 9999 })
        .expect(404)
    })

    it('should return 400 for invalid groupId', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      await request(app)
        .post(`/api/characters/${char!.id}/groups`)
        .send({ groupId: 'bad' })
        .expect(400)
    })
  })

  describe('DELETE /api/characters/:id/groups/:groupId', () => {
    it('should remove a group from a character', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const grp = await createTestGroup({ name: 'Heroes' })
      await testDb.insert(tables.characterGroup).values({ characterId: char!.id, groupId: grp!.id })

      const response = await request(app)
        .delete(`/api/characters/${char!.id}/groups/${grp!.id}`)
        .expect(200)

      expect(response.body.characterGroups).toHaveLength(0)
    })

    it('should return 404 for non-existent character', async () => {
      await request(app)
        .delete('/api/characters/9999/groups/1')
        .expect(404)
    })

    it('should return 400 for invalid character id', async () => {
      await request(app)
        .delete('/api/characters/abc/groups/1')
        .expect(400)
    })

    it('should return 400 for invalid group id', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      await request(app)
        .delete(`/api/characters/${char!.id}/groups/abc`)
        .expect(400)
    })
  })

  describe('PUT /api/characters/bulk', () => {
    it('should update multiple characters in one request', async () => {
      const char1 = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const char2 = await createTestCharacter({ name: 'Bran', birthDate: '0410-05-01' })

      const response = await request(app)
        .put('/api/characters/bulk')
        .send({
          updates: [
            { id: char1!.id, name: 'Aria Updated' },
            { id: char2!.id, name: 'Bran Updated' },
          ]
        })
        .expect(200)

      const names = response.body.map((c: { name: string }) => c.name).sort()
      expect(names).toEqual(['Aria Updated', 'Bran Updated'])
    })

    it('should update group assignments in bulk', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })
      const grp = await createTestGroup({ name: 'Heroes' })

      const response = await request(app)
        .put('/api/characters/bulk')
        .send({ updates: [{ id: char!.id, groupIds: [grp!.id] }] })
        .expect(200)

      expect(response.body[0].characterGroups).toHaveLength(1)
    })

    it('should return 400 if updates is empty', async () => {
      await request(app)
        .put('/api/characters/bulk')
        .send({ updates: [] })
        .expect(400)
    })

    it('should return 400 if updates is missing', async () => {
      await request(app)
        .put('/api/characters/bulk')
        .send({})
        .expect(400)
    })

    it('should return 404 if any character id does not exist', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      await request(app)
        .put('/api/characters/bulk')
        .send({ updates: [{ id: char!.id, name: 'OK' }, { id: 9999, name: 'Ghost' }] })
        .expect(404)
    })

    it('should return 400 for invalid birthDate format in bulk update', async () => {
      const char = await createTestCharacter({ name: 'Aria', birthDate: '0400-03-15' })

      await request(app)
        .put('/api/characters/bulk')
        .send({ updates: [{ id: char!.id, birthDate: 'not-a-date' }] })
        .expect(400)
    })
  })
})
