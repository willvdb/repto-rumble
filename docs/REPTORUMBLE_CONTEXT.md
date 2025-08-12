# Repto Rumble — Workspace Context for Copilot

> **Purpose:** Give Copilot a single, reliable source of truth so it generates code and data that slot straight into the project without back‑and‑forth.
> 
> **⚠️ IMPORTANT:** This document should be updated every time we work on this project to maintain accuracy. Always add new implementations, architectural changes, and current status to keep Copilot aligned with the actual project state.

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

  - `AnimatedSprite2D` (drives visuals + frame events) — **sprite_frames = placeholder_basic.tres**
  - `CollisionShape2D` (20×40 RectangleShape2D for movement collision)
  - `Hurtbox` (`Area2D`) + `CollisionShape2D` — **Ready for combat system**
  - `Sockets` (`Node2D`) with children **`HitSocketA`**, **`HitSocketB`** — **TODO: spawn points**

- **Player.gd** — Finite State Machine (FSM) managing states: **✅ IMPLEMENTED & TESTED**

  - States: Idle, Run, JumpStart, Air, Land, AttackLight, AttackHeavy, WallSlide, WallJump, Hitstun
  - **InputProvider integration**: `input_provider.is_action_pressed("jump")` for multiplayer support
  - **Stamina system**: Recovery, consumption, and UI integration with DebugOverlay
  - **Exports**: `player_id` for multiplayer identification, `input_map_suffix` for custom bindings
  - **Core methods**: `switch_state()`, `get_input_direction()`, `consume_stamina()`, `_on_animation_finished()`

- **States** — GDScript classes extending `BaseState` resource: **✅ ALL CORE STATES IMPLEMENTED**

  - **Required methods**: `enter(owner, prev)`, `exit(owner, next)`, `physics(owner, delta)`, `handle_event(owner, event, data)`
  - **Current states**: `Idle.gd`, `Run.gd`, `JumpStart.gd`, `Air.gd`, `Land.gd`, `AttackLight.gd`, `AttackHeavy.gd`, `WallSlide.gd`, `WallJump.gd`, `Hitstun.gd`
  - **Animation integration**: Each state plays appropriate animation on enter
  - **Input handling**: Uses `owner.input_provider` for consistent multiplayer support

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

## Input Map (configured in project.godot)

**✅ Current bindings:**
- `move_left` — Arrow Left, A
- `move_right` — Arrow Right, D  
- `move_up` — Arrow Up, W
- `move_down` — Arrow Down, S
- `jump` — Space
- `attack_light` — Z
- `attack_heavy` — X
- `debug_toggle` — F3

**Future additions:** `dash`, `sprint`, wall interaction actions

## Multiplayer Architecture

- **InputProvider.gd** — Input abstraction layer for multiplayer support **✅ IMPLEMENTED & TESTED**

  - Each player gets an InputProvider instance with unique `player_id`
  - Automatically maps actions: `jump` → `jump_p2`, `move_left` → `move_left_p2`, etc.
  - Fallback to base actions for backward compatibility
  - Methods: `is_action_pressed()`, `is_action_just_pressed()`, `get_axis()`
  - Simple action mapping: "left"/"right" maps to "move_left"/"move_right"

- **Player.gd multiplayer integration:** **✅ IMPLEMENTED**

  - `@export var player_id: int = 0` — Player identifier (0 = P1, 1 = P2, etc.)
  - `@export var input_map_suffix: String = ""` — Override suffix if needed
  - `var input_provider: InputProvider` — Handles all input for this player
  - `get_input_direction()` uses InputProvider instead of direct Input calls

- **FSM States and InputProvider:**

  - All states use `owner.input_provider` for input instead of global `Input`
  - Example: `owner.input_provider.is_action_just_pressed("jump")`
  - Example: `owner.input_provider.get_axis("left", "right")`

- **Local multiplayer setup:**
  - Each Player instance gets unique `player_id` and InputProvider
  - Input actions automatically suffixed: P1 uses `jump`, P2 uses `jump_p2`
  - Supports splitscreen, shared screen, and future online modes

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

## Testbed Scene & Testing

