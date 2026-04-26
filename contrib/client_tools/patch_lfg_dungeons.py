"""
patch_lfg_dungeons.py
Patches LFGDungeons.dbc (WoTLK 3.3.5a, build 12340) so that all dungeon
entries (regular, heroic, random) have maxlevel = 80, allowing synced
players to queue for any dungeon they meet the minlevel for.
Raid entries (TypeID 2) are left untouched.

Usage:
    python patch_lfg_dungeons.py <path/to/LFGDungeons.dbc>

The file is modified in-place. A .bak backup is created automatically.
"""

import struct
import sys
import shutil
from pathlib import Path

# DBC field indices (each field is 4 bytes, little-endian uint32).
# Two versions exist in the client MPQ files:
#   24-field version — TBC era, found in expansion.MPQ / locale MPQs (DO NOT USE)
#   49-field version — WoTLK, found in lichking.MPQ               (USE THIS ONE)
# Always extract from lichking.MPQ to get the correct file.
#
# 49-field layout (src/game/Server/DBCStructure.h LFGDungeonEntry):
#   0        = ID
#   1-16     = Name[16]  (string offsets)
#   17       = Name_lang_mask
#   18       = MinLevel
#   19       = MaxLevel   ← patched here
#   20       = TargetLevel
#   21       = TargetLevelMin
#   22       = TargetLevelMax
#   23       = MapID
#   24       = Difficulty
#   25       = Flags
#   26       = TypeID     ← filtered here
#   27       = Faction
#   28       = TextureFilename (string offset)
#   29       = ExpansionLevel
#   30       = OrderIndex
#   31       = GroupID
#   32-47    = Description[16] (string offsets)
#   48       = Description_lang_mask
FIELD_MAX_LEVEL = 19   # uint32 MaxLevel
FIELD_TYPE_ID   = 26   # uint32 TypeID

# TypeID values from src/game/LFG/LFGDefines.h
# 1 = DUNGEON, 5 = HEROIC_DUNGEON, 6 = RANDOM_DUNGEON
# 2 = RAID (excluded)
DUNGEON_TYPES = {1, 5, 6}

NEW_MAX_LEVEL = 80
EXPECTED_FIELD_COUNT = 49
EXPECTED_RECORD_SIZE = EXPECTED_FIELD_COUNT * 4   # 196 bytes


def patch(filepath: str) -> None:
    path = Path(filepath)
    if not path.exists():
        print(f"ERROR: file not found: {filepath}")
        sys.exit(1)

    # Backup
    backup = path.with_suffix(".dbc.bak")
    shutil.copy2(path, backup)
    print(f"Backup written to {backup}")

    data = bytearray(path.read_bytes())

    # --- Parse DBC header (20 bytes) ---
    if data[:4] != b"WDBC":
        print("ERROR: not a WDBC file (wrong magic bytes)")
        sys.exit(1)

    record_count, field_count, record_size, _string_block_size = struct.unpack_from("<4I", data, 4)
    print(f"Records: {record_count}  Fields: {field_count}  Record size: {record_size} bytes")

    if field_count != EXPECTED_FIELD_COUNT or record_size != EXPECTED_RECORD_SIZE:
        print(
            f"ERROR: unexpected layout — expected {EXPECTED_FIELD_COUNT} fields / "
            f"{EXPECTED_RECORD_SIZE} bytes per record.\n"
            f"       Got {field_count} fields / {record_size} bytes.\n"
            "       This DBC may be from a different game version."
        )
        sys.exit(1)

    HEADER = 20
    patched = 0

    for i in range(record_count):
        base = HEADER + i * record_size
        type_id = struct.unpack_from("<I", data, base + FIELD_TYPE_ID * 4)[0]

        if type_id in DUNGEON_TYPES:
            struct.pack_into("<I", data, base + FIELD_MAX_LEVEL * 4, NEW_MAX_LEVEL)
            patched += 1

    path.write_bytes(data)
    print(f"Patched {patched} entries (maxlevel → {NEW_MAX_LEVEL}).")
    print("Done — place the modified DBC in a patch-4.MPQ as described in the procedure.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python patch_lfg_dungeons.py <path/to/LFGDungeons.dbc>")
        sys.exit(1)
    patch(sys.argv[1])
