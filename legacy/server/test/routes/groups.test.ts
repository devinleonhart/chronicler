import { describe, it, expect } from 'vitest'
import request from 'supertest'
import { createTestApp } from '../helpers.js'
import { testDb, createTestGroup } from '../setup.js'
import { eq } from 'drizzle-orm'
import * as tables from '../../db/index.js'

const app = createTestApp()

describe('Group Routes', () => {
  describe('GET /api/groups', () => {
    it('should return empty array when no groups', async () => {
      const response = await request(app)
        .get('/api/groups')
        .expect(200)

      expect(response.body).toEqual([])
    })

    it('should return groups with characters', async () => {
      await createTestGroup({ name: 'Heroes', description: 'The good guys' })

      const response = await request(app)
        .get('/api/groups')
        .expect(200)

      expect(response.body).toHaveLength(1)
      expect(response.body[0].name).toBe('Heroes')
      expect(response.body[0].characterGroups).toEqual([])
    })
  })

  describe('POST /api/groups', () => {
    it('should create a group', async () => {
      const response = await request(app)
        .post('/api/groups')
        .send({ name: 'Heroes', description: 'Brave adventurers' })
        .expect(201)

      expect(response.body.name).toBe('Heroes')
      expect(response.body.description).toBe('Brave adventurers')
    })

    it('should create a group without description', async () => {
      const response = await request(app)
        .post('/api/groups')
        .send({ name: 'Villains' })
        .expect(201)

      expect(response.body.description).toBeNull()
    })

    it('should return 400 if name is missing', async () => {
      await request(app)
        .post('/api/groups')
        .send({ description: 'No name' })
        .expect(400)
    })
  })

  describe('GET /api/groups/:id', () => {
    it('should return group by id', async () => {
      const grp = await createTestGroup({ name: 'Heroes' })

      const response = await request(app)
        .get(`/api/groups/${grp!.id}`)
        .expect(200)

      expect(response.body.name).toBe('Heroes')
    })

    it('should return 404 for non-existent group', async () => {
      await request(app)
        .get('/api/groups/9999')
        .expect(404)
    })
  })

  describe('PUT /api/groups/:id', () => {
    it('should update a group', async () => {
      const grp = await createTestGroup({ name: 'Heroes' })

      const response = await request(app)
        .put(`/api/groups/${grp!.id}`)
        .send({ name: 'Updated Heroes', description: 'Even braver' })
        .expect(200)

      expect(response.body.name).toBe('Updated Heroes')
      expect(response.body.description).toBe('Even braver')
    })

    it('should return 404 for non-existent group', async () => {
      await request(app)
        .put('/api/groups/9999')
        .send({ name: 'Ghost' })
        .expect(404)
    })
  })

  describe('DELETE /api/groups/:id', () => {
    it('should delete a group', async () => {
      const grp = await createTestGroup({ name: 'Heroes' })

      await request(app)
        .delete(`/api/groups/${grp!.id}`)
        .expect(204)

      const found = await testDb.select().from(tables.group).where(eq(tables.group.id, grp!.id))
      expect(found).toHaveLength(0)
    })

    it('should return 404 for non-existent group', async () => {
      await request(app)
        .delete('/api/groups/9999')
        .expect(404)
    })
  })
})
