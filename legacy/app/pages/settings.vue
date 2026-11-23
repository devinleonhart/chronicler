<script setup lang="ts">
import { onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import type { UpdateSettingsRequest } from '@/types/store/settings'
import { PageLayout } from '@/components/layout'
import { SettingsForm } from '@/components/features/settings'

const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)
const toast = useToast()

onMounted(async () => {
  try {
    await settingsStore.getSettings()
  } catch {
    toast.error('Failed to load settings')
  }
})

async function handleUpdateSettings(data: UpdateSettingsRequest) {
  try {
    await settingsStore.updateSettings(data)
    toast.success('Settings saved')
  } catch {
    toast.error('Failed to save settings')
  }
}
</script>

<template>
  <PageLayout title="Settings" description="Configure your fictional universe">
    <SettingsForm :settings="settings" @update="handleUpdateSettings" />
  </PageLayout>
</template>
