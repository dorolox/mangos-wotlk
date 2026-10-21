-- Reduce LFG dungeon deserter (71041) and dungeon cooldown (71328) durations to 1 minute
-- Default: Dungeon Deserter = 15 min (DurationIndex 30), Dungeon Cooldown = 30 min (DurationIndex 347)
-- DurationIndex 39 = 60000ms = 1 minute
UPDATE `spell_template` SET `DurationIndex` = 39 WHERE `id` IN (71041, 71328);
