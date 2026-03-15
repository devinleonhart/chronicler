export interface GroupCharacter {
  characterId: number
  groupId: number
  character: {
    id: number
    name: string
    birthDate: string
    deathDate: string | null
    createdAt: string
    updatedAt: string
  }
}

export interface Group {
  id: number
  name: string
  description: string | null
  characterGroups: GroupCharacter[]
  createdAt: string
  updatedAt: string
}

export interface CreateGroupRequest {
  name: string
  description?: string | null
}

export interface UpdateGroupRequest {
  name?: string
  description?: string | null
}
