-- Custom Vendor NPC — sells server-specific custom items (items added separately via npc_vendor)
-- Entry 190002, spawned near the Auction House in all 9 capitals:
--   Alliance : Stormwind, Ironforge, Darnassus, The Exodar
--   Horde    : Orgrimmar, Thunder Bluff, Undercity, Silvermoon City
--   Neutral  : Dalaran (WotLK)
-- Shattrath excluded — no Auction House present.
--
-- !! DisplayId1 (19106) is a placeholder — swap to the desired model. !!
-- !! NpcFlags = 128 (VENDOR). Add GOSSIP (|1 = 129) if a greeting text is needed. !!

-- ============================================================
-- Creature template
-- ============================================================
DELETE FROM `creature_template` WHERE `Entry` = 190002;
INSERT INTO `creature_template`
    (`Entry`, `Name`, `SubName`, `DisplayId1`, `DisplayIdProbability1`,
     `Faction`, `Scale`, `CreatureType`, `InhabitType`, `RegenerateStats`,
     `NpcFlags`, `MinLevel`, `MaxLevel`,
     `SpeedWalk`, `SpeedRun`,
     `GossipMenuId`, `ScriptName`)
VALUES
    (190002, 'Special Vendor', 'Rare Goods', 19106, 100,
     35, 1.0, 7, 3, 3,
     128, 80, 80,
     1.0, 1.14286,
     0, '');

-- ============================================================
-- Creature spawns — one per capital, near its Auction House
-- ============================================================
DELETE FROM `creature` WHERE `id` = 190002;
INSERT INTO `creature`
    (`id`, `map`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecsmin`, `spawntimesecsmax`, `spawndist`, `MovementType`)
VALUES
-- Alliance capitals
-- Stormwind City (Map 0) — Trade District, near Auction House
(190002, 0,   1, 1,  -8812.057617,   654.041138,   96.195740, 4.509317, 120, 120, 0, 0),
-- Ironforge (Map 0) — The Commons, near Auction House
(190002, 0,   1, 1,  -4917.367676,  -980.787537,  501.449463, 2.242305, 120, 120, 0, 0),
-- Darnassus (Map 1) — Tradesmen's Terrace, near Auction House
(190002, 1,   1, 1,   9872.599609,  2341.729980, 1321.670044, 3.525560, 120, 120, 0, 0),
-- The Exodar (Map 530) — Seat of the Naaru, near Auction House
(190002, 530, 1, 1,  -3973.518799,-11695.068359, -139.163284, 0.247400, 120, 120, 0, 0),
-- Horde capitals
-- Orgrimmar (Map 1) — Valley of Strength, near Auction House
(190002, 1,   1, 1,   1664.354248, -4430.434082,   17.674257, 1.765528, 120, 120, 0, 0),
-- Thunder Bluff (Map 1) — Middle Rise, near Auction House
(190002, 1,   1, 1,  -1271.000000,    87.000000,  128.000000, 0.770000, 120, 120, 0, 0),
-- Undercity (Map 0) — The Canals, near Auction House
(190002, 0,   1, 1,   1648.170044,   224.173004,  -56.794800, 4.223700, 120, 120, 0, 0),
-- Silvermoon City (Map 530) — The Bazaar, near Auction House
(190002, 530, 1, 1,   9677.928711, -7136.337891,   14.324089, 0.003639, 120, 120, 0, 0),
-- WotLK neutral capital
-- Dalaran (Map 571) — Runeweaver Square, near Auction House
(190002, 571, 1, 1,   5804.700195,   633.228027,  647.630005, 0.174533, 120, 120, 0, 0);

-- ============================================================
-- Vendor items — populated when custom items are created
-- Schema reminder:
--   INSERT INTO `npc_vendor`
--       (`entry`, `item`, `maxcount`, `incrtime`, `slot`, `ExtendedCost`, `condition_id`)
--   VALUES
--       (190002, <item_entry>, 0, 0, <slot>, 0, 0);
-- maxcount 0  = unlimited stock
-- incrtime 0  = no restock timer needed
-- ExtendedCost 0 = gold-only price defined on the item itself
-- ============================================================
