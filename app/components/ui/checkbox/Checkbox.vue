<script setup lang="ts">
import { Check } from 'lucide-vue-next'

interface Props {
  checked?: boolean
  disabled?: boolean
  class?: string
}

const props = withDefaults(defineProps<Props>(), {
  checked: false,
  disabled: false
})

const emit = defineEmits<{
  'update:checked': [value: boolean]
}>()
</script>

<template>
  <button
    type="button"
    role="checkbox"
    :aria-checked="checked"
    :disabled="disabled"
    class="checkbox-root"
    :class="props.class"
    @click.stop="emit('update:checked', !checked)"
  >
    <span class="checkbox-box">
      <Check v-if="checked" :size="11" />
    </span>
  </button>
</template>

<style scoped>
.checkbox-root {
  appearance: none;
  -webkit-appearance: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
  padding: 0;
  margin: 0;
  border: none;
  background: none;
  outline: none;
}

.checkbox-root:focus-visible .checkbox-box {
  box-shadow: 0 0 0 2px var(--color-ring);
}

.checkbox-box {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 1.125rem;
  height: 1.125rem;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-input);
  background-color: var(--color-background);
  color: white;
  flex-shrink: 0;
  transition: background-color 0.15s, border-color 0.15s;
}

.checkbox-root[aria-checked='true'] .checkbox-box {
  background-color: var(--color-primary);
  border-color: var(--color-primary);
}

.checkbox-root:disabled .checkbox-box {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
