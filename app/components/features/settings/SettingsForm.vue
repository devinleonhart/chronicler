<script setup lang="ts">
import { ref, watch } from 'vue'
import type { UniverseSettings, UpdateSettingsRequest } from '@/types/store/settings'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { DateField } from '@/components/ui/date-field'

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
            <Label>Universe Start Date</Label>
            <DateField v-model="startDate" />
          </div>
          <div class="field">
            <Label>Universe End Date</Label>
            <DateField v-model="endDate" />
          </div>
        </div>

        <div class="field">
          <Label>Current Day</Label>
          <DateField
            v-model="currentDay"
            :min-value="startDate"
            :max-value="endDate"
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
