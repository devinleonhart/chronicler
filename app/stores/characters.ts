import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from 'axios'
import type { Character, CreateCharacterRequest, UpdateCharacterRequest } from '@/types/store/characters'

export const useCharactersStore = defineStore('characters', () => {
  const characters = ref<Character[]>([])

  const getCharacters = async () => {
    try {
      const response = await axios.get('/api/characters')
      characters.value = Array.isArray(response.data) ? response.data : []
    } catch (error) {
      console.error('Error fetching characters:', error)
    }
  }

  const createCharacter = async (request: CreateCharacterRequest) => {
    try {
      const response = await axios.post('/api/characters', request)
      await getCharacters()
      return response.data
    } catch (error) {
      console.error('Error creating character:', error)
      throw error
    }
  }

  const updateCharacter = async (id: number, updates: UpdateCharacterRequest) => {
    try {
      const response = await axios.put(`/api/characters/${id}`, updates)
      await getCharacters()
      return response.data
    } catch (error) {
      console.error('Error updating character:', error)
      throw error
    }
  }

  const deleteCharacter = async (id: number) => {
    try {
      await axios.delete(`/api/characters/${id}`)
      await getCharacters()
    } catch (error) {
      console.error('Error deleting character:', error)
      throw error
    }
  }

  return {
    characters,
    getCharacters,
    createCharacter,
    updateCharacter,
    deleteCharacter
  }
})
