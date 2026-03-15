<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { PageLayout } from '@/components/layout'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Checkbox } from '@/components/ui/checkbox'
import axios from 'axios'
import { Search, Copy, Check, Loader2, FileText } from 'lucide-vue-next'

const charactersStore = useCharactersStore()
const groupsStore = useGroupsStore()
const { characters } = storeToRefs(charactersStore)
const { groups } = storeToRefs(groupsStore)

const isLoading = ref(false)
const isGenerating = ref(false)
const isCopied = ref(false)
const characterSearch = ref('')
const selectedIds = ref(new Set<number>())
const summaryText = ref('')
const summaryError = ref('')

const filteredCharacters = computed(() => {
  const q = characterSearch.value.toLowerCase().trim()
  if (!q) return characters.value
  return characters.value.filter(c => c.name.toLowerCase().includes(q))
})

const selectedCount = computed(() => selectedIds.value.size)

onMounted(async () => {
  isLoading.value = true
  try {
    await Promise.all([charactersStore.getCharacters(), groupsStore.getGroups()])
  } finally {
    isLoading.value = false
  }
})

function toggleCharacter(id: number) {
  const next = new Set(selectedIds.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  selectedIds.value = next
}

function groupToggleState(groupId: number): 'all' | 'some' | 'none' {
  const ids = characters.value
    .filter(c => c.characterGroups.some(cg => cg.groupId === groupId))
    .map(c => c.id)
  if (ids.length === 0) return 'none'
  const count = ids.filter(id => selectedIds.value.has(id)).length
  if (count === ids.length) return 'all'
  if (count > 0) return 'some'
  return 'none'
}

function selectGroup(groupId: number) {
  const ids = characters.value
    .filter(c => c.characterGroups.some(cg => cg.groupId === groupId))
    .map(c => c.id)
  const next = new Set(selectedIds.value)
  const allSelected = ids.every(id => next.has(id))
  if (allSelected) ids.forEach(id => next.delete(id))
  else ids.forEach(id => next.add(id))
  selectedIds.value = next
}

function clearSelection() {
  selectedIds.value = new Set()
  summaryText.value = ''
  summaryError.value = ''
}

async function generate() {
  if (selectedIds.value.size === 0) return
  isGenerating.value = true
  summaryError.value = ''
  summaryText.value = ''
  try {
    const ids = Array.from(selectedIds.value).join(',')
    const response = await axios.get(`/api/summary?characterIds=${ids}`, { responseType: 'text' })
    summaryText.value = response.data
  } catch (err: unknown) {
    try {
      const data = JSON.parse((err as { response?: { data?: string } })?.response?.data ?? '{}')
      summaryError.value = data.error ?? 'Failed to generate summary'
    } catch {
      summaryError.value = 'Failed to generate summary'
    }
  } finally {
    isGenerating.value = false
  }
}

async function copyText() {
  if (!summaryText.value) return
  await navigator.clipboard.writeText(summaryText.value)
  isCopied.value = true
  setTimeout(() => { isCopied.value = false }, 2000)
}
</script>

<template>
  <PageLayout
    title="Summary Generator"
    description="Select characters to generate a chronological event summary"
  >
    <div class="summary-layout">
      <!-- Left: character picker -->
      <div class="picker-panel">
        <div class="picker-header">
          <div class="search-group" style="flex: 1;">
            <Search />
            <Input v-model="characterSearch" placeholder="Search characters..." />
          </div>
          <Button
            v-if="selectedCount > 0"
            variant="ghost"
            size="sm"
            @click="clearSelection"
          >
            Clear ({{ selectedCount }})
          </Button>
        </div>

        <div v-if="isLoading" class="loading-center">
          <Loader2 />
        </div>

        <div v-else class="picker-body">
          <div v-if="groups.length > 0 && !characterSearch" class="group-section">
            <p class="section-label">Groups</p>
            <div class="group-chips">
              <button
                v-for="group in groups"
                :key="group.id"
                class="group-chip"
                :class="{
                  active: groupToggleState(group.id) === 'all',
                  partial: groupToggleState(group.id) === 'some'
                }"
                @click="selectGroup(group.id)"
              >
                {{ group.name }}
              </button>
            </div>
          </div>

          <div class="char-section">
            <p class="section-label">Characters</p>
            <div class="char-list">
              <label
                v-for="char in filteredCharacters"
                :key="char.id"
                class="char-item"
              >
                <Checkbox
                  :checked="selectedIds.has(char.id)"
                  @update:checked="toggleCharacter(char.id)"
                />
                <span class="char-name">{{ char.name }}</span>
              </label>
              <span v-if="filteredCharacters.length === 0" class="empty-state">
                No characters match.
              </span>
            </div>
          </div>
        </div>

        <div class="picker-footer">
          <Button
            :disabled="selectedCount === 0 || isGenerating"
            class="generate-btn"
            @click="generate"
          >
            <Loader2 v-if="isGenerating" class="spin" />
            <FileText v-else />
            Generate Summary
          </Button>
        </div>
      </div>

      <!-- Right: output -->
      <div class="output-panel">
        <div v-if="summaryError" class="output-placeholder output-error">
          {{ summaryError }}
        </div>
        <div v-else-if="!summaryText" class="output-placeholder">
          Select characters on the left and click Generate Summary.
        </div>
        <template v-else>
          <div class="output-toolbar">
            <Button variant="outline" size="sm" @click="copyText">
              <Check v-if="isCopied" />
              <Copy v-else />
              {{ isCopied ? 'Copied!' : 'Copy' }}
            </Button>
          </div>
          <textarea class="output-text" readonly :value="summaryText" />
        </template>
      </div>
    </div>
  </PageLayout>
