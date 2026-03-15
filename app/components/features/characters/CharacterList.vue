<script setup lang="ts">
import type { Character } from '@/types/store/characters'
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
import { Pencil, Trash2 } from 'lucide-vue-next'

interface Props {
  characters: Character[]
}

defineProps<Props>()

const emit = defineEmits<{
  edit: [character: Character]
  delete: [id: number]
}>()
</script>

<template>
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead>Name</TableHead>
        <TableHead>Birth Date</TableHead>
        <TableHead>Death Date</TableHead>
        <TableHead>Groups</TableHead>
        <TableHead></TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      <TableRow v-for="character in characters" :key="character.id">
        <TableCell>
          <span class="name">{{ character.name }}</span>
        </TableCell>
        <TableCell>
          <span class="sub">{{ character.birthDate }}</span>
        </TableCell>
        <TableCell>
          <span v-if="character.deathDate" class="deceased-badge sub">{{ character.deathDate }}</span>
          <span v-else class="sub muted">—</span>
        </TableCell>
        <TableCell>
          <div class="badge-group">
            <Badge
              v-for="cg in character.characterGroups"
              :key="cg.groupId"
              variant="secondary"
            >
              {{ cg.group.name }}
            </Badge>
            <span v-if="character.characterGroups.length === 0" class="sub muted">—</span>
          </div>
        </TableCell>
        <TableCell>
          <div class="actions">
            <Button variant="ghost" size="icon" @click="emit('edit', character)">
              <Pencil />
            </Button>
            <Button variant="ghost" size="icon" @click="emit('delete', character.id)">
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

.deceased-badge {
  color: var(--color-destructive);
}
</style>
