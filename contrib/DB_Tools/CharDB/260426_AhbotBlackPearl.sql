-- Add Black Pearl (item 7971) to the AHBot item list

-- -- Black Pearl has no vendor buy/sell price, causing AHBot to skip it.
-- -- Sets an explicit value and add chance so it appears on the AH.

-- Replaces sql/updates/characters/14098_01_characters_ahbot_black_pearl.sql, which also renamed
-- the character_db_version column to 14098 while the core still requires 14097 (mangosd would
-- refuse to start). Safe to run several times.
INSERT INTO ahbot_items (item, value, add_chance, min_amount, max_amount)
VALUES (7971, 50000, 30, 1, 5)
ON DUPLICATE KEY UPDATE value = 50000, add_chance = 30, min_amount = 1, max_amount = 5;