- **scenes/core/World.tscn** — Main testbed scene with:
  - StaticBody2D ground platform for movement testing
  - Player spawn point at (0, -100)
  - DebugOverlay for real-time monitoring
  - Camera following player
  
- **scenes/ui/DebugOverlay.tscn** — Debug HUD showing:
  - Current FSM state name
  - Player velocity (X, Y)
  - Stamina value and recovery
  - Input directions and action presses
  - FPS counter

- **Controls for testing:**
  - Arrow Keys/WASD: Movement
  - Spacebar: Jump
  - Z: Light Attack
  - X: Heavy Attack  
  - F3: Toggle Debug Overlay

- **placeholder_basic.tres** — Complete SpriteFrames resource with:
  - All required animation names matching the animation contract
  - Uses square.png as atlas texture (64x64 region)
  - Proper loop settings for each animation type
  - Ready to be replaced with real sprite sheets

## Current Goals (prioritized)

1. ✅ Remove unrelated boilerplate (RTS/top‑down/grid/shooter/inventory)
2. ✅ Build clean Player FSM + hitbox/hurtbox + resolver
3. ✅ Implement InputProvider system for multiplayer support
4. ✅ Create testbed scene with debug overlay and placeholder sprites
5. Integrate frame‑event system for attacks
6. Implement first playable **skink** with `idle/run/jump/attack` animations
7. (Optional) Editor‑only AI helper dock — **disabled** by default; we mainly use VS Code

## Implementation Status

### ✅ **Completed Systems**

- **FSM Architecture**: Complete Player.gd FSM controller with BaseState system
- **State Implementations**: All core states (Idle, Run, JumpStart, Air, Land, AttackLight, AttackHeavy, WallSlide, WallJump, Hitstun)
- **InputProvider System**: Multiplayer-ready input abstraction with player ID mapping
- **Testbed Environment**: World.tscn with ground, player spawn, and debug overlay
- **Debug Tools**: Real-time FSM state, velocity, stamina, and input monitoring
- **Placeholder Art**: Working SpriteFrames with all required animation names
- **Project Structure**: Clean, organized codebase following established conventions

### 🚧 **Next Priority Tasks**

- **Frame Events**: Implement AnimatedSprite2D frame event system for attack timing
- **MoveRunner**: Create system to consume move JSON and spawn hitboxes
- **Combat System**: Implement hitbox/hurtbox collision and resolution
- **Real Sprites**: Replace placeholder_basic.tres with actual skink animations

### 📁 **Current File Organization**

```
scenes/core/
├── player.tscn ← CharacterBody2D with AnimatedSprite2D, collision, hurtbox
└── World.tscn ← Testbed scene with StaticBody2D ground and debug overlay

scenes/ui/
└── DebugOverlay.tscn ← HUD showing FSM state, velocity, stamina, inputs

scripts/core/
├── input_provider.gd ← Multiplayer input abstraction
└── player/
    ├── player.gd ← FSM controller with InputProvider integration
    └── states/ ← Individual state classes extending BaseState

sprites/characters/
└── placeholder_basic.tres ← Working SpriteFrames using square.png atlas

scripts/tools/
└── placeholder_sprite_generator.gd ← Tool for creating placeholder sprites
```

---

## 🎯 **Current Project Status (Updated Aug 12, 2025)**

**✅ FULLY FUNCTIONAL:**
- FSM-based player movement and state management
- Multiplayer-ready input system with InputProvider
- Complete testbed environment with debug tools
- All core platformer states (idle, run, jump, air, land)
- Attack states (light/heavy) with stamina system
- Wall movement states (slide, jump)
- Placeholder sprite system ready for real art

**🚧 READY FOR NEXT PHASE:**
- Frame-event system integration for attack timing
- Hitbox/hurtbox collision and damage resolution  
- Move JSON data system for attack definitions
- Real sprite art to replace placeholders

**🎮 HOW TO TEST:**
1. Open project in Godot, main scene auto-loads `World.tscn`
2. Use arrow keys/WASD to move, Space to jump, Z/X to attack
3. Press F3 to toggle debug overlay for real-time FSM monitoring
4. All states transition properly with visual feedback via placeholder sprites

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
