<script setup lang="ts">
import { DialogContent, DialogClose } from 'reka-ui'
import { X } from '@lucide/vue'

interface Props {
  class?: string
}

const props = defineProps<Props>()
</script>

<template>
  <DialogContent class="dialog-content" :class="props.class">
    <slot />
    <DialogClose class="dialog-close">
      <X />
      <span class="sr-only">Close</span>
    </DialogClose>
  </DialogContent>
</template>
