# Custom Feature: Level Sync

Inspired by Final Fantasy XIV's level sync system. Allows a player to
temporarily scale down their effective level to match the lowest-level member
of their party, enabling mixed-level groups to play together meaningfully.

---

## Player-facing behaviour

- `.sync on` — activates sync. Captures the **current lowest level** in the
  party at that instant and stores it as the player's sync level.
- `.sync off` — deactivates sync and restores full stats.
- `.sync show` — displays current sync state and level without changing anything.
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
| Outgoing damage | Scaled via spell bonus functions |
| Incoming healing | Scaled via healing bonus functions |
| XP gain | Calculated using sync level instead of real level |
| Quest grey/green/yellow colour | Client-side only — not changed (see note below) |

## What does NOT scale / change

| System | Reason |
|---|---|
| Spells & abilities available | Not touched — player keeps everything |
| Per-item stats | Not inspected individually |
| Skill caps | Left at real level to avoid breaking professions |
| Item level requirements | Left at real level |
| Movement speed | Not affected |
| PvP power / resilience | Scaled by ratio like all other stats |
| LFG daily dungeon reward tier | Uses real level — synced players keep full reward |

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
| `.sync on` solo | No effect — requires a party |
| Party member joins | No effect |
| Party member leaves | Sync cleared for the leaving player |
| Party fully disbanded | Sync deactivated for all members automatically |
| Player logs out | Sync deactivated |
| Player enters BG / Arena | No effect — sync remains active |
| `.sync on` or `.sync off` while in combat | Blocked, error message returned |
| `.sync show` while in combat | Allowed — read-only, no stat change |
| `.sync off` out of combat | Sync deactivated manually |

---

## Implementation status

### ✅ 1. Player state (`src/game/Entities/Player.h` / `Player.cpp`)

- `uint32 m_syncLevel` (0 = inactive), `float m_syncRatio` (1.0 when inactive).
- Helpers: `IsSynced()`, `GetSyncLevel()`, `GetEffectiveLevel()`, `GetSyncRatio()`,
  `SetSync(uint32 level)`, `ClearSync()`.
- `GetLevel()` is not modified. All sync-aware code uses `GetEffectiveLevel()`.

### ✅ 2. Stat scaling hooks (`src/game/Entities/StatSystem.cpp`)

Ratio applied at the end of each update function after normal computation:

- `Player::UpdateMaxHealth()` — override, clamps current HP to new max.
- `Player::UpdateMaxPower()` — override, clamps current power to new max.
- `Player::UpdateAttackPowerAndDamage()` — AP scaled by ratio; also uses
  `GetEffectiveLevel()` in place of `GetLevel()` for the level-based AP formula.
- `Player::UpdateArmor()` — armor value scaled by ratio.
- `Player::UpdateResistances()` — each resistance scaled by ratio.

### ✅ 3. Spell / healing output scaling (`src/game/Entities/Unit.cpp`)

Rather than a synthetic aura, the ratio is applied directly inside:

- `Unit::SpellBaseDamageBonusDone()` — scales the returned bonus when the unit
  is a synced player (`GetSyncRatio() < 1.0`).
- `Unit::SpellBaseHealingBonusDone()` — same pattern.

### ✅ 4. XP gain (`Player::GiveXP`)

`uint32 level = GetEffectiveLevel()` — XP formula uses sync level instead of
real level.

### ✅ 5. Quest colour / grey check

`GetQuestLevelForPlayer()` updated to use `GetEffectiveLevel()`, which affects
server-side calculations (XP rewards, reputation gains).

The grey/green/yellow difficulty colour in the UI is **client-side only**: the
server sends the quest's static level via `SMSG_QUEST_QUERY_RESPONSE` and the
client compares it against the player's real level locally. This cannot be
influenced server-side without patching the client — not worth doing.

### ✅ 6. `.sync` chat command (`src/game/Chat/Level0.cpp`)

```
.sync on    — SetSync(lowest online party member level); blocked in combat
.sync off   — ClearSync(); blocked in combat
.sync show  — displays current state; always available including in combat
```

Registered in `Chat.cpp` as `SEC_PLAYER`. Declared in `Chat.h`.

### ✅ 7. Party disband / leave hook (`src/game/Groups/Group.cpp`)

- `Group::Disband()` — calls `ClearSync()` on every member.
- `Group::RemoveMember()` — calls `ClearSync()` on the leaving player.

### ✅ 8. Logout / disconnect (`src/game/Entities/Player.cpp`)

`ClearSync()` called in `Player::RemoveFromWorld()`.

---

## LFG dungeon access for synced players

### ✅ Client-side — patch LFGDungeons.dbc

Script: `contrib/client_tools/patch_lfg_dungeons.py`

```bash
python patch_lfg_dungeons.py <path/to/LFGDungeons.dbc>
```

- Extract `LFGDungeons.dbc` from **`lichking-locale-enUS.MPQ`** (or your locale
  equivalent) — not from `lichking.MPQ` (which contains only 3D assets) and not
  from `locale-enUS.MPQ` (which has the outdated 24-field TBC version).
- The script sets `maxlevel = 80` for all dungeon and heroic entries
  (TypeIDs 1, 5, 6). Raids (TypeID 2) and world zones (TypeID 4) are untouched.
- Pack the modified file into `patch-4.MPQ` at internal path
  `DBFilesClient\LFGDungeons.dbc` and place it in the client's `Data\` folder.

### ✅ Server-side — eligibility check (`src/game/LFG/LFGMgr.cpp`)

`LFGMgr::GetLockedDungeons()` now uses `GetEffectiveLevel()` instead of
`GetLevel()` when computing which dungeons to lock (grey out) for a player.
Synced players are therefore validated against their sync level.

`GetRandomDungeonReward()` deliberately keeps `GetLevel()` (real level) so
synced players still receive the full daily reward tier for their actual level.

### ✅ DB table — not required

The server-side level check uses `LFGDungeonExpansionStore` (DBC data), not the
`lfg_dungeon_template` DB table. No SQL update is needed.

---

## Files touched

| File | Change |
|---|---|
| `src/game/Entities/Player.h` | New fields and helpers |
| `src/game/Entities/Player.cpp` | SetSync/ClearSync, GiveXP, RemoveFromWorld |
| `src/game/Entities/StatSystem.cpp` | UpdateMaxHealth, UpdateMaxPower, UpdateAttackPowerAndDamage, UpdateArmor, UpdateResistances overrides |
| `src/game/Entities/Unit.cpp` | SpellBaseDamageBonusDone, SpellBaseHealingBonusDone |
| `src/game/Chat/Chat.h` | HandleSyncCommand declaration |
| `src/game/Chat/Chat.cpp` | .sync registered in command table |
| `src/game/Chat/Level0.cpp` | HandleSyncCommand implementation |
| `src/game/Groups/Group.cpp` | Disband and RemoveMember hooks |
| `src/game/LFG/LFGMgr.cpp` | GetLockedDungeons uses GetEffectiveLevel() |
| `contrib/client_tools/patch_lfg_dungeons.py` | DBC patcher script |

---

## Known limitations / deferred work

- Gear stats are **not** individually scaled; a synced level-80 in full epic
  gear will still outperform a genuine low-level player in raw throughput.
  The ratio softens this but does not eliminate it.
- Abilities above sync level remain usable.
- No visual indicator to other players that a character is synced (could add
  a buff icon via a cosmetic aura later).
- Dungeon/raid lockout and loot eligibility are unaffected by sync level.
- Quest difficulty colour in the UI reflects the player's real level (client-side calculation, not changeable server-side without a client patch).
