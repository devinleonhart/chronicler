<script setup lang="ts">
import { computed } from 'vue'
import { DateFieldRoot, DateFieldInput } from 'radix-vue'
import { CalendarDate, type DateValue } from '@internationalized/date'

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
</script>

<template>
  <DateFieldRoot
    class="date-field"
    :model-value="dateValue"
    :min-value="minDate"
    :max-value="maxDate"
    :placeholder="placeholder"
    :disabled="disabled"
    @update:model-value="handleUpdate"
  >
    <template #default="{ segments }">
      <template v-for="{ part, value } in segments" :key="part">
        <span v-if="part === 'literal'" class="literal" aria-hidden="true">{{ value }}</span>
        <DateFieldInput v-else :part="part" class="segment" />
      </template>
    </template>
  </DateFieldRoot>
</template>

<style scoped>
.date-field {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 0.5rem 0.75rem;
  background-color: var(--color-background);
  color: var(--color-foreground);
  border: 1px solid var(--color-input);
  border-radius: var(--radius-md);
  font-size: 0.875rem;
  font-family: inherit;
  line-height: 1.5;
  transition: border-color 0.15s, box-shadow 0.15s;
  cursor: text;
}

.date-field:focus-within {
  border-color: var(--color-ring);
  box-shadow: 0 0 0 2px color-mix(in srgb, var(--color-ring) 25%, transparent);
}

.date-field[data-disabled] {
  opacity: 0.5;
  cursor: not-allowed;
}

.date-field[data-invalid] {
  border-color: var(--color-destructive);
}

:deep(.segment) {
  padding: 0 1px;
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
</style>
