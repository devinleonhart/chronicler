export interface UniverseSettings {
  id: number
  name: string
  startDate: string
  endDate: string
  currentDay: string
  createdAt: string
  updatedAt: string
}

export interface UpdateSettingsRequest {
  name?: string
  startDate?: string
  endDate?: string
  currentDay?: string
}
