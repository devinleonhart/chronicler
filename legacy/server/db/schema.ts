import { pgTable, timestamp, text, integer, serial, boolean, foreignKey, primaryKey, varchar } from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

export const universeSettings = pgTable('UniverseSettings', {
  id: serial().primaryKey().notNull(),
  createdAt: timestamp({ precision: 3, mode: 'string' }).default(sql`CURRENT_TIMESTAMP`).notNull(),
  updatedAt: timestamp({ precision: 3, mode: 'string' }).notNull(),
  name: varchar({ length: 255 }).notNull().default('My Universe'),
  startDate: varchar({ length: 10 }).notNull(),
  endDate: varchar({ length: 10 }).notNull(),
  currentDay: varchar({ length: 10 }).notNull(),
})

export const group = pgTable('Group', {
  id: serial().primaryKey().notNull(),
  createdAt: timestamp({ precision: 3, mode: 'string' }).default(sql`CURRENT_TIMESTAMP`).notNull(),
  updatedAt: timestamp({ precision: 3, mode: 'string' }).notNull(),
  name: varchar({ length: 255 }).notNull(),
  description: text(),
})

export const character = pgTable('Character', {
  id: serial().primaryKey().notNull(),
  createdAt: timestamp({ precision: 3, mode: 'string' }).default(sql`CURRENT_TIMESTAMP`).notNull(),
  updatedAt: timestamp({ precision: 3, mode: 'string' }).notNull(),
  name: varchar({ length: 255 }).notNull(),
  birthDate: varchar({ length: 10 }).notNull(),
  deathDate: varchar({ length: 10 }),
})

export const characterGroup = pgTable('CharacterGroup', {
  characterId: integer().notNull(),
  groupId: integer().notNull(),
}, (table) => [
  foreignKey({
    columns: [table.characterId],
    foreignColumns: [character.id],
    name: 'CharacterGroup_characterId_fkey'
  }).onUpdate('cascade').onDelete('cascade'),
  foreignKey({
    columns: [table.groupId],
    foreignColumns: [group.id],
    name: 'CharacterGroup_groupId_fkey'
  }).onUpdate('cascade').onDelete('cascade'),
  primaryKey({ columns: [table.characterId, table.groupId], name: 'CharacterGroup_pkey' }),
])

export const event = pgTable('Event', {
  id: serial().primaryKey().notNull(),
  createdAt: timestamp({ precision: 3, mode: 'string' }).default(sql`CURRENT_TIMESTAMP`).notNull(),
  updatedAt: timestamp({ precision: 3, mode: 'string' }).notNull(),
  name: varchar({ length: 255 }).notNull(),
  startDate: varchar({ length: 10 }).notNull(),
  endDate: varchar({ length: 10 }),
  isCurrentDay: boolean().default(false).notNull(),
})

export const eventCharacter = pgTable('EventCharacter', {
  eventId: integer().notNull(),
  characterId: integer().notNull(),
}, (table) => [
  foreignKey({
    columns: [table.eventId],
    foreignColumns: [event.id],
    name: 'EventCharacter_eventId_fkey'
  }).onUpdate('cascade').onDelete('cascade'),
  foreignKey({
    columns: [table.characterId],
    foreignColumns: [character.id],
    name: 'EventCharacter_characterId_fkey'
  }).onUpdate('cascade').onDelete('cascade'),
  primaryKey({ columns: [table.eventId, table.characterId], name: 'EventCharacter_pkey' }),
])
