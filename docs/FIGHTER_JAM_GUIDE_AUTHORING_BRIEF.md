# Brief: Author the Platformer Fighter jam guide

You are being asked to **write a coaching rule**, not to implement the game.

## Deliverable

Create:

`C:\Users\PROPRIETAIRE\Documents\platformer-fighter\.cursor\rules\fighter-jam-guide.mdc`

Style/structure template (copy the *shape*, not the Mario content):

`C:\Users\PROPRIETAIRE\Documents\mario\.cursor\rules\mario-jam-guide.mdc`

Also read for product truth:

`C:\Users\PROPRIETAIRE\Documents\platformer-fighter\AGENTS.md`

## Style requirements (match Mario guide)

Reproduce these traits from `mario-jam-guide.mdc`:

1. YAML frontmatter:
   - `description:` one line about coaching this project
   - `alwaysApply: true`
2. Title like: `# … Coaching (Godot 4.x)`
3. Opening identity paragraph: who the student is, what they’re building, engine version, **teach step-by-step / do not write the whole game**
4. Section **How to respond** — short bullets on coaching cadence (why + which API first; 1–2 steps then wait; cut scope if distracted)
5. Section **Build order (recreate this roadmap)** — numbered phases only for the **hit lab milestone**
6. Section **Godot hooks cheat sheet** — markdown table of hooks/signals relevant to *this* game
7. Section **Scene skeletons (teach these trees)** — compact ASCII scene trees
8. Section **Day-1 / Phase-1 success criteria** — smallest playable bar
9. Section **Common mistakes to warn about**
10. Section **Tunables to expose with `@export`**

Keep it **concise** (roughly Mario-guide length: ~60–90 lines). No essays. No full scripts. Prefer checklists, trees, tables, tiny snippet hints at most.

Coaching voice:

- Explain *why* and *which Godot event/API* before code
- Prefer editor steps + tiny snippets over dumping systems
- Protect scope aggressively

## Student profile (important — not a total beginner)

- Akuvent, ~17
- Finished `platformer_training` (Mario-style Godot 4: player, enemies, coins, checkpoints, platforms, SFX)
- Comfortable with: `CharacterBody2D`, `_physics_process`, basic Area2D, scenes, Input Map
- Weak / deferred: networking, real AI
- Failure mode: scope creep — guide must keep them on the hit lab

So: coach like a **second jam** (feel + combat juice), not “what is a node.”

## What the game is

**Platformer Fighter** — tiny polish-first Smash-like in **Godot 4.6** GDScript.

- Path: `C:\Users\PROPRIETAIRE\Documents\platformer-fighter`
- Repo: https://github.com/Akuvent/platformer_fighter
- `Scenes/Main/Main.tscn` exists (nearly empty); folder tree already scaffolded
- Art-light placeholders OK; flip L/R facing is fine
- Girlfriend may animate later — **do not block** on art

North star for this guide’s scope: a **hit lab**, not full Smash, not PvE campaign, not multiplayer.

## Milestone the guide must teach (only this)

1. Player move + jump + **one** attack
2. One **brainless** dummy (idle or dumb patrol — no AI)
3. On hit: **hitstop** + **anime impact frames** (blackout and/or invert; white silhouettes preferred)
4. Dummy gets hitstun + crude knockback

Success = the hit feels expensive / “illegal.”

### Impact frame tech constraints to encode in the guide

- Fullscreen `CanvasLayer` + `ColorRect` shader for invert / blackout (1–3 frames)
- White silhouettes via **fighter material overrides**, world blackout separately
- **Warn against** modulating the entire root tree
- Shader-only OK — no custom impact art required
- Save nuclear frames for the strong/only attack so they stay special
- Stack: hitstop → impact frame → optional camera punch → SFX/particles after

## Hard exclusions (must appear as cut-list / “if distracted, cut”)

Do **not** put these in the build order:

- Multiplayer / netcode / rollback
- Smart AI, aggro, DI, ledge tech, shield, grab
- Percent system depth, blast zones/KO (optional *after* hit lab only — mention as later, not day-1)
- Items, roster, CSS, story, Spiritfall campaign
- Survival / crafting / hunger
- Full Melee physics parity

Steal Smash **fantasy**, not the ruleset.

## Required build order to put in the guide

Use this roadmap (adapt wording to Mario-guide tone):

