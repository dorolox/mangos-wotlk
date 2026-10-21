-- Death Knight start: default spells, runeforging at level 10, classic starting zones, hearthstone

-- -- Death Knights start in their race's classic starting zone (like warriors, paladin for blood elves)
-- -- with their Acherus spells, can runeforge from level 10 and get a hearthstone.

-- Applied by hand on OVH before 2026-10-21, scripted here so it survives a world DB reinstall.
-- Safe to run several times. The spell_template part must be re-run after every DBC reload
-- (sql/base/dbc/original_data + cmangos_fixes), which recreates spell_template.

-- 1. Default spells for every DK race
DELETE FROM `playercreateinfo_spell` WHERE `class` = 6 AND `Spell` IN (53341, 53343, 49142, 48263, 53428, 51721, 48778, 50977, 46584);
INSERT INTO `playercreateinfo_spell` (`race`, `class`, `Spell`, `Note`) VALUES
-- Human
(1, 6, 53341, 'Rune of Cinderglacier'), (1, 6, 53343, 'Rune of Razorice'), (1, 6, 49142, 'Frozen Rune Weapon'), (1, 6, 48263, 'Frost Presence'), (1, 6, 53428, 'Runeforging'), (1, 6, 51721, 'Dominion Over Acherus'), (1, 6, 48778, 'Acherus Deathcharger'), (1, 6, 50977, 'Death Gate'), (1, 6, 46584, 'Raise Dead'),
-- Orc
(2, 6, 53341, 'Rune of Cinderglacier'), (2, 6, 53343, 'Rune of Razorice'), (2, 6, 49142, 'Frozen Rune Weapon'), (2, 6, 48263, 'Frost Presence'), (2, 6, 53428, 'Runeforging'), (2, 6, 51721, 'Dominion Over Acherus'), (2, 6, 48778, 'Acherus Deathcharger'), (2, 6, 50977, 'Death Gate'), (2, 6, 46584, 'Raise Dead'),
-- Dwarf
(3, 6, 53341, 'Rune of Cinderglacier'), (3, 6, 53343, 'Rune of Razorice'), (3, 6, 49142, 'Frozen Rune Weapon'), (3, 6, 48263, 'Frost Presence'), (3, 6, 53428, 'Runeforging'), (3, 6, 51721, 'Dominion Over Acherus'), (3, 6, 48778, 'Acherus Deathcharger'), (3, 6, 50977, 'Death Gate'), (3, 6, 46584, 'Raise Dead'),
-- Night Elf
(4, 6, 53341, 'Rune of Cinderglacier'), (4, 6, 53343, 'Rune of Razorice'), (4, 6, 49142, 'Frozen Rune Weapon'), (4, 6, 48263, 'Frost Presence'), (4, 6, 53428, 'Runeforging'), (4, 6, 51721, 'Dominion Over Acherus'), (4, 6, 48778, 'Acherus Deathcharger'), (4, 6, 50977, 'Death Gate'), (4, 6, 46584, 'Raise Dead'),
-- Undead
(5, 6, 53341, 'Rune of Cinderglacier'), (5, 6, 53343, 'Rune of Razorice'), (5, 6, 49142, 'Frozen Rune Weapon'), (5, 6, 48263, 'Frost Presence'), (5, 6, 53428, 'Runeforging'), (5, 6, 51721, 'Dominion Over Acherus'), (5, 6, 48778, 'Acherus Deathcharger'), (5, 6, 50977, 'Death Gate'), (5, 6, 46584, 'Raise Dead'),
-- Tauren
(6, 6, 53341, 'Rune of Cinderglacier'), (6, 6, 53343, 'Rune of Razorice'), (6, 6, 49142, 'Frozen Rune Weapon'), (6, 6, 48263, 'Frost Presence'), (6, 6, 53428, 'Runeforging'), (6, 6, 51721, 'Dominion Over Acherus'), (6, 6, 48778, 'Acherus Deathcharger'), (6, 6, 50977, 'Death Gate'), (6, 6, 46584, 'Raise Dead'),
-- Gnome
(7, 6, 53341, 'Rune of Cinderglacier'), (7, 6, 53343, 'Rune of Razorice'), (7, 6, 49142, 'Frozen Rune Weapon'), (7, 6, 48263, 'Frost Presence'), (7, 6, 53428, 'Runeforging'), (7, 6, 51721, 'Dominion Over Acherus'), (7, 6, 48778, 'Acherus Deathcharger'), (7, 6, 50977, 'Death Gate'), (7, 6, 46584, 'Raise Dead'),
-- Troll
(8, 6, 53341, 'Rune of Cinderglacier'), (8, 6, 53343, 'Rune of Razorice'), (8, 6, 49142, 'Frozen Rune Weapon'), (8, 6, 48263, 'Frost Presence'), (8, 6, 53428, 'Runeforging'), (8, 6, 51721, 'Dominion Over Acherus'), (8, 6, 48778, 'Acherus Deathcharger'), (8, 6, 50977, 'Death Gate'), (8, 6, 46584, 'Raise Dead'),
-- Blood Elf
(10, 6, 53341, 'Rune of Cinderglacier'), (10, 6, 53343, 'Rune of Razorice'), (10, 6, 49142, 'Frozen Rune Weapon'), (10, 6, 48263, 'Frost Presence'), (10, 6, 53428, 'Runeforging'), (10, 6, 51721, 'Dominion Over Acherus'), (10, 6, 48778, 'Acherus Deathcharger'), (10, 6, 50977, 'Death Gate'), (10, 6, 46584, 'Raise Dead'),
-- Draenei
(11, 6, 53341, 'Rune of Cinderglacier'), (11, 6, 53343, 'Rune of Razorice'), (11, 6, 49142, 'Frozen Rune Weapon'), (11, 6, 48263, 'Frost Presence'), (11, 6, 53428, 'Runeforging'), (11, 6, 51721, 'Dominion Over Acherus'), (11, 6, 48778, 'Acherus Deathcharger'), (11, 6, 50977, 'Death Gate'), (11, 6, 46584, 'Raise Dead');

