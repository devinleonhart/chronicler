import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from 'axios'
import type { UniverseSettings, UpdateSettingsRequest } from '@/types/store/settings'

export const useSettingsStore = defineStore('settings', () => {
  const settings = ref<UniverseSettings | null>(null)

  const getSettings = async () => {
    try {
      const response = await axios.get('/api/settings')
      settings.value = response.data
    } catch (error) {
      console.error('Error fetching settings:', error)
    }
  }

  const updateSettings = async (updates: UpdateSettingsRequest) => {
    try {
      const response = await axios.put('/api/settings', updates)
      await getSettings()
      return response.data
    } catch (error) {
      console.error('Error updating settings:', error)
      throw error
    }
  }

  return {
    settings,
    getSettings,
    updateSettings
  }
})