1. **Setup** — `Main.tscn` as run scene; Input Map (`move_left`, `move_right`, `jump`, `attack`); 2D physics layers (`world`, `fighter`, `hitbox`, `hurtbox`); one flat stage (StaticBody2D or TileMapLayer); Camera2D
2. **Fighter movement** — `CharacterBody2D` player; `_physics_process`: run, gravity, jump on floor, `move_and_slide()`; face flip; placeholder rect/sprite OK
3. **One attack** — attack state with startup / active / recovery (even if crude timers); spawn or enable an `Area2D` hitbox only during active frames; facing-relative offset
4. **Brainless dummy** — second `CharacterBody2D` (or pinned dummy); hurtbox `Area2D`; no chase AI; can stand still; receives hit signal → hitstun + knockback velocity
5. **Hit pipeline** — hitbox `area_entered` / hurtbox detect → apply knockback + hitstun; ignore self-hits; one-hit-per-swing idempotency
6. **Hitstop** — brief pause (`Engine.time_scale` **or** local freeze flags / stop processing on both fighters for N frames — pick one approach and teach it consistently; prefer a small Combat helper under `Scripts/Combat`)
7. **Impact frames** — Combat/Impact controller: 1–3 frame blackout or invert via fullscreen shader; optional white silhouette material swap on both bodies; restore cleanly
8. **Feel pass** — `@export` tunables; camera punch optional; SFX stub optional; do **not** add new mechanics until the hit pops

Day-1 bar (encode explicitly): Input Map + player run/jump + ground + camera + F5 playable. Attack/dummy/impact come after that works.

## Scene skeletons to teach

Something in this family (refine as needed):

```
Main (Node2D)
├── Stage (StaticBody2D platforms / TileMapLayer)
├── Player (CharacterBody2D)
│   ├── CollisionShape2D
│   ├── Sprite2D / ColorRect placeholder
│   ├── Hurtbox (Area2D)
│   └── Hitbox (Area2D) [enabled only on active frames]
├── Dummy (CharacterBody2D)
│   ├── CollisionShape2D
│   ├── Sprite2D / ColorRect placeholder
│   └── Hurtbox (Area2D)
├── Camera2D
└── CombatFx (CanvasLayer)
    └── ImpactRect (ColorRect + shader)
```

Scripts live under `Scripts/Characters`, `Scripts/Combat` per repo layout. Tunables / impact settings can live in `Resources/Combat`.

## Godot hooks the cheat sheet should cover

Include at least:

| Hook / API | Likely use |
|------------|------------|
| `_physics_process` | Move, attack timers, knockback decay, hitstun |
| `_ready` | Cache nodes, connect hit/hurt signals |
| Area2D `area_entered` | Hitbox → hurtbox |
| Timer / frame counters | Startup, active, recovery, hitstop length, impact frames |
| `Engine.time_scale` or freeze flags | Hitstop |
| ShaderMaterial on ColorRect | Invert / blackout impact |
| Material override on sprites | White silhouette |
| Custom signals (`hit_landed`, etc.) | Fighter → CombatFx |
| `@export` | Speed, jump, hitbox frames, knockback, hitstop, impact duration |

## Common mistakes to include

- Building AI / percent / KO before the hit feels good
- Leaving hitboxes enabled outside active frames
- Root `modulate` for impact frames
- Doing hit logic only in `_process`
- Skipping hurtbox/hitbox layers/masks
- Writing one mega-script instead of Player / Dummy / CombatFx
- Impact every frame of contact (should be once per swing + short window)

## Tunables to list

`speed`, `jump_velocity`, `gravity`, `startup_frames`, `active_frames`, `recovery_frames`, `knockback`, `hitstun_frames`, `hitstop_frames`, `impact_frames` (1–3), maybe `impact_mode` (blackout / invert).

## How the finished `.mdc` should tell agents to respond

Mirror Mario:

- Why + which API before paste
- Next 1–2 concrete editor/script steps, then wait
- If user drifts: cut AI, KO, percent, second attack, second stage — keep move, jump, one attack, dummy, hitstop, impact frames

## Done criteria for *your* task (authoring)

- [ ] `fighter-jam-guide.mdc` exists with correct frontmatter
- [ ] Same section skeleton as Mario guide
- [ ] Build order matches hit lab only
- [ ] Impact-frame constraints + anti-modulate warning present
- [ ] No full game dump / no giant code blocks
- [ ] Student treated as Mario-graduate, not absolute beginner

Do **not** implement game features while writing the guide unless the user explicitly asks.
