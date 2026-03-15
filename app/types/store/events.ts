export interface EventCharacter {
  eventId: number
  characterId: number
  character: {
    id: number
    name: string
    birthDate: string
    deathDate: string | null
    createdAt: string
    updatedAt: string
  }
}

export interface ChronicleEvent {
  id: number
  name: string
  startDate: string
  endDate: string | null
  isCurrentDay: boolean
  eventCharacters: EventCharacter[]
  createdAt: string
  updatedAt: string
}

export interface CreateEventRequest {
  name: string
  startDate: string
  endDate?: string | null
  characterIds?: number[]
}

export interface UpdateEventRequest {
  name?: string
  startDate?: string
  endDate?: string | null
  characterIds?: number[]
}
