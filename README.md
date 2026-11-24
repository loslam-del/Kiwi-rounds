# Kiwi Rounds

Original 2D round-based arena prototype for Android.

## Current controls (landscape)
- Left virtual joystick: move.
- Left-side WAVE button: fire an energy pulse.
- Right-bottom virtual joystick: aim the character's arm in any direction.
- JUMP button above the right joystick: jump.
- Keyboard test: A/D or arrows to move, W/up to jump, Space to fire, I/J/K/L to aim.

## Mod support (data-only JSON)
Mods are loaded from `user://mods/<folder>/mod.json` when the game starts. On Android this is the game's writable user-data folder; create a folder for each mod and put a `mod.json` file inside. Mods only provide data; the game does not execute mod scripts.

Example:
```json
{
  "name": "My first mod",
  "skins": [
    {"id": "violet", "name": "Violet", "color": "#a77bff"},
    {"id": "mint", "name": "Mint", "color": "#70e0b4"}
  ],
  "maps": [
    {
      "id": "wide_sky",
      "name": "Wide sky",
      "platforms": [
        {"x": 300, "y": 540, "w": 220, "h": 22},
        {"x": 640, "y": 420, "w": 260, "h": 22},
        {"x": 980, "y": 540, "w": 220, "h": 22}
      ]
    }
  ],
  "upgrades": [
    {
      "id": "mod_speed",
      "name": "Turbo",
      "desc": "Move faster",
      "effect": "swift"
    }
  ]
}
```

Supported skins: `id`, `name`, `color` (hex color). Use the in-game SKIN button to cycle loaded mod skins.
Supported maps: `id`, `name`, `platforms` (array of x/y/w/h platform objects). Built-in and mod maps rotate between rounds.
Supported upgrades: `id`, `name`, `desc`, `effect`. Effects currently supported: `swift`, `spring`, `wave`, `rapid`, `sturdy`. Mod upgrades can add new names/descriptions and reuse one of these effects.

## Open and build
Import this folder in Godot 4.3+ and run `scenes/main.tscn`. Android export requires matching Godot export templates and Android build tools. No APK has been built or device-tested yet.

The project uses original code and placeholder visuals; it does not contain ROUNDS source code or original game assets.
