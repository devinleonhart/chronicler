<script setup lang="ts">
import { CheckboxRoot } from 'radix-vue'
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
  <CheckboxRoot
    class="checkbox-root"
    :checked="checked"
    :disabled="disabled"
    :class="props.class"
    @update:checked="emit('update:checked', $event)"
  >
    <span class="checkbox-box">
      <Check v-if="checked" :size="11" />
    </span>
  </CheckboxRoot>
</template>

<style scoped>
.checkbox-root {
  all: unset;
  display: inline-flex;
  cursor: pointer;
  flex-shrink: 0;
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

.checkbox-root[data-state='checked'] .checkbox-box {
  background-color: var(--color-primary);
  border-color: var(--color-primary);
}

.checkbox-root[data-disabled] .checkbox-box {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