-- 2. Runeforging and the two starting runes usable from level 10
UPDATE `spell_template` SET `BaseLevel` = 10, `SpellLevel` = 0 WHERE `Id` IN (53341, 53343, 53428);

-- 3. Starting position copied from the warrior of the same race (races 1-8, 11)
UPDATE `playercreateinfo` dk
JOIN `playercreateinfo` ref ON dk.race = ref.race AND ref.class = 1
SET dk.map = ref.map, dk.zone = ref.zone, dk.position_x = ref.position_x, dk.position_y = ref.position_y,
    dk.position_z = ref.position_z, dk.orientation = ref.orientation
WHERE dk.class = 6 AND dk.race IN (1, 2, 3, 4, 5, 6, 7, 8, 11);

-- Blood elves have no warrior in WotLK: use the paladin
UPDATE `playercreateinfo` dk
JOIN `playercreateinfo` ref ON dk.race = ref.race AND ref.class = 2
SET dk.map = ref.map, dk.zone = ref.zone, dk.position_x = ref.position_x, dk.position_y = ref.position_y,
    dk.position_z = ref.position_z, dk.orientation = ref.orientation
WHERE dk.class = 6 AND dk.race = 10;

-- 4. Hearthstone (6948). playercreateinfo_item has no primary key: delete first to avoid duplicates
DELETE FROM `playercreateinfo_item` WHERE `class` = 6 AND `itemid` = 6948;
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`) VALUES
(1, 6, 6948, 1),
(2, 6, 6948, 1),
(3, 6, 6948, 1),
(4, 6, 6948, 1),
(5, 6, 6948, 1),
(6, 6, 6948, 1),
(7, 6, 6948, 1),
(8, 6, 6948, 1),
(10, 6, 6948, 1),
(11, 6, 6948, 1);
