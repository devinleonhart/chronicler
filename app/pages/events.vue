<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import type { ChronicleEvent, CreateEventRequest, UpdateEventRequest, BirthDeathRow, EventListRow } from '@/types/store/events'
import { PageLayout } from '@/components/layout'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { EventList, EventForm, EventTimelineView } from '@/components/features/events'
import { Search, Plus, List, BarChart2, Loader2 } from 'lucide-vue-next'

const eventsStore = useEventsStore()
const charactersStore = useCharactersStore()
const groupsStore = useGroupsStore()
const settingsStore = useSettingsStore()
const { events } = storeToRefs(eventsStore)
const { characters } = storeToRefs(charactersStore)
const { groups } = storeToRefs(groupsStore)
const { settings } = storeToRefs(settingsStore)
const toast = useToast()
const confirm = useConfirm()

const isLoading = ref(false)
const showForm = ref(false)
const selectedEvent = ref<ChronicleEvent | null>(null)
const viewMode = ref<'list' | 'timeline'>('list')

// Filter state
const searchQuery = ref('')
const selectedFilterGroups = ref<number[]>([])
const selectedFilterCharacters = ref<number[]>([])
const showBirthsDeaths = ref(false)

// Sort state
type SortKey = 'name' | 'startDate' | 'endDate'
type SortDir = 'asc' | 'desc'
const sortKey = ref<SortKey>('startDate')
const sortDir = ref<SortDir>('asc')

function toggleSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDir.value = 'asc'
  }
}

const filteredEvents = computed(() => {
  let result = events.value

  const q = searchQuery.value.toLowerCase().trim()
  if (q) {
    result = result.filter(e =>
      e.name.toLowerCase().includes(q) ||
      e.eventCharacters.some(ec => ec.character.name.toLowerCase().includes(q))
    )
  }

  const hasGroupFilter = selectedFilterGroups.value.length > 0
  const hasCharFilter = selectedFilterCharacters.value.length > 0

  if (hasGroupFilter || hasCharFilter) {
    result = result.filter(e => {
      if (e.isCurrentDay) return true

      const eventCharIds = new Set(e.eventCharacters.map(ec => ec.characterId))

      if (hasCharFilter && selectedFilterCharacters.value.some(id => eventCharIds.has(id))) {
        return true
      }

      if (hasGroupFilter) {
        const groupCharIds = new Set(
          groups.value
            .filter(g => selectedFilterGroups.value.includes(g.id))
            .flatMap(g => g.characterGroups.map(cg => cg.characterId))
        )
        if ([...eventCharIds].some(id => groupCharIds.has(id))) {
          return true
        }
      }

      return !hasGroupFilter && !hasCharFilter
    })
  }

  result = [...result].sort((a, b) => {
    const dir = sortDir.value === 'asc' ? 1 : -1
    const aVal = a[sortKey.value] ?? ''
    const bVal = b[sortKey.value] ?? ''
    return aVal < bVal ? -dir : aVal > bVal ? dir : 0
  })

  return result
})

const syntheticRows = computed<BirthDeathRow[]>(() => {
  if (!showBirthsDeaths.value) return []
  const rows: BirthDeathRow[] = []
  for (const char of characters.value) {
    rows.push({
      kind: 'birth',
      characterId: char.id,
      name: `${char.name} born`,
      startDate: char.birthDate,
      endDate: null,
      character: char
    })
    if (char.deathDate) {
      rows.push({
        kind: 'death',
        characterId: char.id,
        name: `${char.name} died`,
        startDate: char.deathDate,
        endDate: null,
        character: char
      })
    }
  }
  return rows
})

