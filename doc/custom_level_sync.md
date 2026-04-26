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
| Max mana / energy / rage / runic power | **Not scaled** — mana left at full value; scaling would cause client-side grey-out of affordable spells (DBC costs are client-side and cannot be changed without a client patch) |
| Mana regeneration (spirit + mp5) | **Not scaled** — mana system is entirely untouched |
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

When `.sync on` is activated, two values are stored on the player:

```
m_syncLevel  = lowest online party member's level      (uint32)
m_syncRatio  = float(m_syncLevel) / float(GetLevel())  (float, always in (0, 1])
```

`m_syncRatio` is computed once at activation and reused for every stat
recalculation until sync is cleared. It represents the fraction of the player's
real level that the sync level corresponds to.

**Example — level 46 syncing to a level 6 party member:**

```
m_syncLevel = 6
m_syncRatio = 6.0 / 46.0 ≈ 0.130

Max HP 10 000  →  floor(10 000 × 0.130) = 1 300
Max mana 8 000 →  floor(8 000  × 0.130) = 1 040
Armor    5 000 →  floor(5 000  × 0.130) =   650
```

Applied as a flat multiplier to the relevant totals after normal stat
computation. For HP and mana the current value is clamped to the new max on
activation.

A simple linear ratio is the starting point. If it turns out to feel wrong
(e.g. a level 80 synced to 70 is still far too strong), a power curve can be
introduced by changing `SetSync` to store:

```
m_syncRatio = pow(float(syncLevel) / float(realLevel), k)   -- k > 1 makes scaling more aggressive
```

---

## Formulas by system

All values are integers unless noted otherwise. `floor()` is implicit from
integer truncation in the C++ casts.

### Player — resources

| System | Formula |
|---|---|
| Max HP | `newMax = max(1, floor(normalMaxHP × ratio))` — current HP clamped to newMax |
| Max mana | Unchanged — see "What does NOT scale" for rationale |
| Max energy / rage / runic power | Unchanged — fixed caps, do not scale with level |
| Mana regen (spirit + mp5) | Unchanged — mana system fully untouched |

### Player — combat stats

| System | Formula |
|---|---|
| Armor | `finalArmor = floor(computedArmor × ratio)` |
| Resistances (all schools) | `finalRes = floor(computedRes × ratio)` |
| Attack power (melee) | Level-based component recalculated with `syncLevel`; then `finalAP = floor(computedAP × ratio)` |
| Attack power (ranged) | Same as melee — both use `GetEffectiveLevel()` in the level formula and then ratio is applied |

Note: AP gets a **double reduction** — the per-level contribution is already
lower because the level formula uses `syncLevel`, and then the ratio is applied
on top of that whole value.

### Player — damage and healing output

These are applied inside the bonus functions, on the **already-computed** bonus
value before it is added to the base hit/heal.

| System | Formula |
|---|---|
| Spell power bonus (damage) | `DoneAdvertisedBenefit = floor(DoneAdvertisedBenefit × ratio)` — in `SpellBaseDamageBonusDone` |
| Spell power bonus (healing) | `AdvertisedBenefit = floor(AdvertisedBenefit × ratio)` — in `SpellBaseHealingBonusDone` |
| Total heal (final) | `finalHeal = floor(computedHeal × ratio)` — in `SpellHealingBonusDone` |
| Total spell damage (final) | `finalDamage = floor(computedSpellDamage × ratio)` — in `SpellDamageBonusDone` |
| Total melee damage (final) | `finalDamage = floor(computedMeleeDamage × ratio)` — in `MeleeDamageBonusDone` |

Spell damage goes through both `SpellBaseDamageBonusDone` (power component) and
`SpellDamageBonusDone` (final total). The ratio therefore applies **twice** for
the spell power bonus portion — once to the additive bonus and once to the whole
total that includes it.

### Player — critical chance

The weapon skill used in the crit formula is capped to `syncLevel × 5`:

