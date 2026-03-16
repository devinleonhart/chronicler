<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { PageLayout } from '@/components/layout'
import { calculateAge } from '@/lib/ageCalculator'
import { Users, Skull } from 'lucide-vue-next'

const settingsStore = useSettingsStore()
const charactersStore = useCharactersStore()

const { settings } = storeToRefs(settingsStore)
const { characters } = storeToRefs(charactersStore)

const groupBy = ref<'none' | 'group'>('none')

const referenceDate = computed(() => settings.value?.currentDay ?? '')

interface CharacterWithAge {
  id: number
  name: string
  birthDate: string
  deathDate: string | null
  groups: string[]
  age: number
  deceased: boolean
}

const charactersWithAges = computed<CharacterWithAge[]>(() => {
  if (!referenceDate.value) return []
  return characters.value.map(c => {
    const result = calculateAge(c.birthDate, referenceDate.value, c.deathDate)
    return {
      id: c.id,
      name: c.name,
      birthDate: c.birthDate,
      deathDate: c.deathDate,
      groups: c.characterGroups.map(cg => cg.group.name),
      age: result.years,
      deceased: result.deceased
    }
  }).sort((a, b) => {
    if (a.deceased !== b.deceased) return a.deceased ? 1 : -1
    return a.name.localeCompare(b.name)
  })
})

const living = computed(() => charactersWithAges.value.filter(c => !c.deceased))
const deceased = computed(() => charactersWithAges.value.filter(c => c.deceased))

// For group view: collect unique group names across all characters
const allGroups = computed(() => {
  const seen = new Set<string>()
  const groups: string[] = []
  for (const c of charactersWithAges.value) {
    for (const g of c.groups) {
      if (!seen.has(g)) { seen.add(g); groups.push(g) }
    }
  }
  groups.sort((a, b) => a.localeCompare(b))
  return groups
})

function charactersInGroup(groupName: string) {
  return charactersWithAges.value.filter(c => c.groups.includes(groupName))
}

const ungrouped = computed(() =>
  charactersWithAges.value.filter(c => c.groups.length === 0)
)
</script>

<template>
  <PageLayout>
    <template #header>
      <div class="page-header">
        <div class="header-left">
          <h1 class="page-title">Current Day</h1>
          <span v-if="referenceDate" class="date-badge">{{ referenceDate }}</span>
        </div>
        <div class="view-toggle">
          <button
            class="toggle-btn"
            :class="{ active: groupBy === 'none' }"
            @click="groupBy = 'none'"
          >
            <Users :size="14" /> All
          </button>
          <button
            class="toggle-btn"
            :class="{ active: groupBy === 'group' }"
            @click="groupBy = 'group'"
          >
            By Group
          </button>
        </div>
      </div>
    </template>

    <div v-if="!referenceDate" class="empty-state">
      No universe settings found. Configure a Current Day in Settings.
    </div>

    <!-- Flat view -->
    <template v-else-if="groupBy === 'none'">
      <section v-if="living.length > 0" class="section">
        <h2 class="section-title">Living ({{ living.length }})</h2>
        <div class="char-grid">
          <div v-for="c in living" :key="c.id" class="char-card">
            <span class="char-name">{{ c.name }}</span>
            <span class="char-age">{{ c.age }}</span>
          </div>
        </div>
      </section>

      <section v-if="deceased.length > 0" class="section">
        <h2 class="section-title deceased-title">
          <Skull :size="14" /> Deceased ({{ deceased.length }})
        </h2>
        <div class="char-grid">
          <div v-for="c in deceased" :key="c.id" class="char-card deceased">
            <span class="char-name">{{ c.name }}</span>
            <span class="char-age">{{ c.age }} at death</span>
          </div>
        </div>
      </section>
    </template>

    <!-- Group view -->
    <template v-else>
      <section v-for="groupName in allGroups" :key="groupName" class="section">
        <h2 class="section-title">{{ groupName }}</h2>
        <div class="char-grid">
          <div
            v-for="c in charactersInGroup(groupName)"
            :key="c.id"
            class="char-card"
            :class="{ deceased: c.deceased }"
          >
            <span class="char-name">{{ c.name }}</span>
            <span class="char-age">{{ c.deceased ? `${c.age} at death` : c.age }}</span>
          </div>
        </div>
      </section>

      <section v-if="ungrouped.length > 0" class="section">
        <h2 class="section-title muted">Ungrouped</h2>
        <div class="char-grid">
          <div
            v-for="c in ungrouped"
            :key="c.id"
            class="char-card"
            :class="{ deceased: c.deceased }"
          >
            <span class="char-name">{{ c.name }}</span>
            <span class="char-age">{{ c.deceased ? `${c.age} at death` : c.age }}</span>
          </div>
        </div>
      </section>
    </template>
  </PageLayout>
</template>

<style scoped>
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.page-title {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
}

.date-badge {
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
  background-color: var(--color-muted);
  padding: 0.2rem 0.6rem;
  border-radius: var(--radius-md);
  font-variant-numeric: tabular-nums;
}

.view-toggle {
  display: flex;
  gap: 0.25rem;
  background-color: var(--color-muted);
  padding: 0.25rem;
  border-radius: var(--radius-md);
}

.toggle-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.25rem 0.75rem;
  font-size: 0.8125rem;
  border: none;
  background: none;
  color: var(--color-muted-foreground);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: background-color 0.1s, color 0.1s;
}

.toggle-btn.active {
  background-color: var(--color-card);
  color: var(--color-foreground);
}

.section {
  margin-bottom: 2rem;
}

.section-title {
  font-size: 0.8125rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-muted-foreground);
  margin: 0 0 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.deceased-title {
  color: var(--color-muted-foreground);
}

.section-title.muted {
  opacity: 0.6;
}

.char-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr));
  gap: 0.5rem;
}

.char-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.5rem 0.75rem;
  background-color: var(--color-card);
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
}

.char-card.deceased {
  opacity: 0.5;
}

.char-name {
  font-size: 0.9375rem;
  font-weight: 500;
}

.char-card.deceased .char-name {
  text-decoration: line-through;
}

.char-age {
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
  font-variant-numeric: tabular-nums;
}

.empty-state {
  color: var(--color-muted-foreground);
  font-style: italic;
  padding: 2rem 0;
  text-align: center;
}
</style>
