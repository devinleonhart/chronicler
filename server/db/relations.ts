import { relations } from 'drizzle-orm/relations'
import { character, group, characterGroup, event, eventCharacter } from './schema.js'

export const characterRelations = relations(character, ({ many }) => ({
  characterGroups: many(characterGroup),
  eventCharacters: many(eventCharacter),
}))

export const groupRelations = relations(group, ({ many }) => ({
  characterGroups: many(characterGroup),
}))

export const characterGroupRelations = relations(characterGroup, ({ one }) => ({
  character: one(character, {
    fields: [characterGroup.characterId],
    references: [character.id]
  }),
  group: one(group, {
    fields: [characterGroup.groupId],
    references: [group.id]
  }),
}))

export const eventRelations = relations(event, ({ many }) => ({
  eventCharacters: many(eventCharacter),
}))

export const eventCharacterRelations = relations(eventCharacter, ({ one }) => ({
  event: one(event, {
    fields: [eventCharacter.eventId],
    references: [event.id]
  }),
  character: one(character, {
    fields: [eventCharacter.characterId],
    references: [character.id]
  }),
}))
