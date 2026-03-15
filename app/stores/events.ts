import { defineStore } from 'pinia'
import { ref } from 'vue'
import axios from 'axios'
import type { ChronicleEvent, CreateEventRequest, UpdateEventRequest } from '@/types/store/events'

export const useEventsStore = defineStore('events', () => {
  const events = ref<ChronicleEvent[]>([])

  const getEvents = async () => {
    try {
      const response = await axios.get('/api/events')
      events.value = Array.isArray(response.data) ? response.data : []
    } catch (error) {
      console.error('Error fetching events:', error)
    }
  }

  const createEvent = async (request: CreateEventRequest) => {
    try {
      const response = await axios.post('/api/events', request)
      await getEvents()
      return response.data
    } catch (error) {
      console.error('Error creating event:', error)
      throw error
    }
  }

  const updateEvent = async (id: number, updates: UpdateEventRequest) => {
    try {
      const response = await axios.put(`/api/events/${id}`, updates)
      await getEvents()
      return response.data
    } catch (error) {
      console.error('Error updating event:', error)
      throw error
    }
  }

  const deleteEvent = async (id: number) => {
    try {
      await axios.delete(`/api/events/${id}`)
      await getEvents()
    } catch (error) {
      console.error('Error deleting event:', error)
      throw error
    }
  }

  return {
    events,
    getEvents,
    createEvent,
    updateEvent,
    deleteEvent
  }
})
