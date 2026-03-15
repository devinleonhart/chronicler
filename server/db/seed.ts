import pg from 'pg'
import { drizzle } from 'drizzle-orm/node-postgres'
import * as schema from './index.js'
import { getDatabaseUrl } from '../utils/databaseUrls.js'

const { Pool } = pg
const pool = new Pool({ connectionString: getDatabaseUrl() })
const db = drizzle(pool, { schema })

console.log('Seeding Knighthood universe...')

// ── Universe Settings ─────────────────────────────────────────
await db.insert(schema.universeSettings).values({
  name: 'Knighthood',
  startDate: '2173-01-01',
  endDate: '2303-12-31',
  currentDay: '2300-09-25',
  updatedAt: new Date().toISOString()
})

// ── Groups ────────────────────────────────────────────────────
const groupMap: Record<string, number> = {}

const [group_ev06E64dksRLnhMcmReu7] = await db.insert(schema.group).values({
  name: 'Knighthood',
  description: null,
  updatedAt: new Date().toISOString()
}).returning()
groupMap['ev06E64dksRLnhMcmReu7'] = group_ev06E64dksRLnhMcmReu7!.id

const [group_Nz8zlFmoHGG1xcjOCwjzf] = await db.insert(schema.group).values({
  name: 'Civilian',
  description: null,
  updatedAt: new Date().toISOString()
}).returning()
groupMap['Nz8zlFmoHGG1xcjOCwjzf'] = group_Nz8zlFmoHGG1xcjOCwjzf!.id

const [group_4MhWYE07w3jXI0Jle36Ld] = await db.insert(schema.group).values({
  name: 'Ingrium Cell',
  description: null,
  updatedAt: new Date().toISOString()
}).returning()
groupMap['4MhWYE07w3jXI0Jle36Ld'] = group_4MhWYE07w3jXI0Jle36Ld!.id

