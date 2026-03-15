<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { storeToRefs } from 'pinia'
import type { Character, CreateCharacterRequest, UpdateCharacterRequest } from '@/types/store/characters'
import type { Group } from '@/types/store/groups'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Checkbox } from '@/components/ui/checkbox'
import { DateField } from '@/components/ui/date-field'

const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)

interface Props {
  open: boolean
  character?: Character | null
  groups: Group[]
}

const props = withDefaults(defineProps<Props>(), {
  character: null
})

const emit = defineEmits<{
  'update:open': [value: boolean]
  create: [data: CreateCharacterRequest]
  update: [id: number, data: UpdateCharacterRequest]
}>()

const name = ref('')
const birthDate = ref('')
const deathDate = ref('')
const selectedGroupIds = ref<number[]>([])

const isEditing = computed(() => !!props.character)
const title = computed(() => isEditing.value ? 'Edit Character' : 'Add Character')

watch(() => props.open, (open) => {
  if (open && props.character) {
    name.value = props.character.name
    birthDate.value = props.character.birthDate
    deathDate.value = props.character.deathDate || ''
    selectedGroupIds.value = props.character.characterGroups.map(cg => cg.groupId)
  } else if (open) {
    name.value = ''
    birthDate.value = ''
    deathDate.value = ''
    selectedGroupIds.value = []
  }
})

function toggleGroup(groupId: number) {
  if (selectedGroupIds.value.includes(groupId)) {
    selectedGroupIds.value = selectedGroupIds.value.filter(id => id !== groupId)
  } else {
    selectedGroupIds.value = [...selectedGroupIds.value, groupId]
  }
}

function handleSubmit() {
  if (!name.value.trim() || !birthDate.value) return

  const data = {
    name: name.value.trim(),
    birthDate: birthDate.value,
    deathDate: deathDate.value.trim() || null,
    groupIds: selectedGroupIds.value
  }

  if (isEditing.value && props.character) {
    emit('update', props.character.id, data)
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
            <Label for="char-name">Name</Label>
            <Input
              id="char-name"
              v-model="name"
              placeholder="Character name"
            />
          </div>

          <div class="field-row">
            <div class="field">
              <Label>Birth Date</Label>
              <DateField
                v-model="birthDate"
                :min-value="settings?.startDate"
                :max-value="settings?.endDate"
              />
            </div>
            <div class="field">
              <Label>Death Date (optional)</Label>
              <DateField
                v-model="deathDate"
                :min-value="settings?.startDate"
                :max-value="settings?.endDate"
              />
            </div>
          </div>

          <div v-if="groups.length > 0" class="field">
            <Label>Groups</Label>
            <div class="group-list">
              <label
                v-for="group in groups"
                :key="group.id"
                class="group-item"
              >
                <Checkbox
                  :checked="selectedGroupIds.includes(group.id)"
                  @update:checked="toggleGroup(group.id)"
                />
                <span>{{ group.name }}</span>
              </label>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" type="button" @click="emit('update:open', false)">
              Cancel
            </Button>
            <Button type="submit" :disabled="!name.trim() || !birthDate">
              {{ isEditing ? 'Save Changes' : 'Add Character' }}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </template>
  </Dialog>
</template>

<style scoped>
.group-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 12rem;
  overflow-y: auto;
  padding: 0.5rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
}

.group-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-size: 0.875rem;
}
</style>
