# Repto Rumble — Workspace Context for Copilot

> **Purpose:** Give Copilot a single, reliable source of truth so it generates code and data that slot straight into the project without back‑and‑forth.

## Project Facts

- **Engine:** Godot 4 (GDScript)
- **Genre:** 2D reptile brawler/platformer
- **Art:** Pixel‑art, retro 90s arcade vibe
- **Core identity:** Each reptile’s movement/attacks draw from the real species; balance realism vs fun
- **Frame size:** **64×64** across all character animations
- **Palette:** Small fixed palette; shader‑based color swaps via 1D LUT

## Animation Contract (for all playable characters)

**Required animations (exact names):**

```
idle, run, jump_start, air, land,
attack_light_1, attack_light_2, attack_heavy,
hurt, wall_slide, wall_jump
```

- All frames: **64×64** (canvas & collision alignment consistent across characters)
- Use the same names across every character (scripts target these identifiers)
- Keep silhouettes centered; feet baseline consistent to avoid collider jitter
- Suggested FPS: idle 8–10, movement 12, attacks 12–15 (tweak per feel)

## Architecture Overview

- **Player.tscn** — `CharacterBody2D` with children:

  - `AnimatedSprite2D` (drives visuals + frame events)
  - `Hurtbox` (`Area2D`) + `CollisionShape2D`
  - `Sockets` (`Node2D`) with children **`HitSocketA`**, **`HitSocketB`** (spawn points)

- **Player.gd** — Finite State Machine (FSM) managing states:

  - Idle, Run, JumpStart, Air, Land, AttackLight, AttackHeavy, WallSlide, WallJump, Hitstun

- **States** — GDScript classes extending a `BaseState` resource

  - Methods: `enter(owner, prev)`, `exit(owner, next)`, `physics(owner, delta)`, `handle_event(owner, event, data)`

- **Move data** — `res://data/moves/*.json` or `.tres` (JSON favored during iteration)
- **MoveRunner.gd** — consumes move data + **frame events** to spawn hitboxes
- **Hitbox/Hurtbox** — `Area2D` scenes with scripts; physics layers for resolver
- **HitResolver** — applies damage, knockback, hitstop, hitstun, sfx, and on‑hit events

## Frame‑Event System (editor‑agnostic)

- Emitted from `AnimatedSprite2D` per frame index or labels
- Consumption path: `Player.gd` → `MoveRunner.gd` → spawn/resolve
- **Event types (extendable):**

  - `spawn_hitbox` → params: socket, shape, dims/radius, damage, kb, hitstop, hitstun, attr, priority
  - `despawn_hitbox` → params: id/tag
  - `sfx` → params: id/path
  - `vfx` → params: id/path/socket
  - `state_cancel` → params: to_state, at_frame

## Move JSON — Canonical Shape

```json
{
  "name": "skink_attack_light_1",
  "startup": 4,
  "active": 3,
  "recovery": 10,
  "cancel_windows": [
    { "from": "active", "to": "attack_light_2", "at_frame": 2 }
  ],
  "hitboxes": [
    {
      "at_frame": 5,
      "socket": "HitSocketA",
      "shape": "circle",
      "radius": 12,
      "damage": 6,
      "knockback": [220, -120],
      "hitstop": 6,
      "hitstun": 12,
      "priority": 1,
      "attr": "strike"
    }
  ],
  "sfx": { "start": "res://audio/sfx/hit_light.wav" }
}
```

> **Rule:** JSON should be data‑only; all behavior lives in scripts.

## Hitbox/Hurtbox Contracts

- **Hitbox.tscn** (`Area2D`)

  - Group: `hitbox`
  - Exposed data: damage, kb(vec2), hitstop, hitstun, priority, attr, owner_id, team
  - Shape: Circle/Rect/Polygon supported; configured at spawn time from move data

- **Hurtbox.tscn** (`Area2D`)

  - Group: `hurtbox`
  - Script tracks invuln flags and team

- **HitResolver.gd**

  - On `hitbox` vs `hurtbox`: apply knockback, start hitstop timer, signal `on_hit`
  - No friendly fire (same team ignored) unless `attr == "self_hit"`

## Palette Swap Shader (1D LUT)

```glsl
shader_type canvas_item;
uniform sampler2D palette_tex : hint_default_black; // 1D LUT in a 2D texture (width N, height 1)
uniform float steps = 32.0; // number of indexed colors

vec3 index_sample(float i){
    float u = (floor(i) + 0.5) / steps;
    return texture(palette_tex, vec2(u, 0.5)).rgb;
}

void fragment(){
    vec4 c = texture(TEXTURE, UV);
    // assume source grayscale indexes in c.r * steps
    float idx = clamp(round(c.r * (steps - 1.0)), 0.0, steps-1.0);
    vec3 mapped = index_sample(idx);
    COLOR = vec4(mapped, c.a);
}
```

