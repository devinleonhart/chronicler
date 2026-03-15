export interface CharacterGroup {
  characterId: number
  groupId: number
  group: {
    id: number
    name: string
    description: string | null
    createdAt: string
    updatedAt: string
  }
}

export interface Character {
  id: number
  name: string
  birthDate: string
  deathDate: string | null
  characterGroups: CharacterGroup[]
  createdAt: string
  updatedAt: string
}

export interface CreateCharacterRequest {
  name: string
  birthDate: string
  deathDate?: string | null
  groupIds?: number[]
}

export interface UpdateCharacterRequest {
  name?: string
  birthDate?: string
  deathDate?: string | null
  groupIds?: number[]
}
