import { createApp, createRouter, toNodeListener } from 'h3'

// ── Settings ──────────────────────────────────────────────────────────────────
import settingsGet from '../api/settings/index.get.js'
import settingsPut from '../api/settings/index.put.js'

// ── Characters ────────────────────────────────────────────────────────────────
import charactersGetAll from '../api/characters/index.get.js'
import charactersPost from '../api/characters/index.post.js'
import charactersGetById from '../api/characters/[id].get.js'
import charactersPutById from '../api/characters/[id].put.js'
import charactersDeleteById from '../api/characters/[id].delete.js'

// ── Groups ────────────────────────────────────────────────────────────────────
import groupsGetAll from '../api/groups/index.get.js'
import groupsPost from '../api/groups/index.post.js'
import groupsGetById from '../api/groups/[id].get.js'
import groupsPutById from '../api/groups/[id].put.js'
import groupsDeleteById from '../api/groups/[id].delete.js'

// ── Events ────────────────────────────────────────────────────────────────────
import eventsGetAll from '../api/events/index.get.js'
import eventsPost from '../api/events/index.post.js'
import eventsGetById from '../api/events/[id].get.js'
import eventsPutById from '../api/events/[id].put.js'
import eventsDeleteById from '../api/events/[id].delete.js'

export function createTestApp() {
  const app = createApp()
  const router = createRouter()

  // Settings
  router.get('/api/settings', settingsGet)
  router.put('/api/settings', settingsPut)

  // Characters
  router.get('/api/characters', charactersGetAll)
  router.post('/api/characters', charactersPost)
  router.get('/api/characters/:id', charactersGetById)
  router.put('/api/characters/:id', charactersPutById)
  router.delete('/api/characters/:id', charactersDeleteById)

  // Groups
  router.get('/api/groups', groupsGetAll)
  router.post('/api/groups', groupsPost)
  router.get('/api/groups/:id', groupsGetById)
  router.put('/api/groups/:id', groupsPutById)
  router.delete('/api/groups/:id', groupsDeleteById)

  // Events
  router.get('/api/events', eventsGetAll)
  router.post('/api/events', eventsPost)
  router.get('/api/events/:id', eventsGetById)
  router.put('/api/events/:id', eventsPutById)
  router.delete('/api/events/:id', eventsDeleteById)

  app.use(router)
  return toNodeListener(app)
}
