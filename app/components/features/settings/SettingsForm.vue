<script setup lang="ts">
import { ref, watch } from 'vue'
import type { UniverseSettings, UpdateSettingsRequest } from '@/types/store/settings'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'

interface Props {
  settings: UniverseSettings | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  update: [data: UpdateSettingsRequest]
}>()

const name = ref('')
const startDate = ref('')
const endDate = ref('')
const currentDay = ref('')

watch(() => props.settings, (s) => {
  if (s) {
    name.value = s.name
    startDate.value = s.startDate
    endDate.value = s.endDate
    currentDay.value = s.currentDay
  }
}, { immediate: true })

function handleSubmit() {
  emit('update', {
    name: name.value.trim() || undefined,
    startDate: startDate.value || undefined,
    endDate: endDate.value || undefined,
    currentDay: currentDay.value || undefined
  })
}
</script>

<template>
  <Card>
    <CardHeader>
      <CardTitle>Universe Settings</CardTitle>
    </CardHeader>
    <CardContent>
      <form class="form" style="padding: 0;" @submit.prevent="handleSubmit">
        <div class="field">
          <Label for="universe-name">Universe Name</Label>
          <Input
            id="universe-name"
            v-model="name"
            placeholder="My Universe"
          />
        </div>

        <div class="field-row">
          <div class="field">
            <Label for="start-date">Universe Start Date</Label>
            <Input
              id="start-date"
              v-model="startDate"
              placeholder="YYYY-MM-DD"
            />
          </div>
          <div class="field">
            <Label for="end-date">Universe End Date</Label>
            <Input
              id="end-date"
              v-model="endDate"
              placeholder="YYYY-MM-DD"
            />
          </div>
        </div>

        <div class="field">
          <Label for="current-day">Current Day</Label>
          <Input
            id="current-day"
            v-model="currentDay"
            placeholder="YYYY-MM-DD"
          />
          <span class="hint">This date drives the "Current Day" event and shows current character ages.</span>
        </div>

        <div class="form-footer">
          <Button type="submit">
            Save Settings
          </Button>
        </div>
      </form>
    </CardContent>
  </Card>
</template>

<style scoped>
.hint {
  font-size: 0.8125rem;
  color: var(--color-muted-foreground);
}

.form-footer {
  display: flex;
  justify-content: flex-end;
  padding-top: 0.5rem;
}
</style>
