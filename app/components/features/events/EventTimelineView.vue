<script setup lang="ts">
import { computed } from 'vue'
import type { ChronicleEvent } from '@/types/store/events'
import type { UniverseSettings } from '@/types/store/settings'

interface Props {
  events: ChronicleEvent[]
  settings: UniverseSettings | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  edit: [event: ChronicleEvent]
}>()

const universeStartYear = computed(() => {
  if (!props.settings) return 1
  return parseInt(props.settings.startDate.split('-')[0]!)
})

const universeEndYear = computed(() => {
  if (!props.settings) return 1000
  return parseInt(props.settings.endDate.split('-')[0]!)
})

const currentDayYear = computed(() => {
  if (!props.settings) return null
  return parseInt(props.settings.currentDay.split('-')[0]!)
})

const totalYears = computed(() => universeEndYear.value - universeStartYear.value || 1)

function yearToPercent(year: number): number {
  return ((year - universeStartYear.value) / totalYears.value) * 100
}

function dateToYear(dateStr: string): number {
  return parseInt(dateStr.split('-')[0]!)
}

function eventLeft(event: ChronicleEvent): string {
  const year = dateToYear(event.startDate)
  return `${Math.max(0, Math.min(100, yearToPercent(year)))}%`
}

function eventWidth(event: ChronicleEvent): string {
  if (!event.endDate) return '0.5%'
  const startYear = dateToYear(event.startDate)
  const endYear = dateToYear(event.endDate)
  const width = yearToPercent(endYear) - yearToPercent(startYear)
  return `${Math.max(0.5, width)}%`
}

const currentDayPercent = computed(() => {
  if (currentDayYear.value === null) return null
  return `${Math.max(0, Math.min(100, yearToPercent(currentDayYear.value)))}%`
})

// Generate year labels for the axis
const yearLabels = computed(() => {
  const span = totalYears.value
  let step = 100
  if (span <= 100) step = 10
  else if (span <= 500) step = 50
  else if (span <= 2000) step = 100
  else step = 500

  const labels = []
  const firstLabel = Math.ceil(universeStartYear.value / step) * step
  for (let y = firstLabel; y <= universeEndYear.value; y += step) {
    labels.push(y)
  }
  return labels
})

// Assign row indexes to avoid overlapping events
const eventRows = computed(() => {
  const rows: Array<{ event: ChronicleEvent; row: number }> = []
  const rowEnds: number[] = []

  const sorted = [...props.events].sort((a, b) => a.startDate.localeCompare(b.startDate))

  for (const ev of sorted) {
    const startYear = dateToYear(ev.startDate)
    const endYear = ev.endDate ? dateToYear(ev.endDate) : startYear + 1

    let row = 0
    while (rowEnds[row] !== undefined && rowEnds[row]! > startYear) {
      row++
    }
    rowEnds[row] = endYear + 1
    rows.push({ event: ev, row })
  }

  return rows
})

const maxRow = computed(() => {
  const max = Math.max(...eventRows.value.map(r => r.row), 0)
  return max
})

const timelineHeight = computed(() => (maxRow.value + 1) * 36 + 40)
</script>

<template>
  <div class="timeline-wrap">
    <div v-if="!settings" class="empty-state">Configure universe settings to see the timeline.</div>
    <div v-else class="timeline" :style="{ height: `${timelineHeight}px` }">
      <!-- Year axis -->
      <div class="axis">
        <div
          v-for="year in yearLabels"
          :key="year"
          class="axis-label"
          :style="{ left: `${yearToPercent(year)}%` }"
        >
          {{ year }}
        </div>
      </div>

      <!-- Current Day marker -->
      <div
        v-if="currentDayPercent"
        class="current-day-line"
        :style="{ left: currentDayPercent }"
        :title="`Current Day: ${settings.currentDay}`"
      />

      <!-- Events -->
      <div
        v-for="{ event, row } in eventRows"
        :key="event.id"
        class="event-bar"
        :class="{
          'event-bar-current': event.isCurrentDay,
          'event-bar-point': !event.endDate
        }"
        :style="{
          left: eventLeft(event),
          width: eventWidth(event),
          top: `${row * 36 + 32}px`
        }"
        :title="`${event.name} (${event.startDate}${event.endDate ? ' – ' + event.endDate : ''})`"
        @click="emit('edit', event)"
      >
        <span class="event-label">{{ event.name }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.timeline-wrap {
  width: 100%;
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  background-color: var(--color-card);
}

.timeline {
  position: relative;
  min-width: 600px;
  padding: 0 1rem 1rem;
}

.axis {
  position: relative;
  height: 28px;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 4px;
}

.axis-label {
  position: absolute;
  bottom: 4px;
  transform: translateX(-50%);
  font-size: 0.75rem;
  color: var(--color-muted-foreground);
  white-space: nowrap;
}

.current-day-line {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 2px;
  background-color: var(--color-primary);
  opacity: 0.7;
  z-index: 5;
  cursor: default;
}

.event-bar {
  position: absolute;
  height: 24px;
  border-radius: var(--radius-sm);
  background-color: var(--color-accent);
  border: 1px solid var(--color-border);
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: 0 0.375rem;
  overflow: hidden;
  transition: background-color 0.15s;
  min-width: 6px;
  z-index: 2;
}

.event-bar:hover {
  background-color: color-mix(in srgb, var(--color-accent) 70%, var(--color-primary));
  border-color: var(--color-primary);
}

.event-bar-current {
  background-color: color-mix(in srgb, var(--color-primary) 25%, var(--color-card));
  border-color: var(--color-primary);
}

.event-bar-point {
  width: 8px !important;
  border-radius: 50%;
  padding: 0;
}

.event-label {
  font-size: 0.75rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: var(--color-foreground);
}

.event-bar-point .event-label {
  display: none;
}
</style>
