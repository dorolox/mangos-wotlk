-- Scroll of Mentorship -- reinitializes all bot members in the user's party/sub-group
-- to the caster's current level (same logic as ".bot init" but uses the
-- player's own level instead of the master's).
-- In a raid, only bots in the caster's sub-group (5-man) are affected.
-- Sold by the custom vendor (entry 190002) for 20 gold.
--
-- Scroll of Mentorship (Raid) -- same effect but covers the entire raid.
-- Sold by the custom vendor (entry 190002) for 100 gold.
--
-- Requires server built with ENABLE_PLAYERBOTS.
-- Scripts: item_scroll_of_mentorship / item_scroll_of_mentorship_raid (item_scripts.cpp)
--
-- spellid_1 uses our own custom spell IDs (90001/90002).
-- These exist in the server's spell_template AND in the client's Spell.dbc
-- after running contrib/client_tools/patch_custom_spells.py.

-- ============================================================
-- Server-side trigger spells (IsServerSide=1)
-- Also added to client Spell.dbc via patch_custom_spells.py
-- ============================================================
DELETE FROM `spell_template` WHERE `Id` IN (90001, 90002);
INSERT INTO `spell_template` (`Id`, `Effect1`, `EffectImplicitTargetA1`, `IsServerSide`, `SpellName`)
VALUES
(90001, 3, 1, 1, 'Scroll of Mentorship - reinit group bots to caster level'),
(90002, 3, 1, 1, 'Scroll of Mentorship (Raid) - reinit all raid bots to caster level');

-- ============================================================
-- Item template (party scroll)
-- class 0 = Consumable, subclass 3 = Other
-- Quality 2 = Uncommon (green)
-- BuyPrice 200000 = 20 gold (in copper). SellPrice = 25% of that.
-- stackable 5, spellcharges_1 -1 = single-use (item destroyed on use)
-- ============================================================
DELETE FROM `item_template` WHERE `entry` IN (90001, 90002);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `unk0`, `name`, `displayid`,
     `Quality`, `BuyCount`, `BuyPrice`, `SellPrice`,
     `AllowableClass`, `AllowableRace`,
     `stackable`,
     `spellid_1`, `spelltrigger_1`, `spellcharges_1`,
     `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
     `bonding`, `description`, `ScriptName`)
VALUES
    (90001, 0, 3, -1, 'Scroll of Mentorship', 3331,
     2, 1, 200000, 50000,
     -1, -1,
     5,
     90001, 0, -1,
     -1, 0, -1,
     0,
     'Reinitializes all bots in your party, gearing and leveling them to match your current level.',
     'item_scroll_of_mentorship'),
    (90002, 0, 3, -1, 'Scroll of Mentorship (Raid)', 3331,
     2, 1, 1000000, 250000,
     -1, -1,
     3,
     90002, 0, -1,
     -1, 0, -1,
     0,
     'Reinitializes all bots in your raid, gearing and leveling them to match your current level.',
     'item_scroll_of_mentorship_raid');

-- ============================================================
-- Add both scrolls to custom vendor (entry 190002)
-- slot 0/1, unlimited stock, gold-only price
-- ============================================================
DELETE FROM `npc_vendor` WHERE `entry` = 190002 AND `item` IN (90001, 90002);
INSERT INTO `npc_vendor` (`entry`, `item`, `maxcount`, `incrtime`, `slot`, `ExtendedCost`, `condition_id`)
VALUES
    (190002, 90001, 0, 0, 0, 0, 0),
    (190002, 90002, 0, 0, 1, 0, 0);
