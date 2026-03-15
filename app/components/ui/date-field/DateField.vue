<script setup lang="ts">
import { computed } from 'vue'
import {
  DatePickerRoot,
  DatePickerField,
  DatePickerInput,
  DatePickerTrigger,
  DatePickerContent,
  DatePickerCalendar,
  DatePickerHeader,
  DatePickerHeading,
  DatePickerPrev,
  DatePickerNext,
  DatePickerGrid,
  DatePickerGridHead,
  DatePickerGridBody,
  DatePickerGridRow,
  DatePickerHeadCell,
  DatePickerCell,
  DatePickerCellTrigger
} from 'radix-vue'
import { CalendarDate, type DateValue } from '@internationalized/date'
import { Calendar, ChevronLeft, ChevronRight } from 'lucide-vue-next'

interface Props {
  modelValue?: string
  minValue?: string
  maxValue?: string
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  disabled: false
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

function parseDate(str: string | undefined): CalendarDate | undefined {
  if (!str) return undefined
  const parts = str.split('-')
  const year = parseInt(parts[0] ?? '', 10)
  const month = parseInt(parts[1] ?? '', 10)
  const day = parseInt(parts[2] ?? '', 10)
  if (isNaN(year) || isNaN(month) || isNaN(day)) return undefined
  return new CalendarDate(year, month, day)
}

const dateValue = computed(() => parseDate(props.modelValue))
const minDate = computed(() => parseDate(props.minValue))
const maxDate = computed(() => parseDate(props.maxValue))
const placeholder = computed(() => parseDate(props.minValue))

function handleUpdate(val: DateValue | undefined) {
  emit('update:modelValue', val ? val.toString() : '')
}

function prevYear(date: DateValue): DateValue {
  return date.subtract({ years: 1 })
}

function nextYear(date: DateValue): DateValue {
  return date.add({ years: 1 })
}
</script>

<template>
  <DatePickerRoot
    :model-value="dateValue"
    :min-value="minDate"
    :max-value="maxDate"
    :placeholder="placeholder"
    :disabled="disabled"
    @update:model-value="handleUpdate"
  >
    <div class="date-picker-wrapper" :data-disabled="disabled || undefined">
      <DatePickerField v-slot="{ segments }" class="date-picker-field">
        <template v-for="{ part, value } in segments" :key="part">
          <span v-if="part === 'literal'" class="literal" aria-hidden="true">{{ value }}</span>
          <DatePickerInput v-else :part="part" class="segment">{{ value }}</DatePickerInput>
        </template>
      </DatePickerField>
      <DatePickerTrigger class="cal-trigger">
        <Calendar :size="15" />
      </DatePickerTrigger>
    </div>

    <DatePickerContent class="cal-content" side="bottom" align="start" :side-offset="4">
      <DatePickerCalendar v-slot="{ weekDays, grid }">
        <DatePickerHeader class="cal-header">
          <DatePickerPrev :prev-page="prevYear" class="cal-nav-btn" title="Previous year">«</DatePickerPrev>
          <DatePickerPrev class="cal-nav-btn" title="Previous month">
            <ChevronLeft :size="14" />
          </DatePickerPrev>
          <DatePickerHeading v-slot="{ headingValue }" class="cal-heading">
            {{ headingValue }}
          </DatePickerHeading>
          <DatePickerNext class="cal-nav-btn" title="Next month">
            <ChevronRight :size="14" />
          </DatePickerNext>
          <DatePickerNext :next-page="nextYear" class="cal-nav-btn" title="Next year">»</DatePickerNext>
        </DatePickerHeader>

        <DatePickerGrid
          v-for="month in grid"
          :key="month.value.toString()"
          class="cal-grid"
        >
          <DatePickerGridHead>
            <DatePickerGridRow class="cal-week-row">
              <DatePickerHeadCell
                v-for="day in weekDays"
                :key="day"
                class="cal-head-cell"
              >
                {{ day }}
              </DatePickerHeadCell>
            </DatePickerGridRow>
          </DatePickerGridHead>
          <DatePickerGridBody>
            <DatePickerGridRow
              v-for="(weekDates, i) in month.rows"
              :key="i"
              class="cal-week-row"
            >
              <DatePickerCell
                v-for="date in weekDates"
                :key="date.toString()"
                :date="date"
                class="cal-cell"
              >
                <DatePickerCellTrigger
                  :day="date"
                  :month="month.value"
                  class="cal-day"
                />
              </DatePickerCell>
            </DatePickerGridRow>
          </DatePickerGridBody>
        </DatePickerGrid>
      </DatePickerCalendar>
    </DatePickerContent>
  </DatePickerRoot>
</template>

<style scoped>
.date-picker-wrapper {
  display: flex;
  align-items: stretch;
  width: 100%;
  background-color: var(--color-background);
  border: 1px solid var(--color-input);
  border-radius: var(--radius-md);
  transition: border-color 0.15s, box-shadow 0.15s;
  overflow: hidden;
}

.date-picker-wrapper:focus-within {
  border-color: var(--color-ring);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--color-ring) 25%, transparent);
}

.date-picker-wrapper[data-disabled] {
  opacity: 0.5;
  cursor: not-allowed;
}

:deep(.date-picker-field) {
  flex: 1;
  display: flex;
  align-items: center;
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  font-family: inherit;
  cursor: text;
  gap: 1px;
}

:deep(.segment) {
  padding: 0 2px;
  border-radius: 2px;
  outline: none;
  caret-color: transparent;
}

:deep(.segment[data-placeholder]) {
  color: var(--color-muted-foreground);
}

:deep(.segment[data-focused]) {
  background-color: var(--color-primary);
  color: var(--color-primary-foreground);
}

.literal {
  color: var(--color-muted-foreground);
  user-select: none;
}

.cal-trigger {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 0.625rem;
  border: none;
  border-left: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-muted-foreground);
  cursor: pointer;
  transition: background-color 0.15s, color 0.15s;
  flex-shrink: 0;
}

.cal-trigger:hover {
  background-color: var(--color-accent);
  color: var(--color-foreground);
}
</style>