const [group_UyID5qn1UrRQrfut6yxvP] = await db.insert(schema.group).values({
  name: 'Nomad Cell',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['UyID5qn1UrRQrfut6yxvP'] = group_UyID5qn1UrRQrfut6yxvP!.id

const [group_9GhzRksiFnmHxGCWjBsqu] = await db.insert(schema.group).values({
  name: 'Boothbay Cell',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['9GhzRksiFnmHxGCWjBsqu'] = group_9GhzRksiFnmHxGCWjBsqu!.id

const [group_IdsbVn6gAdeaZJKF1tFeK] = await db.insert(schema.group).values({
  name: 'Arboria Cell',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['IdsbVn6gAdeaZJKF1tFeK'] = group_IdsbVn6gAdeaZJKF1tFeK!.id

const [group_OD0QSl35pUN9BtpCK0Hxh] = await db.insert(schema.group).values({
  name: 'Sunrise Cell',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['OD0QSl35pUN9BtpCK0Hxh'] = group_OD0QSl35pUN9BtpCK0Hxh!.id

const [group_MkL87FaZm8F3U9My5Lg4K] = await db.insert(schema.group).values({
  name: 'Crystalis Cell',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['MkL87FaZm8F3U9My5Lg4K'] = group_MkL87FaZm8F3U9My5Lg4K!.id

const [group_kr3sdIg3ij81jWBGo5CEF] = await db.insert(schema.group).values({
  name: 'Gossamer Cell / Las Lindas',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['kr3sdIg3ij81jWBGo5CEF'] = group_kr3sdIg3ij81jWBGo5CEF!.id

const [group_Qqyrsj59UtI7Tnq2iRrEU] = await db.insert(schema.group).values({
  name: 'Dispatch',
  description: 'Part of Knighthood',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['Qqyrsj59UtI7Tnq2iRrEU'] = group_Qqyrsj59UtI7Tnq2iRrEU!.id

const [group_ZudmL3Vrs0mitCvTmTVrU] = await db.insert(schema.group).values({
  name: 'Trellis',
  description: 'Part of Civilian',
  updatedAt: new Date().toISOString()
}).returning()
groupMap['ZudmL3Vrs0mitCvTmTVrU'] = group_ZudmL3Vrs0mitCvTmTVrU!.id

// ── Characters ───────────────────────────────────────────────
const charMap: Record<string, number> = {}

const [char_vegMDSeT8VfZslLuFBbfW] = await db.insert(schema.character).values({
  name: 'Alicia Santana',
  birthDate: '2278-09-10',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['vegMDSeT8VfZslLuFBbfW'] = char_vegMDSeT8VfZslLuFBbfW!.id

const [char_DxoUDbFEdGXBVmlKoBIc9] = await db.insert(schema.character).values({
  name: 'Caramel White',
  birthDate: '2274-11-17',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['DxoUDbFEdGXBVmlKoBIc9'] = char_DxoUDbFEdGXBVmlKoBIc9!.id

const [char_g9X9NVKcPQ3v5hO6HfvHL] = await db.insert(schema.character).values({
  name: 'Catherine',
  birthDate: '2270-05-19',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['g9X9NVKcPQ3v5hO6HfvHL'] = char_g9X9NVKcPQ3v5hO6HfvHL!.id

const [char_OxcxQ4mWML1fSZwCuO4UW] = await db.insert(schema.character).values({
  name: 'Clive Gustave',
  birthDate: '2274-04-10',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['OxcxQ4mWML1fSZwCuO4UW'] = char_OxcxQ4mWML1fSZwCuO4UW!.id

const [char_21QADh2ACBsfX8iz0xrHj] = await db.insert(schema.character).values({
  name: 'Dale Hoapili',
  birthDate: '2276-02-04',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['21QADh2ACBsfX8iz0xrHj'] = char_21QADh2ACBsfX8iz0xrHj!.id

const [char_WZ4wypWVtSBDt5Bfbo8cC] = await db.insert(schema.character).values({
  name: 'Daphne Price',
  birthDate: '2272-05-15',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['WZ4wypWVtSBDt5Bfbo8cC'] = char_WZ4wypWVtSBDt5Bfbo8cC!.id

const [char_s72gFKZ9z4izVRUPbCfWH] = await db.insert(schema.character).values({
  name: 'Diana Linda',
  birthDate: '2231-10-12',
  deathDate: '2290-11-12',
  updatedAt: new Date().toISOString()
}).returning()
charMap['s72gFKZ9z4izVRUPbCfWH'] = char_s72gFKZ9z4izVRUPbCfWH!.id

const [char_zxDCcgennrkNaUMLThpNw] = await db.insert(schema.character).values({
  name: 'Drake',
  birthDate: '2270-01-01',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['zxDCcgennrkNaUMLThpNw'] = char_zxDCcgennrkNaUMLThpNw!.id

const [char_neyVpwQZIFglDPako23yF] = await db.insert(schema.character).values({
  name: 'Elise DuForte',
  birthDate: '2279-11-01',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['neyVpwQZIFglDPako23yF'] = char_neyVpwQZIFglDPako23yF!.id

const [char_hQK1UsvGx1TaxvYk451L3] = await db.insert(schema.character).values({
  name: 'Ember Guerra',
  birthDate: '2275-07-08',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['hQK1UsvGx1TaxvYk451L3'] = char_hQK1UsvGx1TaxvYk451L3!.id

const [char_NCiV2CyaxnVaYci9DOb5X] = await db.insert(schema.character).values({
  name: 'Fio Maple',
  birthDate: '2276-01-19',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['NCiV2CyaxnVaYci9DOb5X'] = char_NCiV2CyaxnVaYci9DOb5X!.id

const [char_mjboVFq63n8nA4CSP3Ckm] = await db.insert(schema.character).values({
  name: 'Gina Sabatier',
  birthDate: '2273-03-13',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['mjboVFq63n8nA4CSP3Ckm'] = char_mjboVFq63n8nA4CSP3Ckm!.id

const [char_JRPLIlinobYat89R6d993] = await db.insert(schema.character).values({
  name: 'Hope Ravenhurst',
  birthDate: '2272-08-20',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['JRPLIlinobYat89R6d993'] = char_JRPLIlinobYat89R6d993!.id

const [char_ddfQ6XS7JD2flyaPTOAZn] = await db.insert(schema.character).values({
  name: 'Joy Ravenhurst',
  birthDate: '2276-08-20',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['ddfQ6XS7JD2flyaPTOAZn'] = char_ddfQ6XS7JD2flyaPTOAZn!.id

const [char_jYuhNwN2Nz7qw6bKYsKII] = await db.insert(schema.character).values({
  name: 'Kiki Aryoko',
  birthDate: '2275-04-24',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['jYuhNwN2Nz7qw6bKYsKII'] = char_jYuhNwN2Nz7qw6bKYsKII!.id

const [char_crsLU3v2Rwkpg61AJ9DsV] = await db.insert(schema.character).values({
  name: 'Lise Awen',
  birthDate: '2271-09-30',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['crsLU3v2Rwkpg61AJ9DsV'] = char_crsLU3v2Rwkpg61AJ9DsV!.id

const [char_sDvrOQE0MkiBNa5G6Ud8R] = await db.insert(schema.character).values({
  name: 'Lorena Walker',
  birthDate: '2274-09-04',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['sDvrOQE0MkiBNa5G6Ud8R'] = char_sDvrOQE0MkiBNa5G6Ud8R!.id

const [char_eYZUxvbJd2ymAB9mEiEhS] = await db.insert(schema.character).values({
  name: 'Marco Barley',
  birthDate: '2260-12-21',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['eYZUxvbJd2ymAB9mEiEhS'] = char_eYZUxvbJd2ymAB9mEiEhS!.id

const [char_A3TFT65ToxxI7ZoIA07Ct] = await db.insert(schema.character).values({
  name: 'Maria Linda',
  birthDate: '2173-02-02',
  deathDate: '2250-06-20',
  updatedAt: new Date().toISOString()
}).returning()
charMap['A3TFT65ToxxI7ZoIA07Ct'] = char_A3TFT65ToxxI7ZoIA07Ct!.id

const [char_TXaClCXVrOu1WfuztqP3z] = await db.insert(schema.character).values({
  name: 'Max Lionheart',
  birthDate: '2271-09-30',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['TXaClCXVrOu1WfuztqP3z'] = char_TXaClCXVrOu1WfuztqP3z!.id

const [char_fHdFALYp5iFYVn0IFrlSu] = await db.insert(schema.character).values({
  name: 'Miles Lionheart',
  birthDate: '2271-07-31',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['fHdFALYp5iFYVn0IFrlSu'] = char_fHdFALYp5iFYVn0IFrlSu!.id

const [char_uWkBweQYQOQkVuJHiZqcP] = await db.insert(schema.character).values({
  name: 'Mora Linda',
  birthDate: '2259-03-28',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['uWkBweQYQOQkVuJHiZqcP'] = char_uWkBweQYQOQkVuJHiZqcP!.id

const [char_gboD3jRnbn2iGTtLsbD3A] = await db.insert(schema.character).values({
  name: 'Penka Orlav',
  birthDate: '2274-01-10',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['gboD3jRnbn2iGTtLsbD3A'] = char_gboD3jRnbn2iGTtLsbD3A!.id

const [char_IXG9ndG8K8EGhzIDjcSgv] = await db.insert(schema.character).values({
  name: 'Pyrro Guerra',
  birthDate: '2275-07-08',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['IXG9ndG8K8EGhzIDjcSgv'] = char_IXG9ndG8K8EGhzIDjcSgv!.id

const [char_AFCUIu4AvlbgtsQvj8I9E] = await db.insert(schema.character).values({
  name: 'Rachael Saleigh',
  birthDate: '2270-01-01',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['AFCUIu4AvlbgtsQvj8I9E'] = char_AFCUIu4AvlbgtsQvj8I9E!.id

const [char_7uqNNvhCbexeJh0L03aWJ] = await db.insert(schema.character).values({
  name: 'Riposte DuForte',
  birthDate: '2277-12-12',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['7uqNNvhCbexeJh0L03aWJ'] = char_7uqNNvhCbexeJh0L03aWJ!.id

const [char_52hgTVzLw4ZG8NyTsLpk1] = await db.insert(schema.character).values({
  name: 'Rowan Okoye',
  birthDate: '2264-11-04',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['52hgTVzLw4ZG8NyTsLpk1'] = char_52hgTVzLw4ZG8NyTsLpk1!.id

const [char_h4o7ZPmLBemFZmw7Cq1UU] = await db.insert(schema.character).values({
  name: 'Sammy Maclean',
  birthDate: '2254-12-11',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['h4o7ZPmLBemFZmw7Cq1UU'] = char_h4o7ZPmLBemFZmw7Cq1UU!.id

const [char_9S1hIuE13WLrOJcjn2CaX] = await db.insert(schema.character).values({
  name: 'Simon Cooper',
  birthDate: '2274-06-03',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['9S1hIuE13WLrOJcjn2CaX'] = char_9S1hIuE13WLrOJcjn2CaX!.id

const [char_7I52xNDUNHtskjvt8m7te] = await db.insert(schema.character).values({
  name: 'Sophie Cruz',
  birthDate: '2275-11-19',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['7I52xNDUNHtskjvt8m7te'] = char_7I52xNDUNHtskjvt8m7te!.id

const [char_lzAJeRwsHc6RSH1hMwKDF] = await db.insert(schema.character).values({
  name: 'Stephan Wolfe',
  birthDate: '2244-04-09',
  deathDate: '2303-04-26',
  updatedAt: new Date().toISOString()
}).returning()
charMap['lzAJeRwsHc6RSH1hMwKDF'] = char_lzAJeRwsHc6RSH1hMwKDF!.id

const [char_GjOVa6T8K4sDwR3TG1zPK] = await db.insert(schema.character).values({
  name: 'Taffy',
  birthDate: '2270-04-17',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['GjOVa6T8K4sDwR3TG1zPK'] = char_GjOVa6T8K4sDwR3TG1zPK!.id

const [char_bkChrC88denoAJ4rF9fuM] = await db.insert(schema.character).values({
  name: 'Tiggs',
  birthDate: '2271-06-02',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['bkChrC88denoAJ4rF9fuM'] = char_bkChrC88denoAJ4rF9fuM!.id

const [char_O0UOInxaDvnyJ6eswy8LC] = await db.insert(schema.character).values({
  name: 'Tila',
  birthDate: '2245-12-30',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['O0UOInxaDvnyJ6eswy8LC'] = char_O0UOInxaDvnyJ6eswy8LC!.id

const [char_9fsgoYp2Hmks2Gy6K3LG8] = await db.insert(schema.character).values({
  name: 'Toby',
  birthDate: '2272-03-19',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['9fsgoYp2Hmks2Gy6K3LG8'] = char_9fsgoYp2Hmks2Gy6K3LG8!.id

const [char_340LiZFrkGTYPBgRcpDYV] = await db.insert(schema.character).values({
  name: 'Victoria Linda',
  birthDate: '2205-03-01',
  deathDate: '2247-10-20',
  updatedAt: new Date().toISOString()
}).returning()
charMap['340LiZFrkGTYPBgRcpDYV'] = char_340LiZFrkGTYPBgRcpDYV!.id

const [char_9wyZW5xwzEieOOdD5ESm6] = await db.insert(schema.character).values({
  name: 'Vixy',
  birthDate: '2272-04-03',
  deathDate: null,
  updatedAt: new Date().toISOString()
}).returning()
charMap['9wyZW5xwzEieOOdD5ESm6'] = char_9wyZW5xwzEieOOdD5ESm6!.id

// ── Character Group Assignments ───────────────────────────────
await db.insert(schema.characterGroup).values([
  { characterId: charMap['eYZUxvbJd2ymAB9mEiEhS']!, groupId: groupMap['MkL87FaZm8F3U9My5Lg4K']! },
  { characterId: charMap['neyVpwQZIFglDPako23yF']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['bkChrC88denoAJ4rF9fuM']!, groupId: groupMap['OD0QSl35pUN9BtpCK0Hxh']! },
  { characterId: charMap['fHdFALYp5iFYVn0IFrlSu']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['9wyZW5xwzEieOOdD5ESm6']!, groupId: groupMap['OD0QSl35pUN9BtpCK0Hxh']! },
  { characterId: charMap['uWkBweQYQOQkVuJHiZqcP']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['h4o7ZPmLBemFZmw7Cq1UU']!, groupId: groupMap['Qqyrsj59UtI7Tnq2iRrEU']! },
  { characterId: charMap['mjboVFq63n8nA4CSP3Ckm']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['vegMDSeT8VfZslLuFBbfW']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['52hgTVzLw4ZG8NyTsLpk1']!, groupId: groupMap['UyID5qn1UrRQrfut6yxvP']! },
  { characterId: charMap['TXaClCXVrOu1WfuztqP3z']!, groupId: groupMap['UyID5qn1UrRQrfut6yxvP']! },
  { characterId: charMap['jYuhNwN2Nz7qw6bKYsKII']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['ddfQ6XS7JD2flyaPTOAZn']!, groupId: groupMap['9GhzRksiFnmHxGCWjBsqu']! },
  { characterId: charMap['9S1hIuE13WLrOJcjn2CaX']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['NCiV2CyaxnVaYci9DOb5X']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['IXG9ndG8K8EGhzIDjcSgv']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['hQK1UsvGx1TaxvYk451L3']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['gboD3jRnbn2iGTtLsbD3A']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['7uqNNvhCbexeJh0L03aWJ']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['OxcxQ4mWML1fSZwCuO4UW']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['WZ4wypWVtSBDt5Bfbo8cC']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['21QADh2ACBsfX8iz0xrHj']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['7I52xNDUNHtskjvt8m7te']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['sDvrOQE0MkiBNa5G6Ud8R']!, groupId: groupMap['IdsbVn6gAdeaZJKF1tFeK']! },
  { characterId: charMap['340LiZFrkGTYPBgRcpDYV']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['s72gFKZ9z4izVRUPbCfWH']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['A3TFT65ToxxI7ZoIA07Ct']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['JRPLIlinobYat89R6d993']!, groupId: groupMap['OD0QSl35pUN9BtpCK0Hxh']! },
  { characterId: charMap['zxDCcgennrkNaUMLThpNw']!, groupId: groupMap['9GhzRksiFnmHxGCWjBsqu']! },
  { characterId: charMap['GjOVa6T8K4sDwR3TG1zPK']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['DxoUDbFEdGXBVmlKoBIc9']!, groupId: groupMap['Nz8zlFmoHGG1xcjOCwjzf']! },
  { characterId: charMap['9fsgoYp2Hmks2Gy6K3LG8']!, groupId: groupMap['OD0QSl35pUN9BtpCK0Hxh']! },
  { characterId: charMap['crsLU3v2Rwkpg61AJ9DsV']!, groupId: groupMap['UyID5qn1UrRQrfut6yxvP']! },
  { characterId: charMap['AFCUIu4AvlbgtsQvj8I9E']!, groupId: groupMap['kr3sdIg3ij81jWBGo5CEF']! },
  { characterId: charMap['lzAJeRwsHc6RSH1hMwKDF']!, groupId: groupMap['4MhWYE07w3jXI0Jle36Ld']! },
  { characterId: charMap['O0UOInxaDvnyJ6eswy8LC']!, groupId: groupMap['OD0QSl35pUN9BtpCK0Hxh']! },
  { characterId: charMap['g9X9NVKcPQ3v5hO6HfvHL']!, groupId: groupMap['OD0QSl35pUN9BtpCK0Hxh']! }
])

// ── Events ────────────────────────────────────────────────────
const eventMap: Record<string, number> = {}

const [event_4QLb82PzNE2IZBhJGXQzJ] = await db.insert(schema.event).values({
  name: 'End of LL',
  startDate: '2295-05-01',
  endDate: null,
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['4QLb82PzNE2IZBhJGXQzJ'] = event_4QLb82PzNE2IZBhJGXQzJ!.id

const [event_KvuqwQlUScDaos3Q2QLrO] = await db.insert(schema.event).values({
  name: 'The Invasion of Earth',
  startDate: '2196-05-13',
  endDate: '2199-12-03',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['KvuqwQlUScDaos3Q2QLrO'] = event_KvuqwQlUScDaos3Q2QLrO!.id

const [event_vMjbrmM9Yr4F6rLl8ZRhq] = await db.insert(schema.event).values({
  name: 'The Emperor is Defeated',
  startDate: '2199-12-02',
  endDate: '2199-12-02',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['vMjbrmM9Yr4F6rLl8ZRhq'] = event_vMjbrmM9Yr4F6rLl8ZRhq!.id

const [event_ifUytNjaEDheeGEW2zRD4] = await db.insert(schema.event).values({
  name: 'Ambar Activates the Arc',
  startDate: '2199-12-05',
  endDate: '2199-12-05',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['ifUytNjaEDheeGEW2zRD4'] = event_ifUytNjaEDheeGEW2zRD4!.id

const [event_Y7iBxiZRLwYLaB3GrxVXk] = await db.insert(schema.event).values({
  name: 'Neo Earth is Born',
  startDate: '2199-12-06',
  endDate: '2199-12-06',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['Y7iBxiZRLwYLaB3GrxVXk'] = event_Y7iBxiZRLwYLaB3GrxVXk!.id

const [event_6T5oP8oeiQCREMXczDSD5] = await db.insert(schema.event).values({
  name: 'The first Prime Colony is founded.',
  startDate: '2199-12-10',
  endDate: '2199-12-10',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['6T5oP8oeiQCREMXczDSD5'] = event_6T5oP8oeiQCREMXczDSD5!.id

const [event_Bt240KyymsPQo5K5SjP7o] = await db.insert(schema.event).values({
  name: 'Ambar calls the colony ships to Neo Earth',
  startDate: '2202-06-30',
  endDate: '2202-06-30',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['Bt240KyymsPQo5K5SjP7o'] = event_Bt240KyymsPQo5K5SjP7o!.id

const [event_gWQT2fTRZ0rPRFfTMtrMn] = await db.insert(schema.event).values({
  name: 'The Unification',
  startDate: '2204-09-04',
  endDate: '2204-09-04',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['gWQT2fTRZ0rPRFfTMtrMn'] = event_gWQT2fTRZ0rPRFfTMtrMn!.id

const [event_0AIC9eqyZLEUCLdoGqZPc] = await db.insert(schema.event).values({
  name: 'The Horizon Lands',
  startDate: '2204-09-04',
  endDate: '2204-09-04',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['0AIC9eqyZLEUCLdoGqZPc'] = event_0AIC9eqyZLEUCLdoGqZPc!.id

const [event_fwlpEubPB9XOu0IA6yc7b] = await db.insert(schema.event).values({
  name: 'The Aurora Lands',
  startDate: '2204-09-07',
  endDate: '2204-09-07',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['fwlpEubPB9XOu0IA6yc7b'] = event_fwlpEubPB9XOu0IA6yc7b!.id

const [event_hJV1IIc9Mt2xPoOkOiBzp] = await db.insert(schema.event).values({
  name: 'Las Lindas is Founded',
  startDate: '2204-09-13',
  endDate: '2204-09-13',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['hJV1IIc9Mt2xPoOkOiBzp'] = event_hJV1IIc9Mt2xPoOkOiBzp!.id

const [event_mWaALVteFs1g64RE5z6Hu] = await db.insert(schema.event).values({
  name: 'The Comet Lands',
  startDate: '2204-10-01',
  endDate: '2204-10-01',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['mWaALVteFs1g64RE5z6Hu'] = event_mWaALVteFs1g64RE5z6Hu!.id

const [event_8QLDblB2782UqsDV6ZNzL] = await db.insert(schema.event).values({
  name: 'The Knighthood is Formed',
  startDate: '2205-01-01',
  endDate: '2205-01-01',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['8QLDblB2782UqsDV6ZNzL'] = event_8QLDblB2782UqsDV6ZNzL!.id

const [event_VbfA3AM7klUL9KWNYAA5r] = await db.insert(schema.event).values({
  name: 'Diana Runs Las Lindas',
  startDate: '2247-10-20',
  endDate: '2290-11-12',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['VbfA3AM7klUL9KWNYAA5r'] = event_VbfA3AM7klUL9KWNYAA5r!.id

const [event_8QrZcwTkDYxOGG3l4tmSg] = await db.insert(schema.event).values({
  name: 'Tila’s Knighthood Quest',
  startDate: '2263-03-16',
  endDate: '2267-06-13',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['8QrZcwTkDYxOGG3l4tmSg'] = event_8QrZcwTkDYxOGG3l4tmSg!.id

const [event_tYMlQKmBS4l81Z96XFmWW] = await db.insert(schema.event).values({
  name: 'Sammy Maclean\'s Knighthood Quest',
  startDate: '2271-05-13',
  endDate: '2275-10-27',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['tYMlQKmBS4l81Z96XFmWW'] = event_tYMlQKmBS4l81Z96XFmWW!.id

const [event_NJX6szE1jmmdT0rNusjk7] = await db.insert(schema.event).values({
  name: 'Mora runs away from home.',
  startDate: '2275-06-19',
  endDate: '2275-06-19',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['NJX6szE1jmmdT0rNusjk7'] = event_NJX6szE1jmmdT0rNusjk7!.id

const [event_W0nFvJzHUjXosTOzs8e7q] = await db.insert(schema.event).values({
  name: 'Sammy joins Crystalis Cell',
  startDate: '2275-12-29',
  endDate: '2275-12-29',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['W0nFvJzHUjXosTOzs8e7q'] = event_W0nFvJzHUjXosTOzs8e7q!.id

const [event_wlm12BDWNa4cZqjbF9y14] = await db.insert(schema.event).values({
  name: 'Rowan Knighthood Quest',
  startDate: '2284-05-18',
  endDate: '2295-10-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['wlm12BDWNa4cZqjbF9y14'] = event_wlm12BDWNa4cZqjbF9y14!.id

const [event_JkCaTq5FsKVlCMRalOSxO] = await db.insert(schema.event).values({
  name: 'Max meets Rowan @ The Sword!',
  startDate: '2285-10-04',
  endDate: '2285-10-04',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['JkCaTq5FsKVlCMRalOSxO'] = event_JkCaTq5FsKVlCMRalOSxO!.id

const [event_mlckaU0bi8JNnfVh1EFGb] = await db.insert(schema.event).values({
  name: 'Prisim University College Years',
  startDate: '2290-01-31',
  endDate: '2292-01-15',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['mlckaU0bi8JNnfVh1EFGb'] = event_mlckaU0bi8JNnfVh1EFGb!.id

const [event_KvO6u1K52EU4XND1MjpEe] = await db.insert(schema.event).values({
  name: 'Lise’s Knigthood Quest',
  startDate: '2290-01-31',
  endDate: '2295-07-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['KvO6u1K52EU4XND1MjpEe'] = event_KvO6u1K52EU4XND1MjpEe!.id

const [event_Y9LYhdANz46gHOJSo5nEm] = await db.insert(schema.event).values({
  name: 'Daphne’s Knigthood Quest',
  startDate: '2290-03-15',
  endDate: '2294-02-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['Y9LYhdANz46gHOJSo5nEm'] = event_Y9LYhdANz46gHOJSo5nEm!.id

const [event_VohTCeZln1x3XNu6OQBNj] = await db.insert(schema.event).values({
  name: 'Penka’s Knighthood Quest',
  startDate: '2291-03-08',
  endDate: '2295-10-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['VohTCeZln1x3XNu6OQBNj'] = event_VohTCeZln1x3XNu6OQBNj!.id

const [event_1scxVWQ1RDb8n9HBrXwcQ] = await db.insert(schema.event).values({
  name: 'Max’s Knighthood Quest',
  startDate: '2291-05-18',
  endDate: '2295-10-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['1scxVWQ1RDb8n9HBrXwcQ'] = event_1scxVWQ1RDb8n9HBrXwcQ!.id

const [event_qXBqDyvavGxFOsWuQkwAf] = await db.insert(schema.event).values({
  name: 'Pyrro and Ember’s Knighthood Quest',
  startDate: '2291-05-18',
  endDate: '2295-02-10',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['qXBqDyvavGxFOsWuQkwAf'] = event_qXBqDyvavGxFOsWuQkwAf!.id

const [event_GnOnAI4jc3CAZkchuCldO] = await db.insert(schema.event).values({
  name: 'Hope enters PU',
  startDate: '2291-07-01',
  endDate: '2291-07-01',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['GnOnAI4jc3CAZkchuCldO'] = event_GnOnAI4jc3CAZkchuCldO!.id

const [event_qgdboKCUImowX6UK2xQzL] = await db.insert(schema.event).values({
  name: 'Lorena’s Knighthood Quest',
  startDate: '2291-11-07',
  endDate: '2296-06-16',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['qgdboKCUImowX6UK2xQzL'] = event_qgdboKCUImowX6UK2xQzL!.id

const [event_27t2D9uJc9RMsFzz52IcF] = await db.insert(schema.event).values({
  name: 'Riposte’s Knigthood Quest',
  startDate: '2291-12-20',
  endDate: '2296-02-29',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['27t2D9uJc9RMsFzz52IcF'] = event_27t2D9uJc9RMsFzz52IcF!.id

const [event_jcChNMqv6s0FDMz7pTRvv] = await db.insert(schema.event).values({
  name: 'Hope and Miles break up',
  startDate: '2292-01-12',
  endDate: '2292-01-12',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['jcChNMqv6s0FDMz7pTRvv'] = event_jcChNMqv6s0FDMz7pTRvv!.id

const [event_BeAsN1thcfpWUt2mULCkY] = await db.insert(schema.event).values({
  name: 'Hope’s Knighthood Quest',
  startDate: '2292-01-14',
  endDate: '2295-07-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['BeAsN1thcfpWUt2mULCkY'] = event_BeAsN1thcfpWUt2mULCkY!.id

const [event_NzhRYGANDEZqLhmh90XiO] = await db.insert(schema.event).values({
  name: 'Toby’s Knighthood Quest',
  startDate: '2292-01-14',
  endDate: '2295-07-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['NzhRYGANDEZqLhmh90XiO'] = event_NzhRYGANDEZqLhmh90XiO!.id

const [event_mbhocSEBG6aBwucuN1POP] = await db.insert(schema.event).values({
  name: 'Dale’s Knigthood Quest',
  startDate: '2292-02-11',
  endDate: '2296-07-12',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['mbhocSEBG6aBwucuN1POP'] = event_mbhocSEBG6aBwucuN1POP!.id

const [event_nZNbCXS02TH18h0zC2LXf] = await db.insert(schema.event).values({
  name: 'Las Lindas Comic',
  startDate: '2292-02-17',
  endDate: '2295-04-29',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['nZNbCXS02TH18h0zC2LXf'] = event_nZNbCXS02TH18h0zC2LXf!.id

const [event_PyWUI7QpfpKlH9QOzxqk9] = await db.insert(schema.event).values({
  name: 'Mora returns to Las Lindas',
  startDate: '2292-02-17',
  endDate: '2292-02-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['PyWUI7QpfpKlH9QOzxqk9'] = event_PyWUI7QpfpKlH9QOzxqk9!.id

const [event_36BzsUea0N1Vbivfgu8re] = await db.insert(schema.event).values({
  name: 'Gina’s Knighthood Quest',
  startDate: '2292-04-03',
  endDate: '2296-06-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['36BzsUea0N1Vbivfgu8re'] = event_36BzsUea0N1Vbivfgu8re!.id

const [event_jAxnRKNxvIOnP6PSgPnLN] = await db.insert(schema.event).values({
  name: 'Clive’s Knigthood Quest',
  startDate: '2292-06-20',
  endDate: '2296-08-04',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['jAxnRKNxvIOnP6PSgPnLN'] = event_jAxnRKNxvIOnP6PSgPnLN!.id

const [event_BGPLksjRq3Ezcz87hTkNL] = await db.insert(schema.event).values({
  name: 'Simon’s Knighthood Quest',
  startDate: '2292-08-24',
  endDate: '2296-06-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['BGPLksjRq3Ezcz87hTkNL'] = event_BGPLksjRq3Ezcz87hTkNL!.id

const [event_is6JnA0zOvY7r8iyPVsge] = await db.insert(schema.event).values({
  name: 'Sophie’s Knighthood Quest',
  startDate: '2292-09-01',
  endDate: '2296-07-12',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['is6JnA0zOvY7r8iyPVsge'] = event_is6JnA0zOvY7r8iyPVsge!.id

const [event_VwNY6HjNEpHV3sua1Vlww] = await db.insert(schema.event).values({
  name: 'Tiggs\' Knighthood Quest',
  startDate: '2292-10-30',
  endDate: '2297-10-26',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['VwNY6HjNEpHV3sua1Vlww'] = event_VwNY6HjNEpHV3sua1Vlww!.id

const [event_sSU0utwB1X757eMPxeJak] = await db.insert(schema.event).values({
  name: 'Vixy\'s Knighthood Quest',
  startDate: '2292-10-30',
  endDate: '2297-10-26',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['sSU0utwB1X757eMPxeJak'] = event_sSU0utwB1X757eMPxeJak!.id

const [event_ZMjngvQ0jhnYeSl6AupKC] = await db.insert(schema.event).values({
  name: 'Fio’s Knighthood Quest',
  startDate: '2292-10-30',
  endDate: '2296-06-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['ZMjngvQ0jhnYeSl6AupKC'] = event_ZMjngvQ0jhnYeSl6AupKC!.id

const [event_Ra5d6N7coJ1AOJG2ptdsq] = await db.insert(schema.event).values({
  name: 'Kiki’s Knighthood Quest',
  startDate: '2293-04-03',
  endDate: '2296-06-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['Ra5d6N7coJ1AOJG2ptdsq'] = event_Ra5d6N7coJ1AOJG2ptdsq!.id

const [event_FS3N6XRbIGFoaipoupc5G] = await db.insert(schema.event).values({
  name: 'Joy Ravenhursts’ Knighthood Quest',
  startDate: '2294-04-02',
  endDate: '2297-04-06',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['FS3N6XRbIGFoaipoupc5G'] = event_FS3N6XRbIGFoaipoupc5G!.id

const [event_0l9ZVRGZyrL1cwiCjLUgE] = await db.insert(schema.event).values({
  name: 'Knighthood Comic',
  startDate: '2294-04-02',
  endDate: '2297-04-06',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['0l9ZVRGZyrL1cwiCjLUgE'] = event_0l9ZVRGZyrL1cwiCjLUgE!.id

const [event_FltEe7VnHJHD51ILTp22P] = await db.insert(schema.event).values({
  name: 'Joy meets Drake',
  startDate: '2294-07-03',
  endDate: '2294-07-03',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['FltEe7VnHJHD51ILTp22P'] = event_FltEe7VnHJHD51ILTp22P!.id

const [event_tIDFxB8UgdWVO1RDmldrl] = await db.insert(schema.event).values({
  name: 'Sammy is promoted to Dispatch',
  startDate: '2294-12-30',
  endDate: '2294-12-30',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['tIDFxB8UgdWVO1RDmldrl'] = event_tIDFxB8UgdWVO1RDmldrl!.id

const [event_Rl2fzA3RXKb0jmSANMWmY] = await db.insert(schema.event).values({
  name: 'Elise DuForte’s Knighthood Quest',
  startDate: '2295-01-01',
  endDate: '2298-12-16',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['Rl2fzA3RXKb0jmSANMWmY'] = event_Rl2fzA3RXKb0jmSANMWmY!.id

const [event_kvPrxrHMM7S3MEWJGlRdF] = await db.insert(schema.event).values({
  name: 'Alicia Santana’s Knighthood Quest',
  startDate: '2295-01-02',
  endDate: '2298-06-14',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['kvPrxrHMM7S3MEWJGlRdF'] = event_kvPrxrHMM7S3MEWJGlRdF!.id

const [event_O8Ql8uk21cknfxFBGVA6D] = await db.insert(schema.event).values({
  name: 'Taffy’s Knighthood Quest',
  startDate: '2295-04-28',
  endDate: '2299-02-16',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['O8Ql8uk21cknfxFBGVA6D'] = event_O8Ql8uk21cknfxFBGVA6D!.id

const [event_alS5IQr4iISi0WFmeY8GG] = await db.insert(schema.event).values({
  name: 'Miles Lionheart’s Knighthood Quest',
  startDate: '2295-04-29',
  endDate: '2299-04-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['alS5IQr4iISi0WFmeY8GG'] = event_alS5IQr4iISi0WFmeY8GG!.id

const [event_tOatY8tITDO537Sy87k1r] = await db.insert(schema.event).values({
  name: 'Rachael’s Knighthood Quest',
  startDate: '2295-04-29',
  endDate: '2299-04-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['tOatY8tITDO537Sy87k1r'] = event_tOatY8tITDO537Sy87k1r!.id

const [event_ajBZL32gNht61oVkvNuTk] = await db.insert(schema.event).values({
  name: 'Caramel Returs From Japan',
  startDate: '2295-08-12',
  endDate: '2295-08-12',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['ajBZL32gNht61oVkvNuTk'] = event_ajBZL32gNht61oVkvNuTk!.id

const [event_DUZ17uhRFi1eT1jr1YlRc] = await db.insert(schema.event).values({
  name: 'Trellis',
  startDate: '2295-08-12',
  endDate: '2299-09-18',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['DUZ17uhRFi1eT1jr1YlRc'] = event_DUZ17uhRFi1eT1jr1YlRc!.id

const [event_FIf4UMbHk6DCNxCe9Yk8g] = await db.insert(schema.event).values({
  name: 'Arboria Cell',
  startDate: '2296-06-01',
  endDate: '2299-09-18',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['FIf4UMbHk6DCNxCe9Yk8g'] = event_FIf4UMbHk6DCNxCe9Yk8g!.id

const [event_adFAIsGT24WRYoQN26BGv] = await db.insert(schema.event).values({
  name: 'Arboria Cell is formed!',
  startDate: '2296-06-08',
  endDate: '2296-06-08',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['adFAIsGT24WRYoQN26BGv'] = event_adFAIsGT24WRYoQN26BGv!.id

const [event_y7w4o1qWLLdWzn09HQ6x4] = await db.insert(schema.event).values({
  name: 'Lorena joins Arboria Cell',
  startDate: '2296-07-03',
  endDate: '2296-07-03',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['y7w4o1qWLLdWzn09HQ6x4'] = event_y7w4o1qWLLdWzn09HQ6x4!.id

const [event_wA20hnZOrisXCjecfawRM] = await db.insert(schema.event).values({
  name: 'Riposte joins Arboria Cell',
  startDate: '2296-08-09',
  endDate: '2296-08-09',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['wA20hnZOrisXCjecfawRM'] = event_wA20hnZOrisXCjecfawRM!.id

const [event_5wbZQi0z7VFczRm6Rj43u] = await db.insert(schema.event).values({
  name: 'Wild Kingdoms is published!',
  startDate: '2296-09-08',
  endDate: '2296-09-08',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['5wbZQi0z7VFczRm6Rj43u'] = event_5wbZQi0z7VFczRm6Rj43u!.id

const [event_WCOLqSFLvbILyv43lix79] = await db.insert(schema.event).values({
  name: 'Max & Rowan join Crystalis Cell',
  startDate: '2296-10-11',
  endDate: '2296-10-11',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['WCOLqSFLvbILyv43lix79'] = event_WCOLqSFLvbILyv43lix79!.id

const [event_fJYZsFa8Gem9Qqio1Cenk] = await db.insert(schema.event).values({
  name: 'Pyrro and Ember join Arboria Cell',
  startDate: '2296-10-14',
  endDate: '2296-10-14',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['fJYZsFa8Gem9Qqio1Cenk'] = event_fJYZsFa8Gem9Qqio1Cenk!.id

const [event_R7p91wQcuy4Ru2o5YS7eI] = await db.insert(schema.event).values({
  name: 'Clive joins Arboria Cell',
  startDate: '2296-11-19',
  endDate: '2296-11-19',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['R7p91wQcuy4Ru2o5YS7eI'] = event_R7p91wQcuy4Ru2o5YS7eI!.id

const [event_88zd0LHjAwoAs6Rie3Iwr] = await db.insert(schema.event).values({
  name: 'Daphne joins Arboria Cell',
  startDate: '2296-12-06',
  endDate: '2296-12-06',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['88zd0LHjAwoAs6Rie3Iwr'] = event_88zd0LHjAwoAs6Rie3Iwr!.id

const [event_iUXSAW8JI2QJZNuZuaCRd] = await db.insert(schema.event).values({
  name: 'Dale and Sophie join Arboria Cell',
  startDate: '2297-02-21',
  endDate: '2297-02-21',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['iUXSAW8JI2QJZNuZuaCRd'] = event_iUXSAW8JI2QJZNuZuaCRd!.id

const [event_OeTjiTANj9SMsxuzFo1PZ] = await db.insert(schema.event).values({
  name: 'Penka joins Arboria Cell',
  startDate: '2297-03-11',
  endDate: '2297-03-11',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['OeTjiTANj9SMsxuzFo1PZ'] = event_OeTjiTANj9SMsxuzFo1PZ!.id

const [event_ndODEIpDFkRiUqt06Omvf] = await db.insert(schema.event).values({
  name: 'Max & Rowan are discharged from Crystalis Cell.',
  startDate: '2297-06-19',
  endDate: '2297-06-19',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['ndODEIpDFkRiUqt06Omvf'] = event_ndODEIpDFkRiUqt06Omvf!.id

const [event_FmtYmBbs88HVn6Nwq90Vn] = await db.insert(schema.event).values({
  name: 'Crystalis’ Cell Leader Defects',
  startDate: '2297-10-27',
  endDate: '2297-10-27',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['FmtYmBbs88HVn6Nwq90Vn'] = event_FmtYmBbs88HVn6Nwq90Vn!.id

const [event_c04NSD11RbFEw4Fip1a5m] = await db.insert(schema.event).values({
  name: 'Crystalis’ Cell is attacked.',
  startDate: '2298-06-14',
  endDate: '2298-06-14',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['c04NSD11RbFEw4Fip1a5m'] = event_c04NSD11RbFEw4Fip1a5m!.id

const [event_7G2JsI4iAzCDXY83pGe3d] = await db.insert(schema.event).values({
  name: 'Marco Barley joins Crystalis Cell',
  startDate: '2298-06-14',
  endDate: '2298-06-14',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['7G2JsI4iAzCDXY83pGe3d'] = event_7G2JsI4iAzCDXY83pGe3d!.id

const [event_xYR7X8at06BMT0qGmuWVO] = await db.insert(schema.event).values({
  name: 'Wild Kingdoms becomes national phenomenon!',
  startDate: '2298-12-15',
  endDate: '2298-12-15',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['xYR7X8at06BMT0qGmuWVO'] = event_xYR7X8at06BMT0qGmuWVO!.id

const [event_Mco7vhB4U3zFpIZRXV1QF] = await db.insert(schema.event).values({
  name: 'Elise joins Arboria Cell',
  startDate: '2299-01-16',
  endDate: '2299-01-16',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['Mco7vhB4U3zFpIZRXV1QF'] = event_Mco7vhB4U3zFpIZRXV1QF!.id

const [event_AA1WGlSwM252UKxLXOjes] = await db.insert(schema.event).values({
  name: 'Alicia joins Arboria Cell',
  startDate: '2299-09-17',
  endDate: '2299-09-17',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['AA1WGlSwM252UKxLXOjes'] = event_AA1WGlSwM252UKxLXOjes!.id

const [event_JWZ0TWqK1jew7dzGL9ppZ] = await db.insert(schema.event).values({
  name: 'Naerie defeats Anubis',
  startDate: '2300-03-13',
  endDate: '2300-03-13',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['JWZ0TWqK1jew7dzGL9ppZ'] = event_JWZ0TWqK1jew7dzGL9ppZ!.id

const [event_sFypn5SLFfKWKMlUgpOcI] = await db.insert(schema.event).values({
  name: 'Pyrro saves Ingrium',
  startDate: '2300-07-09',
  endDate: '2300-09-26',
  isCurrentDay: false,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['sFypn5SLFfKWKMlUgpOcI'] = event_sFypn5SLFfKWKMlUgpOcI!.id

const [event_fWFHRlmWfJxGOiybz9vjn] = await db.insert(schema.event).values({
  name: 'CURRENT DAY',
  startDate: '2300-09-25',
  endDate: '2300-09-25',
  isCurrentDay: true,
  updatedAt: new Date().toISOString()
}).returning()
eventMap['fWFHRlmWfJxGOiybz9vjn'] = event_fWFHRlmWfJxGOiybz9vjn!.id

// ── Event Character Assignments ───────────────────────────────
await db.insert(schema.eventCharacter).values([
  { eventId: eventMap['FS3N6XRbIGFoaipoupc5G']!, characterId: charMap['ddfQ6XS7JD2flyaPTOAZn']! },
  { eventId: eventMap['JkCaTq5FsKVlCMRalOSxO']!, characterId: charMap['TXaClCXVrOu1WfuztqP3z']! },
  { eventId: eventMap['JkCaTq5FsKVlCMRalOSxO']!, characterId: charMap['52hgTVzLw4ZG8NyTsLpk1']! },
  { eventId: eventMap['ndODEIpDFkRiUqt06Omvf']!, characterId: charMap['TXaClCXVrOu1WfuztqP3z']! },
  { eventId: eventMap['ndODEIpDFkRiUqt06Omvf']!, characterId: charMap['52hgTVzLw4ZG8NyTsLpk1']! },
  { eventId: eventMap['ndODEIpDFkRiUqt06Omvf']!, characterId: charMap['h4o7ZPmLBemFZmw7Cq1UU']! },
  { eventId: eventMap['Rl2fzA3RXKb0jmSANMWmY']!, characterId: charMap['neyVpwQZIFglDPako23yF']! },
  { eventId: eventMap['Mco7vhB4U3zFpIZRXV1QF']!, characterId: charMap['neyVpwQZIFglDPako23yF']! },
  { eventId: eventMap['FIf4UMbHk6DCNxCe9Yk8g']!, characterId: charMap['neyVpwQZIFglDPako23yF']! },
  { eventId: eventMap['FIf4UMbHk6DCNxCe9Yk8g']!, characterId: charMap['vegMDSeT8VfZslLuFBbfW']! },
  { eventId: eventMap['FIf4UMbHk6DCNxCe9Yk8g']!, characterId: charMap['jYuhNwN2Nz7qw6bKYsKII']! },
  { eventId: eventMap['Ra5d6N7coJ1AOJG2ptdsq']!, characterId: charMap['jYuhNwN2Nz7qw6bKYsKII']! },
  { eventId: eventMap['WCOLqSFLvbILyv43lix79']!, characterId: charMap['52hgTVzLw4ZG8NyTsLpk1']! },
  { eventId: eventMap['WCOLqSFLvbILyv43lix79']!, characterId: charMap['TXaClCXVrOu1WfuztqP3z']! },
  { eventId: eventMap['kvPrxrHMM7S3MEWJGlRdF']!, characterId: charMap['vegMDSeT8VfZslLuFBbfW']! },
  { eventId: eventMap['tIDFxB8UgdWVO1RDmldrl']!, characterId: charMap['h4o7ZPmLBemFZmw7Cq1UU']! },
  { eventId: eventMap['7G2JsI4iAzCDXY83pGe3d']!, characterId: charMap['eYZUxvbJd2ymAB9mEiEhS']! },
  { eventId: eventMap['mlckaU0bi8JNnfVh1EFGb']!, characterId: charMap['9wyZW5xwzEieOOdD5ESm6']! },
  { eventId: eventMap['mlckaU0bi8JNnfVh1EFGb']!, characterId: charMap['fHdFALYp5iFYVn0IFrlSu']! },
  { eventId: eventMap['mlckaU0bi8JNnfVh1EFGb']!, characterId: charMap['bkChrC88denoAJ4rF9fuM']! },
  { eventId: eventMap['1scxVWQ1RDb8n9HBrXwcQ']!, characterId: charMap['TXaClCXVrOu1WfuztqP3z']! },
  { eventId: eventMap['sSU0utwB1X757eMPxeJak']!, characterId: charMap['9wyZW5xwzEieOOdD5ESm6']! },
  { eventId: eventMap['4QLb82PzNE2IZBhJGXQzJ']!, characterId: charMap['uWkBweQYQOQkVuJHiZqcP']! },
  { eventId: eventMap['tYMlQKmBS4l81Z96XFmWW']!, characterId: charMap['h4o7ZPmLBemFZmw7Cq1UU']! },
  { eventId: eventMap['0l9ZVRGZyrL1cwiCjLUgE']!, characterId: charMap['ddfQ6XS7JD2flyaPTOAZn']! },
  { eventId: eventMap['VwNY6HjNEpHV3sua1Vlww']!, characterId: charMap['bkChrC88denoAJ4rF9fuM']! },
  { eventId: eventMap['36BzsUea0N1Vbivfgu8re']!, characterId: charMap['mjboVFq63n8nA4CSP3Ckm']! },
  { eventId: eventMap['alS5IQr4iISi0WFmeY8GG']!, characterId: charMap['fHdFALYp5iFYVn0IFrlSu']! },
  { eventId: eventMap['jAxnRKNxvIOnP6PSgPnLN']!, characterId: charMap['OxcxQ4mWML1fSZwCuO4UW']! },
  { eventId: eventMap['Y9LYhdANz46gHOJSo5nEm']!, characterId: charMap['WZ4wypWVtSBDt5Bfbo8cC']! },
  { eventId: eventMap['mbhocSEBG6aBwucuN1POP']!, characterId: charMap['21QADh2ACBsfX8iz0xrHj']! },
  { eventId: eventMap['VohTCeZln1x3XNu6OQBNj']!, characterId: charMap['gboD3jRnbn2iGTtLsbD3A']! },
  { eventId: eventMap['qXBqDyvavGxFOsWuQkwAf']!, characterId: charMap['hQK1UsvGx1TaxvYk451L3']! },
  { eventId: eventMap['qXBqDyvavGxFOsWuQkwAf']!, characterId: charMap['IXG9ndG8K8EGhzIDjcSgv']! },
  { eventId: eventMap['qgdboKCUImowX6UK2xQzL']!, characterId: charMap['sDvrOQE0MkiBNa5G6Ud8R']! },
  { eventId: eventMap['27t2D9uJc9RMsFzz52IcF']!, characterId: charMap['7uqNNvhCbexeJh0L03aWJ']! },
  { eventId: eventMap['BGPLksjRq3Ezcz87hTkNL']!, characterId: charMap['9S1hIuE13WLrOJcjn2CaX']! },
  { eventId: eventMap['is6JnA0zOvY7r8iyPVsge']!, characterId: charMap['7I52xNDUNHtskjvt8m7te']! },
  { eventId: eventMap['ZMjngvQ0jhnYeSl6AupKC']!, characterId: charMap['NCiV2CyaxnVaYci9DOb5X']! },
  { eventId: eventMap['adFAIsGT24WRYoQN26BGv']!, characterId: charMap['mjboVFq63n8nA4CSP3Ckm']! },
  { eventId: eventMap['adFAIsGT24WRYoQN26BGv']!, characterId: charMap['jYuhNwN2Nz7qw6bKYsKII']! },
  { eventId: eventMap['adFAIsGT24WRYoQN26BGv']!, characterId: charMap['9S1hIuE13WLrOJcjn2CaX']! },
  { eventId: eventMap['adFAIsGT24WRYoQN26BGv']!, characterId: charMap['NCiV2CyaxnVaYci9DOb5X']! },
  { eventId: eventMap['fJYZsFa8Gem9Qqio1Cenk']!, characterId: charMap['IXG9ndG8K8EGhzIDjcSgv']! },
  { eventId: eventMap['fJYZsFa8Gem9Qqio1Cenk']!, characterId: charMap['hQK1UsvGx1TaxvYk451L3']! },
  { eventId: eventMap['OeTjiTANj9SMsxuzFo1PZ']!, characterId: charMap['gboD3jRnbn2iGTtLsbD3A']! },
  { eventId: eventMap['W0nFvJzHUjXosTOzs8e7q']!, characterId: charMap['h4o7ZPmLBemFZmw7Cq1UU']! },
  { eventId: eventMap['y7w4o1qWLLdWzn09HQ6x4']!, characterId: charMap['sDvrOQE0MkiBNa5G6Ud8R']! },
  { eventId: eventMap['wA20hnZOrisXCjecfawRM']!, characterId: charMap['7uqNNvhCbexeJh0L03aWJ']! },
  { eventId: eventMap['R7p91wQcuy4Ru2o5YS7eI']!, characterId: charMap['OxcxQ4mWML1fSZwCuO4UW']! }
])

await db.insert(schema.eventCharacter).values([
  { eventId: eventMap['88zd0LHjAwoAs6Rie3Iwr']!, characterId: charMap['21QADh2ACBsfX8iz0xrHj']! },
  { eventId: eventMap['iUXSAW8JI2QJZNuZuaCRd']!, characterId: charMap['21QADh2ACBsfX8iz0xrHj']! },
  { eventId: eventMap['iUXSAW8JI2QJZNuZuaCRd']!, characterId: charMap['7I52xNDUNHtskjvt8m7te']! },
  { eventId: eventMap['AA1WGlSwM252UKxLXOjes']!, characterId: charMap['vegMDSeT8VfZslLuFBbfW']! },
  { eventId: eventMap['NJX6szE1jmmdT0rNusjk7']!, characterId: charMap['uWkBweQYQOQkVuJHiZqcP']! },
  { eventId: eventMap['NJX6szE1jmmdT0rNusjk7']!, characterId: charMap['s72gFKZ9z4izVRUPbCfWH']! },
  { eventId: eventMap['GnOnAI4jc3CAZkchuCldO']!, characterId: charMap['JRPLIlinobYat89R6d993']! },
  { eventId: eventMap['jcChNMqv6s0FDMz7pTRvv']!, characterId: charMap['JRPLIlinobYat89R6d993']! },
  { eventId: eventMap['jcChNMqv6s0FDMz7pTRvv']!, characterId: charMap['fHdFALYp5iFYVn0IFrlSu']! },
  { eventId: eventMap['PyWUI7QpfpKlH9QOzxqk9']!, characterId: charMap['uWkBweQYQOQkVuJHiZqcP']! },
  { eventId: eventMap['FltEe7VnHJHD51ILTp22P']!, characterId: charMap['ddfQ6XS7JD2flyaPTOAZn']! },
  { eventId: eventMap['FltEe7VnHJHD51ILTp22P']!, characterId: charMap['zxDCcgennrkNaUMLThpNw']! },
  { eventId: eventMap['KvuqwQlUScDaos3Q2QLrO']!, characterId: charMap['A3TFT65ToxxI7ZoIA07Ct']! },
  { eventId: eventMap['nZNbCXS02TH18h0zC2LXf']!, characterId: charMap['uWkBweQYQOQkVuJHiZqcP']! },
  { eventId: eventMap['nZNbCXS02TH18h0zC2LXf']!, characterId: charMap['GjOVa6T8K4sDwR3TG1zPK']! },
  { eventId: eventMap['nZNbCXS02TH18h0zC2LXf']!, characterId: charMap['fHdFALYp5iFYVn0IFrlSu']! },
  { eventId: eventMap['ajBZL32gNht61oVkvNuTk']!, characterId: charMap['DxoUDbFEdGXBVmlKoBIc9']! },
  { eventId: eventMap['DUZ17uhRFi1eT1jr1YlRc']!, characterId: charMap['DxoUDbFEdGXBVmlKoBIc9']! },
  { eventId: eventMap['5wbZQi0z7VFczRm6Rj43u']!, characterId: charMap['DxoUDbFEdGXBVmlKoBIc9']! },
  { eventId: eventMap['NzhRYGANDEZqLhmh90XiO']!, characterId: charMap['9fsgoYp2Hmks2Gy6K3LG8']! },
  { eventId: eventMap['c04NSD11RbFEw4Fip1a5m']!, characterId: charMap['h4o7ZPmLBemFZmw7Cq1UU']! },
  { eventId: eventMap['c04NSD11RbFEw4Fip1a5m']!, characterId: charMap['TXaClCXVrOu1WfuztqP3z']! },
  { eventId: eventMap['c04NSD11RbFEw4Fip1a5m']!, characterId: charMap['52hgTVzLw4ZG8NyTsLpk1']! },
  { eventId: eventMap['c04NSD11RbFEw4Fip1a5m']!, characterId: charMap['crsLU3v2Rwkpg61AJ9DsV']! },
  { eventId: eventMap['tOatY8tITDO537Sy87k1r']!, characterId: charMap['AFCUIu4AvlbgtsQvj8I9E']! },
  { eventId: eventMap['VbfA3AM7klUL9KWNYAA5r']!, characterId: charMap['uWkBweQYQOQkVuJHiZqcP']! },
  { eventId: eventMap['VbfA3AM7klUL9KWNYAA5r']!, characterId: charMap['s72gFKZ9z4izVRUPbCfWH']! },
  { eventId: eventMap['wlm12BDWNa4cZqjbF9y14']!, characterId: charMap['52hgTVzLw4ZG8NyTsLpk1']! },
  { eventId: eventMap['KvO6u1K52EU4XND1MjpEe']!, characterId: charMap['crsLU3v2Rwkpg61AJ9DsV']! },
  { eventId: eventMap['vMjbrmM9Yr4F6rLl8ZRhq']!, characterId: charMap['A3TFT65ToxxI7ZoIA07Ct']! },
  { eventId: eventMap['0AIC9eqyZLEUCLdoGqZPc']!, characterId: charMap['A3TFT65ToxxI7ZoIA07Ct']! }
])

console.log('Seed complete: Knighthood universe loaded.')
await pool.end()