```
effectiveSkill = min(weaponSkill, syncLevel × 5)
critBonus      = (effectiveSkill - targetDefenseSkill) × 0.2%   (vs NPCs)
```

This prevents the skill gap (e.g. skill 230 vs NPC defense 30) from inflating
crit chance by up to 40 pp.

### Player — XP gain

`BaseGain()` is called with `GetEffectiveLevel()` (sync level) instead of real
level, then a compensating multiplier is applied so the reward is meaningful
relative to the real character's leveling needs:

```
baseXP    = syncLevel × 5 + contentOffset
finalXP   = baseXP × sqrt(realLevel / syncLevel)
```

The `sqrt` factor keeps the reward **below** what killing a same-level mob at
real level would give, preventing abuse while still making synced content
worthwhile. Example for level 46 synced to 6:

```
baseXP  = 6×5 + 45 = 75
factor  = sqrt(46/6) ≈ 2.77
finalXP ≈ 208   vs   275 for a genuine same-level kill at level 46  (~76%)
```

If the sync level equals the real level (no sync active), the multiplier is 1
and XP is unaffected.

---

## Pet formulas

Pets (Hunter pets and Warlock demons) inherit the owner's ratio. Stats are
re-evaluated whenever `SetSync` or `ClearSync` is called on the owner.

| System | Formula |
|---|---|
| Pet max HP | `newMax = max(1, floor(computedPetHP × ownerRatio))` — in `Pet::UpdateMaxHealth` |
| Pet attack power | `finalPetAP = floor(computedPetAP × ownerRatio)` — in `Pet::UpdateAttackPowerAndDamage` |
| Pet spell damage (final) | `finalDamage = floor(computedSpellDamage × ownerRatio)` — in `SpellDamageBonusDone` |
| Pet melee damage (final) | `finalDamage = floor(computedMeleeDamage × ownerRatio)` — in `MeleeDamageBonusDone` |
| Pet critical chance | Weapon skill capped to `ownerSyncLevel × 5` — in `CalculateEffectiveCritChance` |
| Pet max mana/energy/focus | **Not scaled** — pet power pools are based on the pet's own creature level |

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

### ✅ 3. Spell / melee / healing output scaling (`src/game/Entities/Unit.cpp`)

Rather than a synthetic aura, the ratio is applied directly inside:

- `Unit::SpellBaseDamageBonusDone()` — scales the spell power additive bonus.
- `Unit::SpellDamageBonusDone()` — scales the final outgoing spell damage total.
- `Unit::MeleeDamageBonusDone()` — scales the final outgoing melee damage total.
- `Unit::SpellBaseHealingBonusDone()` — scales the healing power additive bonus.
- `Unit::SpellHealingBonusDone()` — scales the final outgoing heal total.
- `Unit::CalculateEffectiveCritChance()` — caps weapon skill to `syncLevel × 5`
  to prevent the skill gap from inflating crit chance vs low-level NPCs.

All five checks also cover pets: if `this` is a pet, the owner's ratio/sync
level is used instead.

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

### ✅ 8. Logout / disconnect (`src/game/Server/WorldSession.cpp`)

`ClearSync()` called in `WorldSession::LogoutPlayer()` before `SaveToDB()`.
`RemoveFromWorld()` is intentionally left alone — it fires on every map
transition (teleport, instance enter) and must not clear sync.

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
| `src/game/Entities/Player.h` | New fields and helpers; `GetLevelForTarget` override |
| `src/game/Entities/Player.cpp` | SetSync/ClearSync, GiveXP, RemoveFromWorld |
| `src/game/Entities/StatSystem.cpp` | Player: UpdateMaxHealth, UpdateAttackPowerAndDamage, UpdateArmor, UpdateResistances; Pet: UpdateMaxHealth, UpdateAttackPowerAndDamage |
| `src/game/Entities/Unit.cpp` | SpellBaseDamageBonusDone, SpellDamageBonusDone, MeleeDamageBonusDone, SpellBaseHealingBonusDone, SpellHealingBonusDone, CalculateEffectiveCritChance |
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
