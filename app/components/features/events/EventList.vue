<script setup lang="ts">
import type { ChronicleEvent } from '@/types/store/events'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell
} from '@/components/ui/table'
import { Pencil, Trash2, Star, ExternalLink, ChevronUp, ChevronDown, ChevronsUpDown } from 'lucide-vue-next'
import { calculateAge, formatAge } from '@/lib/ageCalculator'
import { useRouter } from 'vue-router'

const router = useRouter()

type SortKey = 'name' | 'startDate' | 'endDate'
type SortDir = 'asc' | 'desc'

interface Props {
  events: ChronicleEvent[]
  sortKey?: SortKey
  sortDir?: SortDir
}

defineProps<Props>()

const emit = defineEmits<{
  edit: [event: ChronicleEvent]
  delete: [id: number]
  sort: [key: SortKey]
}>()

function getCharacterAge(birthDate: string, startDate: string, deathDate: string | null | undefined): string {
  const age = calculateAge(birthDate, startDate, deathDate ?? null)
  return formatAge(age)
}
</script>

<template>
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead class="sortable" @click="emit('sort', 'name')">
          <span class="sort-header">
            Event
            <ChevronUp v-if="sortKey === 'name' && sortDir === 'asc'" :size="13" />
            <ChevronDown v-else-if="sortKey === 'name' && sortDir === 'desc'" :size="13" />
            <ChevronsUpDown v-else :size="13" class="sort-idle" />
          </span>
        </TableHead>
        <TableHead class="sortable" @click="emit('sort', 'startDate')">
          <span class="sort-header">
            Start Date
            <ChevronUp v-if="sortKey === 'startDate' && sortDir === 'asc'" :size="13" />
            <ChevronDown v-else-if="sortKey === 'startDate' && sortDir === 'desc'" :size="13" />
            <ChevronsUpDown v-else :size="13" class="sort-idle" />
          </span>
        </TableHead>
        <TableHead class="sortable" @click="emit('sort', 'endDate')">
          <span class="sort-header">
            End Date
            <ChevronUp v-if="sortKey === 'endDate' && sortDir === 'asc'" :size="13" />
            <ChevronDown v-else-if="sortKey === 'endDate' && sortDir === 'desc'" :size="13" />
            <ChevronsUpDown v-else :size="13" class="sort-idle" />
          </span>
        </TableHead>
        <TableHead>Characters &amp; Ages</TableHead>
        <TableHead></TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      <TableRow
        v-for="event in events"
        :key="event.id"
        :class="event.isCurrentDay ? 'current-day-row' : ''"
      >
        <TableCell>
          <div class="info-cell">
            <span class="name">
              <Star v-if="event.isCurrentDay" class="current-day-icon" />
              {{ event.name }}
            </span>
          </div>
        </TableCell>
        <TableCell>
          <span class="sub">{{ event.startDate }}</span>
        </TableCell>
        <TableCell>
          <span v-if="event.endDate" class="sub">{{ event.endDate }}</span>
          <span v-else class="sub muted">—</span>
        </TableCell>
        <TableCell>
          <div v-if="event.isCurrentDay" class="char-list">
            <button class="view-ages-btn" @click="router.push('/current-day')">
              <ExternalLink :size="12" /> View all ages
            </button>
          </div>
          <div v-else-if="event.eventCharacters.length > 0" class="char-list">
            <div
              v-for="ec in event.eventCharacters"
              :key="ec.characterId"
              class="char-age-row"
            >
              <span class="char-name" :class="{ deceased: !!ec.character.deathDate && ec.character.deathDate <= event.startDate }">
                {{ ec.character.name }}
              </span>
              <span class="age-tag">
                age {{ getCharacterAge(ec.character.birthDate, event.startDate, ec.character.deathDate) }}
                <template v-if="event.endDate && event.endDate !== event.startDate">
                  → {{ getCharacterAge(ec.character.birthDate, event.endDate, ec.character.deathDate) }}
                </template>
              </span>
            </div>
          </div>
          <span v-else class="sub muted">—</span>
        </TableCell>
        <TableCell>
          <div class="actions">
            <Button variant="ghost" size="icon" @click="emit('edit', event)">
              <Pencil />
            </Button>
            <Button
              v-if="!event.isCurrentDay"
              variant="ghost"
              size="icon"
              @click="emit('delete', event.id)"
            >
              <Trash2 />
            </Button>
          </div>
        </TableCell>
      </TableRow>
    </TableBody>
  </Table>
</template>

<style scoped>
.sortable {
  cursor: pointer;
  user-select: none;
  white-space: nowrap;
}

.sort-header {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.sortable:hover {
  color: var(--color-foreground);
}

.sort-idle {
  opacity: 0.35;
}

.current-day-row {
  background-color: color-mix(in srgb, var(--color-primary) 8%, transparent);
}

.name {
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.current-day-icon {
  color: var(--color-primary);
  font-size: 0.875em;
}

.sub {
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
}

.muted {
  color: var(--color-border);
}

.view-ages-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.8125rem;
  color: var(--color-primary);
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
}

.view-ages-btn:hover {
  text-decoration: underline;
}

.char-list {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.char-age-row {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.char-name {
  font-weight: 500;
  color: var(--color-foreground);
}

.char-name.deceased {
  color: var(--color-muted-foreground);
  text-decoration: line-through;
}

.age-tag {
  color: var(--color-muted-foreground);
  font-size: 0.8125rem;
}
</style>
