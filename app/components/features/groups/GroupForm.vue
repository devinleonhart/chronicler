<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import type { Group, CreateGroupRequest, UpdateGroupRequest } from '@/types/store/groups'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'

interface Props {
  open: boolean
  group?: Group | null
}

const props = withDefaults(defineProps<Props>(), {
  group: null
})

const emit = defineEmits<{
  'update:open': [value: boolean]
  create: [data: CreateGroupRequest]
  update: [id: number, data: UpdateGroupRequest]
}>()

const name = ref('')
const description = ref('')

const isEditing = computed(() => !!props.group)
const title = computed(() => isEditing.value ? 'Edit Group' : 'Add Group')

watch(() => props.open, (open) => {
  if (open && props.group) {
    name.value = props.group.name
    description.value = props.group.description || ''
  } else if (open) {
    name.value = ''
    description.value = ''
  }
})

function handleSubmit() {
  if (!name.value.trim()) return

  const data = {
    name: name.value.trim(),
    description: description.value.trim() || null
  }

  if (isEditing.value && props.group) {
    emit('update', props.group.id, data)
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
            <Label for="group-name">Name</Label>
            <Input
              id="group-name"
              v-model="name"
              placeholder="Group name"
            />
          </div>

          <div class="field">
            <Label for="group-desc">Description (optional)</Label>
            <Textarea
              id="group-desc"
              v-model="description"
              placeholder="Brief description..."
              :rows="2"
            />
          </div>

          <DialogFooter>
            <Button variant="outline" type="button" @click="emit('update:open', false)">
              Cancel
            </Button>
            <Button type="submit" :disabled="!name.trim()">
              {{ isEditing ? 'Save Changes' : 'Add Group' }}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </template>
  </Dialog>
</template>
