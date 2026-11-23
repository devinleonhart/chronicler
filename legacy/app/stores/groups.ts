import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from 'axios'
import type { Group, CreateGroupRequest, UpdateGroupRequest } from '@/types/store/groups'

export const useGroupsStore = defineStore('groups', () => {
  const groups = ref<Group[]>([])

  const getGroups = async () => {
    try {
      const response = await axios.get('/api/groups')
      groups.value = Array.isArray(response.data) ? response.data : []
    } catch (error) {
      console.error('Error fetching groups:', error)
    }
  }

  const createGroup = async (request: CreateGroupRequest) => {
    try {
      const response = await axios.post('/api/groups', request)
      await getGroups()
      return response.data
    } catch (error) {
      console.error('Error creating group:', error)
      throw error
    }
  }

  const updateGroup = async (id: number, updates: UpdateGroupRequest) => {
    try {
      const response = await axios.put(`/api/groups/${id}`, updates)
      await getGroups()
      return response.data
    } catch (error) {
      console.error('Error updating group:', error)
      throw error
    }
  }

  const deleteGroup = async (id: number) => {
    try {
      await axios.delete(`/api/groups/${id}`)
      await getGroups()
    } catch (error) {
      console.error('Error deleting group:', error)
      throw error
    }
  }

  return {
    groups,
    getGroups,
    createGroup,
    updateGroup,
    deleteGroup
  }
})
