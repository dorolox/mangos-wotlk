-- Give the Totem of the Earthen Ring (46978) to every new shaman

-- -- Orc, Tauren, Troll and Draenei shamans start with the Totem of the Earthen Ring.

-- Applied by hand on OVH before 2026-10-21, scripted here so it survives a world DB reinstall.
-- Safe to run several times. playercreateinfo_item has no primary key: delete first to avoid duplicates.
DELETE FROM `playercreateinfo_item` WHERE `class` = 7 AND `itemid` = 46978;
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`) VALUES
(2, 7, 46978, 1),  -- Orc
(6, 7, 46978, 1),  -- Tauren
(8, 7, 46978, 1),  -- Troll
(11, 7, 46978, 1); -- Draenei
