<script setup lang="ts">
import type { ChronicleEvent } from '@/types/store/events'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell
} from '@/components/ui/table'
import { Pencil, Trash2, Star } from 'lucide-vue-next'
import { calculateAge, formatAge } from '@/lib/ageCalculator'

interface Props {
  events: ChronicleEvent[]
}

defineProps<Props>()

const emit = defineEmits<{
  edit: [event: ChronicleEvent]
  delete: [id: number]
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
        <TableHead>Event</TableHead>
        <TableHead>Start Date</TableHead>
        <TableHead>End Date</TableHead>
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
            <Badge v-if="event.isCurrentDay" variant="default" class="cd-badge">Current Day</Badge>
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
            <span class="sub all-chars">All characters</span>
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

.cd-badge {
  font-size: 0.6875rem;
  margin-top: 0.25rem;
  display: inline-flex;
  width: fit-content;
}

.sub {
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
}

.muted {
  color: var(--color-border);
}

.all-chars {
  font-style: italic;
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
