-- Add a default graveyard (926) for zone 0 and zone 3479 on map 530

-- -- Bots dying in an area without graveyard link (zone 0 on Outland map 530) sometimes caused crashes.
-- -- Links graveyard 926 to zone 0 and zone 3479 for both factions.

-- Applied by hand on OVH before 2026-10-21, scripted here so it survives a world DB reinstall.
-- Safe to run several times (primary key: id, ghost_loc, link_kind).
INSERT IGNORE INTO game_graveyard_zone (id, ghost_loc, link_kind, faction) VALUES
(926, 0, 0, 0),
(926, 3479, 0, 0);
