<script setup lang="ts">
import type { Group } from '@/types/store/groups'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell
} from '@/components/ui/table'
import { Pencil, Trash2 } from 'lucide-vue-next'

interface Props {
  groups: Group[]
}

defineProps<Props>()

const emit = defineEmits<{
  edit: [group: Group]
  delete: [id: number]
}>()
</script>

<template>
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead>Name</TableHead>
        <TableHead>Description</TableHead>
        <TableHead>Members</TableHead>
        <TableHead></TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      <TableRow v-for="group in groups" :key="group.id">
        <TableCell>
          <span class="name">{{ group.name }}</span>
        </TableCell>
        <TableCell>
          <span v-if="group.description" class="sub">{{ group.description }}</span>
          <span v-else class="sub muted">—</span>
        </TableCell>
        <TableCell>
          <span class="sub">{{ group.characterGroups.length }} character{{ group.characterGroups.length !== 1 ? 's' : '' }}</span>
        </TableCell>
        <TableCell>
          <div class="actions">
            <Button variant="ghost" size="icon" @click="emit('edit', group)">
              <Pencil />
            </Button>
            <Button variant="ghost" size="icon" @click="emit('delete', group.id)">
              <Trash2 />
            </Button>
          </div>
        </TableCell>
      </TableRow>
    </TableBody>
  </Table>
</template>

<style scoped>
.name {
  font-weight: 500;
}

.sub {
  font-size: 0.875rem;
  color: var(--color-muted-foreground);
}

.muted {
  color: var(--color-border);
}
</style>
