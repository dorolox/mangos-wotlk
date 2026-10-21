-- Scrolls of Enhancement -- upgrade the gear of all bots in the caster's group
-- that fall within a specific level range, without changing their level or spells.
-- Equivalent to ".bot upgrade" but scoped by expansion level band.
-- Only affects AI bots (not real players).
--
-- i90003 -- Scroll of Enhancement: Azeroth  (bots level  1-60) --  50 gold
-- i90004 -- Scroll of Enhancement: Outland  (bots level  1-70) -- 100 gold
-- i90005 -- Scroll of Enhancement: Northrend(bots level  1-80) -- 150 gold
--
-- Requires server built with ENABLE_PLAYERBOTS.
-- Scripts: item_scroll_of_enhancement_azeroth/outland/northrend (item_scripts.cpp)
--
-- spellid_1 uses our own custom spell IDs (90003/90004/90005).
-- These exist in the server's spell_template AND in the client's Spell.dbc
-- after running contrib/client_tools/patch_custom_spells.py.

-- ============================================================
-- Server-side trigger spells (IsServerSide=1)
-- Also added to client Spell.dbc via patch_custom_spells.py
-- ============================================================
DELETE FROM `spell_template` WHERE `Id` IN (90003, 90004, 90005);
INSERT INTO `spell_template` (`Id`, `Effect1`, `EffectImplicitTargetA1`, `IsServerSide`, `SpellName`)
VALUES
(90003, 3, 1, 1, 'Scroll of Enhancement: Azeroth - upgrade gear of group bots lv 1-60'),
(90004, 3, 1, 1, 'Scroll of Enhancement: Outland - upgrade gear of group bots lv 1-70'),
(90005, 3, 1, 1, 'Scroll of Enhancement: Northrend - upgrade gear of group bots lv 1-80');

-- ============================================================
-- Item templates
-- class 0 = Consumable, subclass 3 = Other
-- Quality 2 = Uncommon (green)
-- stackable 5, spellcharges_1 -1 = consumed on use
-- ============================================================
DELETE FROM `item_template` WHERE `entry` IN (90003, 90004, 90005);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `unk0`, `name`, `displayid`,
     `Quality`, `BuyCount`, `BuyPrice`, `SellPrice`,
     `AllowableClass`, `AllowableRace`,
     `stackable`,
     `spellid_1`, `spelltrigger_1`, `spellcharges_1`,
     `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
     `bonding`, `description`, `ScriptName`)
VALUES
-- 50 gold
(90003, 0, 3, -1, 'Scroll of Enhancement: Azeroth', 3331,
 2, 1, 500000, 125000,
 -1, -1,
 5,
 90003, 0, -1,
 -1, 0, -1,
 0,
 'Upgrades the gear of all bots (level 1-60) in your group to better suit their current level.',
 'item_scroll_of_enhancement_azeroth'),
-- 100 gold
(90004, 0, 3, -1, 'Scroll of Enhancement: Outland', 3331,
 2, 1, 1000000, 250000,
 -1, -1,
 5,
 90004, 0, -1,
 -1, 0, -1,
 0,
 'Upgrades the gear of all bots (level 1-70) in your group to better suit their current level.',
 'item_scroll_of_enhancement_outland'),
-- 150 gold
(90005, 0, 3, -1, 'Scroll of Enhancement: Northrend', 3331,
 2, 1, 1500000, 375000,
 -1, -1,
 5,
 90005, 0, -1,
 -1, 0, -1,
 0,
 'Upgrades the gear of all bots (level 1-80) in your group to better suit their current level.',
 'item_scroll_of_enhancement_northrend');

-- ============================================================
-- Add to custom vendor (entry 190002), slots 2-4
-- ============================================================
DELETE FROM `npc_vendor` WHERE `entry` = 190002 AND `item` IN (90003, 90004, 90005);
INSERT INTO `npc_vendor` (`entry`, `item`, `maxcount`, `incrtime`, `slot`, `ExtendedCost`, `condition_id`)
VALUES
    (190002, 90003, 0, 0, 2, 0, 0),
    (190002, 90004, 0, 0, 3, 0, 0),
    (190002, 90005, 0, 0, 4, 0, 0);