> Provide per‑player `palette_tex` to get color variants without duplicating sprites.

## Physics Layers & Groups

- **Layers (proposal):**

  - 1: `WORLD`
  - 2: `PLAYER`
  - 3: `HITBOX`
  - 4: `HURTBOX`

- **Groups:** `player`, `hitbox`, `hurtbox`

## Input Map (default bindings)

- `move_left`, `move_right`, `jump`, `attack_light`, `attack_heavy`, `dash`

## Folder Structure (authoritative)

```
art/characters/...
audio/sfx/
audio/music/
data/characters/
data/moves/
scenes/core/
scenes/ui/
scripts/core/player/states/
scripts/core/combat/
shaders/
utils/
```

## Coding Conventions

- GDScript 2.0, typed where practical; `class_name` for reusable scripts
- Snake_case for vars/functions; PascalCase for classes/states
- Avoid magic numbers; use `const` for gameplay constants (gravity, speeds)
- Signals for cross‑system events (e.g., `signal hit_landed(data)`)
- State scripts are **pure** (no editor/IO); side‑effects go through `Player.gd`

## Minimal State Skeleton (copilot should follow this)

```gdscript
extends BaseState
class_name Idle

func enter(owner: Node, _prev: BaseState) -> void:
    var anim := owner.get_node("AnimatedSprite2D")
    anim.play("idle")

func physics(owner: Node, delta: float) -> void:
    # read inputs, transition when needed
    # if abs(input.x) > 0: owner.switch_state("Run")
    pass

func handle_event(owner: Node, event: StringName, data := {}) -> void:
    pass
```

## Testbed Scene

- **scenes/core/World.tscn** with a flat floor, spawn 1× Player, optional dummy target
- **scenes/ui/DebugOverlay.tscn** for FPS, state name, facing, velocity, last event

## Current Goals (prioritized)

1. Remove unrelated boilerplate (RTS/top‑down/grid/shooter/inventory)
2. Build clean Player FSM + hitbox/hurtbox + resolver
3. Integrate frame‑event system for attacks
4. Implement first playable **skink** with `idle/run/jump/attack` animations
5. (Optional) Editor‑only AI helper dock — **disabled** by default; we mainly use VS Code

---

# Copilot Prompt Recipes (paste into Copilot Chat with `@workspace`)

### 1) New FSM State

"Create `scripts/core/player/states/Run.gd` for Godot 4. Extends `BaseState` (Resource). On `enter` play `run`. In `physics`, handle horizontal input, set `owner.velocity.x`, and transition to `Idle` at zero input, `JumpStart` on jump. Keep it data‑driven and reference 64×64 animations by name."

### 2) Move JSON

"Create `data/moves/skink_attack_light_1.json` using our schema. Startup 4, active 3, recovery 10. One circular hitbox at frame 5 from `HitSocketA`, radius 12, damage 6, knockback \[220, -120], hitstop 6, hitstun 12, priority 1, attr `strike`. Cancel to `attack_light_2` at active frame 2."

### 3) Hitbox Scene

"Create `scenes/core/Hitbox.tscn` (Area2D + CollisionShape2D) and `scripts/core/combat/Hitbox.gd`. Group `hitbox`. Export damage, knockback(Vector2), hitstop, hitstun, priority, attr, owner_id, team. Add a method `arm(shape_dict)` that configures circle/rect shapes at runtime."

### 4) Frame Events Hook

"Modify `scripts/core/player/Player.gd` so `AnimatedSprite2D` emits events on specific frames (e.g., frames listed in move JSON). Route events to `MoveRunner.gd`, which spawns/cleans hitboxes."

### 5) Palette Swap Shader Usage

"Add a material to `AnimatedSprite2D` that uses `shaders/palette_swap.shader` with a per‑player `palette_tex` LUT. Document how to set palettes in `data/characters/skink.tres`."

---

## Constraints & Don’ts (for AI‑generated code)

- Don’t rename core nodes or animation names
- Don’t hardcode file paths outside the project structure above
- Don’t put plugin/editor code into runtime scripts
- Keep move data declarative; gameplay logic stays in scripts

## Glossary

- **FSM**: Finite State Machine driving `Player.gd`
- **Frame events**: Per‑frame cues from `AnimatedSprite2D` used to spawn hitboxes and play sfx
- **Hitstop**: Brief pause on impact applied to attacker/defender
- **Hitstun**: Frames where the defender can’t act

---

**Tip:** At the top of new files, add a brief SPEC block so Copilot stays aligned:

```gdscript
# SPEC: Godot 4, Repto Rumble
# - States extend BaseState (Resource)
# - AnimatedSprite2D animations: idle/run/jump_start/air/land/attack_*/hurt/wall_*
# - Use MoveRunner + frame events to spawn Hitbox.tscn at HitSocketA/B
```
