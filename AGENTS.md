# Platformer Fighter — Agent Context

Hand-off brief for any agent working on this repo. Read this before changing scope or architecture.

## What this is

A **tiny, polish-first Smash-like (platform fighter)** in **Godot 4.6** (GDScript).

- Local folder: `C:\Users\PROPRIETAIRE\Documents\platformer-fighter`
- GitHub: https://github.com/Akuvent/platformer_fighter
- Display name in `project.godot`: **Platformer Fighter**
- Author: Akuvent (17). Solo-dev focused; networking/multiplayer is out of scope for now on purpose.

North star: a **clean, juice-heavy solo fight fantasy** — not a big roster game, not a survival game, not online Smash.

## Current milestone (do this first)

Build the **smallest playable hit lab**:

1. Player can move + jump + do **one** attack
2. One **brainless enemy / dummy** (idle or fixed patrol only — no real AI)
3. On hit: **hitstop** + **true anime impact frames**
4. Dummy takes hitstun / knockback (even if crude)

Success = landing a hit feels expensive and “illegal,” not that systems are complete.

### Impact frames (core juice goal)

Desired look: real anime impact — **not** a soft white flash only.

Preferred stack on strong hits:

1. **Hitstop** — freeze attacker + victim briefly
2. **Impact frame** for 1–3 frames:
   - full **blackout** + **white silhouettes**, and/or
   - **color invert**
3. Camera punch / tiny zoom optional
4. SFX + particles after the freeze

Implementation guidance:

- Prefer **fullscreen post-process / ColorRect shader** for invert or blackout
- For white silhouettes: temporarily force **fighter materials** to unshaded white; black out the world — do **not** blindly `modulate` the whole scene tree
- Reserve full blackout/invert for heavy hits so it stays special
- Shader-only is enough; no custom impact art required for v1

## Product direction (locked for now)

| Do | Don’t |
|---|---|
| Tiny polished platform fighter | Full Smash clone / Melee physics completeness |
| Solo / PvE-leaning long-term | Online multiplayer / rollback / netcode |
| Brainless dummy first | Real AI, aggro, combo DI, ledge craft |
| 1 stage, 1–2 fighters max | Roster, items, CSS, story campaign |
| Juice + feel + timing | Hunger/crafting/survival (explicitly rejected) |
| Finish small vertical slices | Scope creep into “systems for later” |

Long-term fantasy (later, not now): Smash-like combat that can carry a **PvE** experience (Spiritfall-adjacent), because solo fun is the priority and networking is deferred. **Do not start AI/campaign work until the hit lab feels great.**

## Design constraints

- **Art-light**: 2D fighters, limited facing (flip L/R is fine), placeholders OK
- Girlfriend may help with short anims later (idle/run/short attack) — do not block gameplay on art
- Prefer readable hitboxes over fancy sprites
- One composition of feel > many half features

## Forbidden until milestone ships

- Multiplayer / networking
- Complex enemy AI
- Percent/DI/ledge tech parity with Smash
- Items, assist trophies, final smashes
- Base building, crafting, hunger, meta progression trees
- Large content pipelines (many stages/characters)

## Suggested Smash-lite combat minimum (after impact frames work)

Only if the hit lab already feels good:

- Jump (solid; short hop optional later)
- Attack hitboxes with startup / active / recovery
- Knockback + simple percent (optional at first)
- Blast zones / KO later
- Still one stage, brainless foe

Steal Smash **fantasy**, not the full ruleset.

## Repo layout

```
Resources/          # data, combat resources
  Characters/
  Combat/           # hit data, impact settings, etc.
Scenes/
  Characters/
  Main/             # entry scenes (Main.tscn exists, mostly empty)
  Stages/
  UI/
Scripts/
  Autoload/
  Characters/
  Combat/           # hitstop, impact frames, hitboxes, knockback
  Stages/
  UI/
Sounds/SFX|Music/
Sprites/Characters|Stages|UI|VFX/
```

Put impact-frame / hitstop / hitbox logic under `Scripts/Combat` (+ `Resources/Combat` for tunable data).

## Tooling notes

- Engine: Godot **4.6** stable (Windows exe used by local launcher)
- Desktop shortcut launches `.cursor-autocommit/launch_platformer_fighter_silent.vbs` (editor + autosave watcher)
- `.cursor-autocommit/` is **gitignored** (machine-local)
- Autocommit watcher commits local WIP every ~10 min while Godot is open — don’t fight it; keep secrets out of the project tree

## Prior art / player skill context

Author previously finished `platformer_training` (Mario-style Godot trainer: player, enemies, coins, checkpoints, platforms, SFX). Comfortable with Godot 2D basics; weak on networking; history of scope creep — **agents must protect small scope**.

## Agent working rules

1. Read this file; prefer the current milestone over future ideas in chat history
2. If a request expands scope, implement the smallest slice that still trains impact frames / feel
3. Prefer finishing playable loops over architecture astronautics
4. Keep code simple and readable; match existing Godot/GDScript style when present
5. Do not add multiplayer “hooks for later”
6. When in doubt, cut features and polish the hit

## One-line pitch

> A tiny Smash-like hit lab in Godot whose first job is to make one attack look and feel like a real anime impact frame against a brainless dummy.
