<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import type { Character, CreateCharacterRequest, UpdateCharacterRequest } from '@/types/store/characters'
import { PageLayout } from '@/components/layout'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { CharacterList, CharacterForm } from '@/components/features/characters'
import { Search, Loader2, Plus } from 'lucide-vue-next'

const charactersStore = useCharactersStore()
const groupsStore = useGroupsStore()
const { characters } = storeToRefs(charactersStore)
const { groups } = storeToRefs(groupsStore)
const toast = useToast()
const confirm = useConfirm()

const isLoading = ref(false)
const showForm = ref(false)
const selectedCharacter = ref<Character | null>(null)

const { searchQuery, filteredItems } = useSearch({
  items: characters,
  searchFields: ['name'],
  customFilter: (character, query) =>
    character.name.toLowerCase().includes(query) ||
    character.characterGroups.some(cg => cg.group.name.toLowerCase().includes(query))
})

onMounted(async () => {
  isLoading.value = true
  try {
    await Promise.all([
      charactersStore.getCharacters(),
      groupsStore.getGroups()
    ])
  } catch {
    toast.error('Failed to load characters')
  } finally {
    isLoading.value = false
  }
})

function handleAddCharacter() {
  selectedCharacter.value = null
  showForm.value = true
}

function handleEditCharacter(character: Character) {
  selectedCharacter.value = character
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  selectedCharacter.value = null
}

async function handleCreateCharacter(data: CreateCharacterRequest) {
  try {
    await charactersStore.createCharacter(data)
    toast.success('Character added successfully')
  } catch {
    toast.error('Failed to add character')
  }
}

async function handleUpdateCharacter(id: number, data: UpdateCharacterRequest) {
  try {
    await charactersStore.updateCharacter(id, data)
    toast.success('Character updated successfully')
  } catch {
    toast.error('Failed to update character')
  }
}

async function handleDeleteCharacter(id: number) {
  const confirmed = await confirm.confirm({
    title: 'Delete Character',
    message: 'Are you sure you want to delete this character? This will remove them from all events.',
    confirmText: 'Delete',
    variant: 'destructive'
  })
  if (!confirmed) return

  try {
    await charactersStore.deleteCharacter(id)
    toast.success('Character deleted')
  } catch {
    toast.error('Failed to delete character')
  }
}
</script>

<template>
  <PageLayout
    title="Characters"
    :description="`${characters.length} character${characters.length !== 1 ? 's' : ''}`"
  >
    <template #actions>
      <div class="action-bar">
        <div class="search-group">
          <Search />
          <Input v-model="searchQuery" placeholder="Search characters..." />
        </div>
        <Button @click="handleAddCharacter">
          <Plus />
          Add Character
        </Button>
      </div>
    </template>

    <div v-if="isLoading" class="loading-center">
      <Loader2 />
    </div>

    <div v-else-if="filteredItems.length === 0" class="empty-state">
      {{ searchQuery ? `No characters match "${searchQuery}"` : 'No characters yet. Add your first character!' }}
    </div>

    <CharacterList
      v-else
      :characters="filteredItems"
      @edit="handleEditCharacter"
      @delete="handleDeleteCharacter"
    />

    <CharacterForm
      :open="showForm"
      :character="selectedCharacter"
      :groups="groups"
      @update:open="closeForm"
      @create="handleCreateCharacter"
      @update="handleUpdateCharacter"
    />
  </PageLayout>
</template>
