-- Custom Vendor NPC — sells server-specific custom items (items added separately via npc_vendor)
-- Entry 190002, spawned near the Auction House in all 9 capitals:
--   Alliance : Stormwind, Ironforge, Darnassus, The Exodar
--   Horde    : Orgrimmar, Thunder Bluff, Undercity, Silvermoon City
--   Neutral  : Dalaran (WotLK)
-- Shattrath excluded — no Auction House present.
--
-- !! Coordinates are approximate. Verify and fine-tune in-game. !!
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
(190002, 0,   1, 1,  -8815.0,   650.0,   93.8, 3.14, 120, 120, 0, 0),
-- Ironforge (Map 0) — The Commons, near Auction House
(190002, 0,   1, 1,  -4893.0, -1064.0,  501.9, 1.15, 120, 120, 0, 0),
-- Darnassus (Map 1) — Craftsmen's Terrace, near Auction House
(190002, 1,   1, 1,   9963.0,  2171.0, 1342.0, 4.71, 120, 120, 0, 0),
-- The Exodar (Map 530) — The Vault of Lights, near Auction House
(190002, 530, 1, 1,  -3961.0,-11561.0, -138.0, 1.57, 120, 120, 0, 0),
-- Horde capitals
-- Orgrimmar (Map 1) — Valley of Strength, near Auction House
(190002, 1,   1, 1,   1655.0, -4447.0,   61.7, 3.14, 120, 120, 0, 0),
-- Thunder Bluff (Map 1) — Middle Rise, near Auction House
(190002, 1,   1, 1,  -1271.0,    87.0,  128.0, 0.77, 120, 120, 0, 0),
-- Undercity (Map 0) — The Trade Quarter, near Auction House
(190002, 0,   1, 1,   1652.0,   237.0,  -52.0, 3.14, 120, 120, 0, 0),
-- Silvermoon City (Map 530) — Royal Exchange, near Auction House
(190002, 530, 1, 1,   9484.0, -7484.0,   14.0, 3.14, 120, 120, 0, 0),
-- WotLK neutral capital
-- Dalaran (Map 571) — The Eventide, near Auction House
(190002, 571, 1, 1,   5762.0,   690.0,  641.0, 1.57, 120, 120, 0, 0);

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
