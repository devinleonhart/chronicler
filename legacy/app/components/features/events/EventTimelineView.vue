<script setup lang="ts">
import { onMounted, onBeforeUnmount, watch, ref } from 'vue'
import { Timeline } from 'vis-timeline/standalone'
import { DataSet } from 'vis-data'
import 'vis-timeline/styles/vis-timeline-graph2d.css'
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

const container = ref<HTMLElement | null>(null)
let timeline: Timeline | null = null

function buildItems() {
  return new DataSet(
    props.events.map(ev => ({
      id: ev.id,
      content: ev.name,
      start: ev.startDate,
      end: ev.endDate ?? undefined,
      type: ev.endDate ? 'range' : 'box',
      title: `${ev.name}<br>${ev.startDate}${ev.endDate ? ' – ' + ev.endDate : ''}`,
      className: ev.isCurrentDay ? 'item-current-day' : 'item-event'
    }))
  )
}

function buildOptions() {
  return {
    min: props.settings?.startDate,
    max: props.settings?.endDate,
    start: props.settings?.startDate,
    end: props.settings?.endDate,
    stack: true,
    showMajorLabels: true,
    showMinorLabels: true,
    orientation: { axis: 'top' },
    zoomMin: 1000 * 60 * 60 * 24 * 365,     // 1 year minimum zoom
    tooltip: { followMouse: true, overflowMethod: 'flip' as const },
    selectable: true
  }
}

function initTimeline() {
  if (!container.value) return

  const items = buildItems()
  timeline = new Timeline(container.value, items, buildOptions())

  // Current Day marker
  if (props.settings?.currentDay) {
    timeline.addCustomTime(new Date(props.settings.currentDay), 'currentDay')
  }

  // Click to edit
  timeline.on('select', (params) => {
    if (params.items.length === 0) return
    const id = params.items[0] as number
    const ev = props.events.find(e => e.id === id)
    if (ev) emit('edit', ev)
    // Deselect immediately so clicking the same item again still fires
    timeline?.setSelection([])
  })
}

function refreshTimeline() {
  if (!timeline) return
  timeline.setItems(buildItems())
  timeline.setOptions(buildOptions())

  try { timeline.removeCustomTime('currentDay') } catch { /* not yet added */ }
  if (props.settings?.currentDay) {
    timeline.addCustomTime(new Date(props.settings.currentDay), 'currentDay')
  }
}

onMounted(initTimeline)
onBeforeUnmount(() => { timeline?.destroy(); timeline = null })

watch(() => [props.events, props.settings], refreshTimeline, { deep: true })
</script>

<template>
  <div v-if="!settings" class="empty-state">
    Configure universe settings to see the timeline.
  </div>
  <div v-else ref="container" class="timeline-container" />
</template>

<style>
/* Override vis-timeline default light theme with our dark palette */
.vis-timeline {
  border: 1px solid var(--color-border) !important;
  border-radius: var(--radius-lg) !important;
  background-color: var(--color-card) !important;
  font-family: inherit !important;
}

.vis-panel.vis-top,
.vis-panel.vis-bottom,
.vis-panel.vis-left,
.vis-panel.vis-right,
.vis-panel.vis-center,
.vis-panel.vis-background {
  border-color: var(--color-border) !important;
}

.vis-labelset .vis-label,
.vis-time-axis .vis-text {
  color: var(--color-muted-foreground) !important;
}

.vis-time-axis .vis-grid.vis-minor {
  border-color: color-mix(in srgb, var(--color-border) 40%, transparent) !important;
}

.vis-time-axis .vis-grid.vis-major {
  border-color: var(--color-border) !important;
}

.vis-item.item-event {
  background-color: var(--color-accent) !important;
  border-color: var(--color-border) !important;
  color: var(--color-foreground) !important;
  border-radius: var(--radius-sm) !important;
  font-size: 0.8125rem !important;
}

.vis-item.item-event.vis-selected {
  background-color: color-mix(in srgb, var(--color-primary) 30%, var(--color-accent)) !important;
  border-color: var(--color-primary) !important;
}

.vis-item.item-event:hover {
  background-color: color-mix(in srgb, var(--color-accent) 70%, var(--color-primary)) !important;
  border-color: var(--color-primary) !important;
}

.vis-item.item-current-day {
  background-color: color-mix(in srgb, var(--color-primary) 25%, var(--color-card)) !important;
  border-color: var(--color-primary) !important;
  color: var(--color-foreground) !important;
  border-radius: var(--radius-sm) !important;
  font-size: 0.8125rem !important;
}

.vis-item .vis-item-content {
  padding: 2px 8px !important;
}

/* Box-type items (single date) */
.vis-item.vis-box.item-event {
  border-color: var(--color-border) !important;
}

.vis-item.vis-box.item-event .vis-item-dot {
  border-color: var(--color-border) !important;
}

.vis-item.vis-box.item-event .vis-item-line {
  border-color: var(--color-border) !important;
}

.vis-item.vis-box.item-event:hover .vis-item-dot,
.vis-item.vis-box.item-event:hover .vis-item-line {
  border-color: var(--color-primary) !important;
}

/* Current Day custom time marker */
.vis-custom-time.currentDay {
  background-color: var(--color-primary) !important;
  opacity: 0.8;
  width: 2px !important;
  cursor: default !important;
  pointer-events: none;
}

.vis-custom-time.currentDay .vis-custom-time-marker {
  background-color: var(--color-primary) !important;
  color: var(--color-primary-foreground) !important;
  border-radius: var(--radius-sm) !important;
  font-size: 0.75rem !important;
  white-space: nowrap;
}

.vis-tooltip {
  background-color: var(--color-popover) !important;
  color: var(--color-popover-foreground) !important;
  border: 1px solid var(--color-border) !important;
  border-radius: var(--radius-md) !important;
  font-size: 0.8125rem !important;
  font-family: inherit !important;
}
</style>

<style scoped>
.timeline-container {
  width: 100%;
  min-height: 200px;
}

.empty-state {
  color: var(--color-muted-foreground);
  font-style: italic;
  padding: 2rem;
  text-align: center;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
}
</style>
