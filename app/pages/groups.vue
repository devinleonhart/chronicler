<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import type { Group, CreateGroupRequest, UpdateGroupRequest } from '@/types/store/groups'
import { PageLayout } from '@/components/layout'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { GroupList, GroupForm } from '@/components/features/groups'
import { Search, Loader2, Plus } from 'lucide-vue-next'

const groupsStore = useGroupsStore()
const { groups } = storeToRefs(groupsStore)
const toast = useToast()
const confirm = useConfirm()

const isLoading = ref(false)
const showForm = ref(false)
const selectedGroup = ref<Group | null>(null)

const { searchQuery, filteredItems } = useSearch({
  items: groups,
  searchFields: ['name', 'description']
})

onMounted(async () => {
  isLoading.value = true
  try {
    await groupsStore.getGroups()
  } catch {
    toast.error('Failed to load groups')
  } finally {
    isLoading.value = false
  }
})

function handleAddGroup() {
  selectedGroup.value = null
  showForm.value = true
}

function handleEditGroup(group: Group) {
  selectedGroup.value = group
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  selectedGroup.value = null
}

async function handleCreateGroup(data: CreateGroupRequest) {
  try {
    await groupsStore.createGroup(data)
    toast.success('Group added successfully')
  } catch {
    toast.error('Failed to add group')
  }
}

async function handleUpdateGroup(id: number, data: UpdateGroupRequest) {
  try {
    await groupsStore.updateGroup(id, data)
    toast.success('Group updated successfully')
  } catch {
    toast.error('Failed to update group')
  }
}

async function handleDeleteGroup(id: number) {
  const confirmed = await confirm.confirm({
    title: 'Delete Group',
    message: 'Are you sure you want to delete this group? Characters will remain but lose this group assignment.',
    confirmText: 'Delete',
    variant: 'destructive'
  })
  if (!confirmed) return

  try {
    await groupsStore.deleteGroup(id)
    toast.success('Group deleted')
  } catch {
    toast.error('Failed to delete group')
  }
}
</script>

<template>
  <PageLayout
    title="Groups"
    :description="`${groups.length} group${groups.length !== 1 ? 's' : ''}`"
  >
    <template #actions>
      <div class="action-bar">
        <div class="search-group">
          <Search />
          <Input v-model="searchQuery" placeholder="Search groups..." />
        </div>
        <Button @click="handleAddGroup">
          <Plus />
          Add Group
        </Button>
      </div>
    </template>

    <div v-if="isLoading" class="loading-center">
      <Loader2 />
    </div>

    <div v-else-if="filteredItems.length === 0" class="empty-state">
      {{ searchQuery ? `No groups match "${searchQuery}"` : 'No groups yet. Add your first group!' }}
    </div>

    <GroupList
      v-else
      :groups="filteredItems"
      @edit="handleEditGroup"
      @delete="handleDeleteGroup"
    />

    <GroupForm
      :open="showForm"
      :group="selectedGroup"
      @update:open="closeForm"
      @create="handleCreateGroup"
      @update="handleUpdateGroup"
    />
  </PageLayout>
</template>