const filteredSyntheticRows = computed<BirthDeathRow[]>(() => {
  let result = syntheticRows.value

  const q = searchQuery.value.toLowerCase().trim()
  if (q) {
    result = result.filter(r => r.character.name.toLowerCase().includes(q))
  }

  const hasGroupFilter = selectedFilterGroups.value.length > 0
  const hasCharFilter = selectedFilterCharacters.value.length > 0

  if (hasGroupFilter || hasCharFilter) {
    result = result.filter(r => {
      if (hasCharFilter && selectedFilterCharacters.value.includes(r.characterId)) return true
      if (hasGroupFilter) {
        const groupCharIds = new Set(
          groups.value
            .filter(g => selectedFilterGroups.value.includes(g.id))
            .flatMap(g => g.characterGroups.map(cg => cg.characterId))
        )
        if (groupCharIds.has(r.characterId)) return true
      }
      return false
    })
  }

  return result
})

const displayedRows = computed<EventListRow[]>(() => {
  const merged: EventListRow[] = [...filteredEvents.value, ...filteredSyntheticRows.value]
  return merged.sort((a, b) => {
    const dir = sortDir.value === 'asc' ? 1 : -1
    const aVal = a[sortKey.value] ?? ''
    const bVal = b[sortKey.value] ?? ''
    return aVal < bVal ? -dir : aVal > bVal ? dir : 0
  })
})

onMounted(async () => {
  isLoading.value = true
  try {
    await Promise.all([
      eventsStore.getEvents(),
      charactersStore.getCharacters(),
      groupsStore.getGroups(),
      settingsStore.getSettings()
    ])
  } catch {
    toast.error('Failed to load data')
  } finally {
    isLoading.value = false
  }
})

function handleAddEvent() {
  selectedEvent.value = null
  showForm.value = true
}

function handleEditEvent(event: ChronicleEvent) {
  selectedEvent.value = event
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  selectedEvent.value = null
}

async function handleCreateEvent(data: CreateEventRequest) {
  try {
    await eventsStore.createEvent(data)
    toast.success('Event added successfully')
  } catch {
    toast.error('Failed to add event')
  }
}

async function handleUpdateEvent(id: number, data: UpdateEventRequest) {
  try {
    await eventsStore.updateEvent(id, data)
    toast.success('Event updated successfully')
  } catch {
    toast.error('Failed to update event')
  }
}

async function handleDeleteEvent(id: number) {
  const confirmed = await confirm.confirm({
    title: 'Delete Event',
    message: 'Are you sure you want to delete this event?',
    confirmText: 'Delete',
    variant: 'destructive'
  })
  if (!confirmed) return

  try {
    await eventsStore.deleteEvent(id)
    toast.success('Event deleted')
  } catch {
    toast.error('Failed to delete event')
  }
}

function toggleFilterGroup(groupId: number) {
  if (selectedFilterGroups.value.includes(groupId)) {
    selectedFilterGroups.value = selectedFilterGroups.value.filter(id => id !== groupId)
  } else {
    selectedFilterGroups.value = [...selectedFilterGroups.value, groupId]
  }
}

function toggleFilterCharacter(charId: number) {
  if (selectedFilterCharacters.value.includes(charId)) {
    selectedFilterCharacters.value = selectedFilterCharacters.value.filter(id => id !== charId)
  } else {
    selectedFilterCharacters.value = [...selectedFilterCharacters.value, charId]
  }
}

function clearFilters() {
  selectedFilterGroups.value = []
  selectedFilterCharacters.value = []
  searchQuery.value = ''
}

const hasActiveFilters = computed(() =>
  selectedFilterGroups.value.length > 0 ||
  selectedFilterCharacters.value.length > 0 ||
  searchQuery.value.trim() !== ''
)
</script>

