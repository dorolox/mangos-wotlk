# Custom Feature: Level Sync

Inspired by Final Fantasy XIV's level sync system. Allows a player to
temporarily scale down their effective level to match the lowest-level member
of their party, enabling mixed-level groups to play together meaningfully.

---

## Player-facing behaviour

- `.sync on` — activates sync. Captures the **current lowest level** in the
  party at that instant and stores it as the player's sync level.
- `.sync off` — deactivates sync and restores full stats.
- Party changes (join / leave) have **no automatic effect** on an active sync.
  The player must re-run `.sync on` to re-evaluate the new lowest level.
- If the **party is fully disbanded**, sync is automatically deactivated.
- Sync state does not persist across relog (deactivates on logout/disconnect).
- Sync works in all contexts including BG, Arena, and world PvP — same as in
  dungeons.

---

## What scales

Everything is applied as a **single global ratio** on the player's already-
computed totals. No per-item or per-spell inspection.

| System | Behaviour |
|---|---|
| Max HP | Scaled by ratio |
| Max mana / energy / rage cap | Scaled by ratio |
| Attack power (melee & ranged) | Scaled by ratio |
| Spell power | Scaled by ratio |
| Armor | Scaled by ratio |
| Resistances | Scaled by ratio |
| Outgoing damage | Scaled by ratio (damage done modifier) |
| Incoming healing | Scaled by ratio (healing done modifier) |
| XP gain | Calculated using sync level instead of real level |
| Quest grey/green/yellow colour | Evaluated against sync level |

## What does NOT scale / change

| System | Reason |
|---|---|
| Spells & abilities available | Not touched — player keeps everything |
| Per-item stats | Not inspected individually |
| Skill caps | Left at real level to avoid breaking professions |
| Item level requirements | Left at real level |
| Movement speed | Not affected |
| PvP power / resilience | Scaled by ratio like all other stats |

---

## Scaling ratio

```
ratio = syncLevel / realLevel
```

Applied as a flat multiplier to the relevant totals after normal stat
computation. For HP/mana the current value is clamped to the new max on
activation.

A simple linear ratio is the starting point. If it turns out to feel wrong
(e.g. a level 80 synced to 70 is still far too strong), a power curve can be
introduced:

```
ratio = (syncLevel / realLevel) ^ k      -- k > 1 makes scaling more aggressive
```

---

## Sync rules summary

| Event | Effect on sync |
|---|---|
| `.sync on` in a party | Activates, snapshots current lowest party level |
| `.sync on` solo | No effect (or optional: sync to own level = no-op) |
| Party member joins | No effect |
| Party member leaves | No effect |
| Party fully disbanded | Sync deactivated automatically |
| Player logs out | Sync deactivated |
| Player enters BG / Arena | No effect — sync remains active |
| `.sync on` or `.sync off` while in combat | Blocked, error message returned |
| `.sync off` out of combat | Sync deactivated manually |

---

## Implementation plan (v1 scope)

### 1. Player state (`src/game/Entities/Player.h` / `Player.cpp`)

- Add `uint32 m_syncLevel` (0 = inactive).
- Add helpers:
  - `bool IsSynced() const`
  - `uint32 GetSyncLevel() const`
  - `void SetSync(uint32 level)` — sets level, triggers stat recalc, clamps HP/mana
  - `void ClearSync()` — sets to 0, triggers stat recalc
- Do **not** modify `GetLevel()` — add `GetEffectiveLevel()` that returns
  `m_syncLevel` when active, `GetLevel()` otherwise.

### 2. Stat scaling hooks

Inject the ratio multiplier at the **end** of each update function, after
normal computation:

- `Player::UpdateMaxHealth()`
- `Player::UpdateMaxPower()` (covers mana, energy, etc.)
- `Player::UpdateAttackPowerAndDamage()`
- `Player::UpdateSpellDamageAndHealingBonus()`
- `Player::UpdateArmor()`
- `Player::UpdateResistances()`

Pattern inside each function:
```cpp
// ... existing calculation ...
if (IsSynced())
{
    float ratio = float(GetSyncLevel()) / float(GetLevel());
    SetStat / SetMaxHealth / etc. *= ratio;
}
```

### 3. Damage / healing output modifiers

