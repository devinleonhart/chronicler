import axios from 'axios'

export default defineNuxtPlugin(() => {
  const { apiKey } = useRuntimeConfig().public
  if (apiKey) {
    axios.defaults.headers.common['Authorization'] = `Bearer ${apiKey}`
  }
})