</template>

<style scoped>
.summary-layout {
  display: grid;
  grid-template-columns: 22rem 1fr;
  gap: 1.25rem;
  align-items: start;
}

.picker-panel {
  display: flex;
  flex-direction: column;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background-color: var(--color-card);
  overflow: hidden;
}

.picker-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  border-bottom: 1px solid var(--color-border);
}

.picker-body {
  padding: 0.75rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-height: calc(100vh - 18rem);
  overflow-y: auto;
}

.picker-footer {
  padding: 0.75rem;
  border-top: 1px solid var(--color-border);
}

.generate-btn {
  width: 100%;
}

.section-label {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-muted-foreground);
  margin: 0 0 0.5rem;
}

.group-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 0.375rem;
}

.group-chip {
  padding: 0.25rem 0.625rem;
  font-size: 0.8125rem;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-foreground);
  cursor: pointer;
  transition: background-color 0.15s, border-color 0.15s, color 0.15s;
}

.group-chip:hover {
  background-color: var(--color-accent);
}

.group-chip.partial {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.group-chip.active {
  background-color: var(--color-primary);
  border-color: var(--color-primary);
  color: var(--color-primary-foreground);
}

.char-list {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.char-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.3rem 0.375rem;
  cursor: pointer;
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  transition: background-color 0.1s;
}

.char-item:hover {
  background-color: var(--color-accent);
}

.char-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}


.output-panel {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.output-toolbar {
  display: flex;
  justify-content: flex-end;
}

.output-text {
  width: 100%;
  min-height: 28rem;
  font-family: 'Menlo', 'Monaco', 'Consolas', monospace;
  font-size: 0.8125rem;
  line-height: 1.65;
  background-color: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  color: var(--color-foreground);
  padding: 1rem;
  resize: vertical;
  box-sizing: border-box;
}

.output-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 28rem;
  border: 1px dashed var(--color-border);
  border-radius: var(--radius-md);
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
  text-align: center;
  padding: 2rem;
}

.output-error {
  color: var(--color-destructive);
  border-color: var(--color-destructive);
}

.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}
</style>
