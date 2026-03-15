<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import type { ChronicleEvent, CreateEventRequest, UpdateEventRequest } from '@/types/store/events'
import type { Character } from '@/types/store/characters'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Checkbox } from '@/components/ui/checkbox'
import { Search } from 'lucide-vue-next'

interface Props {
  open: boolean
  event?: ChronicleEvent | null
  characters: Character[]
}

const props = withDefaults(defineProps<Props>(), {
  event: null
})

const emit = defineEmits<{
  'update:open': [value: boolean]
  create: [data: CreateEventRequest]
  update: [id: number, data: UpdateEventRequest]
}>()

const name = ref('')
const startDate = ref('')
const endDate = ref('')
const selectedCharacterIds = ref<number[]>([])
const characterSearch = ref('')

const isEditing = computed(() => !!props.event)
const title = computed(() => isEditing.value ? 'Edit Event' : 'Add Event')
const isCurrentDay = computed(() => props.event?.isCurrentDay ?? false)

const filteredCharacters = computed(() => {
  const q = characterSearch.value.toLowerCase().trim()
  if (!q) return props.characters
  return props.characters.filter(c => c.name.toLowerCase().includes(q))
})

watch(() => props.open, (open) => {
  if (open && props.event) {
    name.value = props.event.name
    startDate.value = props.event.startDate
    endDate.value = props.event.endDate || ''
    selectedCharacterIds.value = props.event.eventCharacters.map(ec => ec.characterId)
  } else if (open) {
    name.value = ''
    startDate.value = ''
    endDate.value = ''
    selectedCharacterIds.value = []
  }
  characterSearch.value = ''
})

function toggleCharacter(characterId: number) {
  if (selectedCharacterIds.value.includes(characterId)) {
    selectedCharacterIds.value = selectedCharacterIds.value.filter(id => id !== characterId)
  } else {
    selectedCharacterIds.value = [...selectedCharacterIds.value, characterId]
  }
}

function handleSubmit() {
  if (!name.value.trim() || !startDate.value) return

  const data = {
    name: name.value.trim(),
    startDate: startDate.value,
    endDate: endDate.value.trim() || null,
    characterIds: isCurrentDay.value ? undefined : selectedCharacterIds.value
  }

  if (isEditing.value && props.event) {
    emit('update', props.event.id, data)
  } else {
    emit('create', data)
  }

  emit('update:open', false)
}
</script>

<template>
  <Dialog :open="open" @update:open="emit('update:open', $event)">
    <template #content>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{{ title }}</DialogTitle>
        </DialogHeader>

        <form class="form" @submit.prevent="handleSubmit">
          <div class="field">
            <Label for="event-name">Name</Label>
            <Input
              id="event-name"
              v-model="name"
              placeholder="Event name"
            />
          </div>

          <div class="field-row">
            <div class="field">
              <Label for="event-start">Start Date</Label>
              <Input
                id="event-start"
                v-model="startDate"
                placeholder="YYYY-MM-DD"
              />
            </div>
            <div class="field">
              <Label for="event-end">End Date (optional)</Label>
              <Input
                id="event-end"
                v-model="endDate"
                placeholder="YYYY-MM-DD"
              />
            </div>
          </div>

          <div v-if="!isCurrentDay && characters.length > 0" class="field">
            <Label>Characters Present</Label>
            <div class="search-group char-search">
              <Search />
              <Input v-model="characterSearch" placeholder="Search characters..." />
            </div>
            <div class="char-list">
              <label
                v-for="character in filteredCharacters"
                :key="character.id"
                class="char-item"
              >
                <Checkbox
                  :checked="selectedCharacterIds.includes(character.id)"
                  @update:checked="toggleCharacter(character.id)"
                />
                <span>{{ character.name }}</span>
                <span class="char-birth">b. {{ character.birthDate }}</span>
              </label>
              <span v-if="filteredCharacters.length === 0" class="empty-state">No characters match.</span>
            </div>
          </div>

          <div v-if="isCurrentDay" class="current-day-note">
            The Current Day event automatically includes all characters.
          </div>

          <DialogFooter>
            <Button variant="outline" type="button" @click="emit('update:open', false)">
              Cancel
            </Button>
            <Button type="submit" :disabled="!name.trim() || !startDate">
              {{ isEditing ? 'Save Changes' : 'Add Event' }}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </template>
  </Dialog>
</template>

<style scoped>
.char-search {
  margin-bottom: 0.375rem;
}

.char-list {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  max-height: 14rem;
  overflow-y: auto;
  padding: 0.5rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.char-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-size: 0.875rem;
}

.char-birth {
  margin-left: auto;
  font-size: 0.8125rem;
  color: var(--color-muted-foreground);
}

.current-day-note {
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
  font-style: italic;
  padding: 0.5rem 0;
}
</style>