<template>
  <PageLayout
    title="Events"
    :description="settings ? settings.name : 'Fictional Universe Event Tracker'"
  >
    <template #actions>
      <div class="action-bar">
        <div class="search-group">
          <Search />
          <Input v-model="searchQuery" placeholder="Search events..." />
        </div>
        <div class="view-toggle">
          <Button
            :variant="viewMode === 'list' ? 'default' : 'outline'"
            size="sm"
            @click="viewMode = 'list'"
          >
            <List />
          </Button>
          <Button
            :variant="viewMode === 'timeline' ? 'default' : 'outline'"
            size="sm"
            @click="viewMode = 'timeline'"
          >
            <BarChart2 />
          </Button>
        </div>
        <Button @click="handleAddEvent">
          <Plus />
          Add Event
        </Button>
      </div>
    </template>

    <!-- Filter bar -->
    <div v-if="groups.length > 0 || characters.length > 0" class="filter-bar">
      <span class="filter-label">Filter by:</span>

      <div class="filter-chips">
        <button
          v-for="group in groups"
          :key="`g-${group.id}`"
          class="filter-chip"
          :class="{ active: selectedFilterGroups.includes(group.id) }"
          @click="toggleFilterGroup(group.id)"
        >
          {{ group.name }}
        </button>
      </div>

      <div v-if="characters.length > 0" class="filter-divider" />

      <template v-if="characters.length > 0">
        <span class="filter-label">Show:</span>
        <div class="filter-chips">
          <button
            class="filter-chip"
            :class="{ active: showBirthsDeaths }"
            @click="showBirthsDeaths = !showBirthsDeaths"
          >
            Births &amp; Deaths
          </button>
        </div>
      </template>

      <button
        v-if="hasActiveFilters"
        class="clear-filters"
        @click="clearFilters"
      >
        Clear filters
      </button>
    </div>

    <!-- Active character filter badges -->
    <div v-if="selectedFilterCharacters.length > 0" class="badge-group" style="margin-bottom: 0.75rem;">
      <Badge
        v-for="id in selectedFilterCharacters"
        :key="id"
        variant="default"
        class="char-filter-badge"
        @click="toggleFilterCharacter(id)"
      >
        {{ characters.find(c => c.id === id)?.name }} ✕
      </Badge>
    </div>

    <div v-if="isLoading" class="loading-center">
      <Loader2 />
    </div>

    <div v-else-if="filteredEvents.length === 0" class="empty-state">
      {{ hasActiveFilters ? 'No events match the current filters.' : 'No events yet. Add your first event!' }}
    </div>

    <template v-else>
      <EventList
        v-if="viewMode === 'list'"
        :events="displayedRows"
        :sort-key="sortKey"
        :sort-dir="sortDir"
        @sort="toggleSort"
        @edit="handleEditEvent"
        @delete="handleDeleteEvent"
      />

      <EventTimelineView
        v-else
        :events="filteredEvents"
        :settings="settings"
        @edit="handleEditEvent"
      />
    </template>

    <EventForm
      :open="showForm"
      :event="selectedEvent"
      :characters="characters"
      @update:open="closeForm"
      @create="handleCreateEvent"
      @update="handleUpdateEvent"
    />
  </PageLayout>
</template>

<style scoped>
.view-toggle {
  display: flex;
  gap: 0.25rem;
}

.filter-bar {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
  padding: 0.625rem 0.875rem;
  background-color: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.filter-label {
  font-size: 0.8125rem;
  color: var(--color-muted-foreground);
  white-space: nowrap;
}

.filter-chips {
  display: flex;
  gap: 0.375rem;
  flex-wrap: wrap;
}

.filter-chip {
  padding: 0.25rem 0.625rem;
  border-radius: var(--radius-xl);
  font-size: 0.8125rem;
  border: 1px solid var(--color-border);
  background-color: transparent;
  color: var(--color-foreground);
  cursor: pointer;
  transition: background-color 0.15s, border-color 0.15s;
}

.filter-chip:hover {
  background-color: var(--color-accent);
}

.filter-chip.active {
  background-color: var(--color-primary);
  border-color: var(--color-primary);
  color: var(--color-primary-foreground);
}

.filter-divider {
  width: 1px;
  height: 1.25rem;
  background-color: var(--color-border);
  flex-shrink: 0;
}

.clear-filters {
  margin-left: auto;
  font-size: 0.8125rem;
  color: var(--color-muted-foreground);
  background: none;
  border: none;
  cursor: pointer;
  text-decoration: underline;
  padding: 0;
}

.clear-filters:hover {
  color: var(--color-foreground);
}

.char-filter-badge {
  cursor: pointer;
}
</style>
