-- Adds a free-teleport gossip NPC in each racial capital (Alliance & Horde)

-- -- Inserts creature_template entry 190001 (Capital City Teleporter),
-- -- npc_text 190001, gossip_menu 60001, and 8 creature spawns
-- -- (one per capital city). Safe to re-run: DELETEs before INSERTs.
-- -- DisplayId1 (19106) can be changed to any valid creature display ID.
-- -- Spawn coordinates are approximate city-center landmarks.

-- ============================================================
-- NPC greeting text
-- ============================================================
DELETE FROM `npc_text` WHERE `ID` = 190001;
INSERT INTO `npc_text` (`ID`, `text0_0`, `prob0`) VALUES
(190001, 'Greetings, $N. Where would you like to travel today?', 1);

-- ============================================================
-- Gossip menu (ties the NPC to its greeting text)
-- ============================================================
DELETE FROM `gossip_menu` WHERE `entry` = 60001;
INSERT INTO `gossip_menu` (`entry`, `text_id`) VALUES
(60001, 190001);

-- ============================================================
-- Creature template
-- One entry serves all 8 capitals via the same ScriptName.
-- Faction 35 = Friendly (visible and interactive to both factions).
-- NpcFlags 1 = UNIT_NPC_FLAG_GOSSIP.
-- CreatureType 7 = Humanoid. InhabitType 3 = ground.
-- Level 80, no combat stats needed.
-- ============================================================
DELETE FROM `creature_template` WHERE `Entry` = 190001;
INSERT INTO `creature_template`
    (`Entry`, `Name`, `SubName`, `DisplayId1`, `DisplayIdProbability1`,
     `Faction`, `Scale`, `CreatureType`, `InhabitType`, `RegenerateStats`,
     `NpcFlags`, `MinLevel`, `MaxLevel`,
     `SpeedWalk`, `SpeedRun`,
     `GossipMenuId`, `ScriptName`)
VALUES
    (190001, 'Capital City Teleporter', 'Arcane Traveler', 19106, 100,
     35, 1.0, 7, 3, 3,
     1, 80, 80,
     1.0, 1.14286,
     60001, 'npc_capital_teleporter');

-- ============================================================
-- Creature spawns (one per capital, spawnMask 1 = always active)
-- Coordinates are approximate city center landmarks.
-- ============================================================
DELETE FROM `creature` WHERE `id` = 190001;

INSERT INTO `creature`
    (`id`, `map`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecsmin`, `spawntimesecsmax`, `spawndist`, `MovementType`)
VALUES
-- Alliance capitals
-- Stormwind City (Map 0) - Trade District, near the fountain
(190001, 0, 1, 1,  -8825.0,   626.0,   94.0, 3.14, 120, 120, 0, 0),
-- Ironforge (Map 0) - The Commons, near the tram entrance
(190001, 0, 1, 1,  -4841.0, -1045.0,  502.0, 1.15, 120, 120, 0, 0),
-- Darnassus (Map 1) - near the bank
(190001, 1, 1, 1,   9951.6,  2280.9, 1341.4, 1.49, 120, 120, 0, 0),
-- The Exodar (Map 530) - Crystal Hall
(190001, 530, 1, 1, -3961.6,-11653.6, -137.7, 1.02, 120, 120, 0, 0),
-- Horde capitals
-- Orgrimmar (Map 1) - Valley of Strength, near the bank
(190001, 1, 1, 1,   1669.0, -4339.0,   62.0, 3.14, 120, 120, 0, 0),
-- Thunder Bluff (Map 1) - High Rise
(190001, 1, 1, 1,  -1270.0,    72.0,  128.5, 0.77, 120, 120, 0, 0),
-- Undercity (Map 0) - The Trade Quarter
(190001, 0, 1, 1,   1574.0,   239.0,  -52.0, 3.14, 120, 120, 0, 0),
-- Silvermoon City (Map 530) - Royal Exchange
(190001, 530, 1, 1,  9484.0, -7484.0,   14.0, 3.14, 120, 120, 0, 0);
