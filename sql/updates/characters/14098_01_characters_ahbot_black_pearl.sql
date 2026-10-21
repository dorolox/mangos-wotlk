ALTER TABLE character_db_version CHANGE COLUMN required_14097_01_characters_achievement_failed required_14098_01_characters_ahbot_black_pearl bit;

-- Black Pearl (item 7971) has no vendor buy/sell price, causing AHBot to skip it.
-- Set an explicit value and add chance so it appears on the AH.
INSERT INTO ahbot_items (item, value, add_chance, min_amount, max_amount)
VALUES (7971, 50000, 30, 1, 5)
ON DUPLICATE KEY UPDATE value = 50000, add_chance = 30, min_amount = 1, max_amount = 5;
