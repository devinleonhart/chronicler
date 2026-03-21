import { createApp, createRouter, toNodeListener } from 'h3'

// ── Settings ──────────────────────────────────────────────────────────────────
import settingsGet from '../api/settings/index.get.js'
import settingsPut from '../api/settings/index.put.js'

// ── Characters ────────────────────────────────────────────────────────────────
import charactersGetAll from '../api/characters/index.get.js'
import charactersPost from '../api/characters/index.post.js'
import charactersBulkPut from '../api/characters/bulk.put.js'
import charactersPlaceholders from '../api/characters/placeholders.get.js'
import charactersGetById from '../api/characters/[id].get.js'
import charactersPutById from '../api/characters/[id].put.js'
import charactersDeleteById from '../api/characters/[id].delete.js'
import characterGroupsPost from '../api/characters/[id]/groups/index.post.js'
import characterGroupsDelete from '../api/characters/[id]/groups/[groupId].delete.js'
import characterEventsGet from '../api/characters/[id]/events/index.get.js'

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
import eventCharactersPost from '../api/events/[id]/characters/index.post.js'
import eventCharactersDelete from '../api/events/[id]/characters/[characterId].delete.js'

export function createTestApp() {
  const app = createApp()
  const router = createRouter()

  // Settings
  router.get('/api/settings', settingsGet)
  router.put('/api/settings', settingsPut)

  // Characters — static routes before dynamic
  router.get('/api/characters', charactersGetAll)
  router.post('/api/characters', charactersPost)
  router.put('/api/characters/bulk', charactersBulkPut)
  router.get('/api/characters/placeholders', charactersPlaceholders)
  router.get('/api/characters/:id', charactersGetById)
  router.put('/api/characters/:id', charactersPutById)
  router.delete('/api/characters/:id', charactersDeleteById)
  router.post('/api/characters/:id/groups', characterGroupsPost)
  router.delete('/api/characters/:id/groups/:groupId', characterGroupsDelete)
  router.get('/api/characters/:id/events', characterEventsGet)

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
  router.post('/api/events/:id/characters', eventCharactersPost)
  router.delete('/api/events/:id/characters/:characterId', eventCharactersDelete)

  app.use(router)
  return toNodeListener(app)
}