Rather than modifying the base stats alone, also apply the ratio as a
`SPELL_AURA_MOD_DAMAGE_PERCENT_DONE` and `SPELL_AURA_MOD_HEALING_DONE_PERCENT`
modifier so that all damage sources (spells, melee, ranged) are covered
uniformly without needing to touch each damage-dealing code path.

This can be implemented as a synthetic internal aura applied/removed by
`SetSync` / `ClearSync`.

### 4. XP gain (`Player::GiveXP`)

Replace the level parameter passed to the XP formula with `GetEffectiveLevel()`
so XP is calculated as if the player were the sync level.

### 5. Quest colour / grey check

Find the level comparison used for quest difficulty colouring (likely in
`Player::GetLevelDiff` or equivalent) and replace with `GetEffectiveLevel()`.

### 6. `.sync` chat command

Add to the existing GM/player command system (`src/game/Chat/`):

```
.sync on   — calls SetSync(lowest party member level)
.sync off  — calls ClearSync()
```

Validation:
- Player must be in a party for `.sync on`
- Blocked if player is in combat (both `.sync on` and `.sync off`) — checked
  server-side via `player->IsInCombat()`, same pattern as talent respec/logout
- Print current sync level to player on activation

### 7. Party disband hook

In the group-disband / player-leave-group handler, iterate affected players
and call `ClearSync()` on any who are synced and now have no group.

### 8. Logout / disconnect

Call `ClearSync()` in `Player::SaveToDB()` or the logout handler to avoid
persisting sync state.

---

## Files likely touched

| File | Change |
|---|---|
| `src/game/Entities/Player.h` | New fields and helpers |
| `src/game/Entities/Player.cpp` | Stat hooks, GiveXP, logout |
| `src/game/Entities/Unit.cpp` | `GetEffectiveLevel()` usage in combat formulas |
| `src/game/Chat/Level2.cpp` (or similar) | `.sync` command handler |
| `src/game/Groups/Group.cpp` | Disband hook |

---

## LFG dungeon access for synced players

A synced level-80 player cannot queue for low-level dungeons through the
standard LFG tool because the client greys them out based on the player's
**real** level read from `LFGDungeons.dbc`. Two changes are required.

### Client-side — patch LFGDungeons.dbc

Tool: **WDBX Editor** (free, open source, handles WoTLK DBCs natively).

Steps:
1. Extract `LFGDungeons.dbc` from the client MPQ files.
2. Open in WDBX Editor.
3. Filter to dungeon-type entries only (leave raid entries untouched).
4. Bulk-set the `maxlevel` column to **80** for all selected rows.
   Keep `minlevel` unchanged — players still need the minimum level to queue.
5. Save and distribute via a custom patch MPQ (e.g. `patch-4.MPQ`) or as a
   loose file in the client `Data/` override folder.

Effect: all dungeons become visible and queueable in the LFG tool for any
player who meets the `minlevel`. This also automatically includes those
dungeons in the **random daily dungeon** pool for eligible players.

### Server-side — update LFG data in the database

CMaNGOS mirrors LFG dungeon data in the database (introduced in
`sql/updates/mangos/14045_01_mangos_lfg_data.sql`). The exact table and
column names need to be confirmed in the codebase, but the intent is:

```sql
-- Confirm table/column names before running
UPDATE `lfg_dungeon_template` SET `maxlevel` = 80 WHERE `type` = 1;
```

Also use `GetEffectiveLevel()` (the sync-aware helper) instead of `GetLevel()`
in the server-side LFG eligibility check so a synced player is validated
against their sync level, not their real level.

**TODO before implementing:**
- Confirm LFG table and column names in `src/game/LFG/` and related DB schema
- Identify the exact eligibility check function to patch with `GetEffectiveLevel()`
- Write and add the SQL UPDATE to `contrib/DB_Tools/WorldDB/`

---

## Known limitations / deferred work

- Gear stats are **not** individually scaled; a synced level-80 in full epic
  gear will still outperform a genuine low-level player in raw throughput.
  The ratio softens this but does not eliminate it.
- Abilities above sync level remain usable.
- No visual indicator to other players that a character is synced (could add
  a buff icon via a cosmetic aura later).
- Dungeon/raid lockout and loot eligibility are unaffected by sync level.
