# Kiwi Rounds

Original 2D round-based arena prototype for Android.

## Main menu
- **Play** opens three choices: online, vs bots, and training.
- **Vs bots** offers easy, normal, and hard bot difficulty.
- **Training** starts directly in the arena. Open the separate **CARDS** menu whenever you want to build or change a loadout; selected cards are applied immediately.
- **Cards** show an illustrated emblem, their main effect, buffs and debuffs. Built-in weapon cards include homing shots, ricochets, heavy shots, rapid fire, a larger magazine and a rail-speed projectile.
- **Weapon progression** changes the fighter's drawn blaster as weapon cards are equipped; higher weapon levels add visible rails, trims and muzzle effects.
- **Settings** currently contains sound and vibration preference switches; actual audio and haptics are not connected yet.
- **Skins** lets you cycle through built-in colors and loaded mod skins.
- **Mods** displays loaded mod counts/names and can rescan the mods folder.

## Current controls (landscape)
- Left virtual joystick: move.
- WAVE button: fire a harmless energy pulse.
- Right-bottom virtual joystick: aim.
- JUMP button: jump.
- MENU: pause and return to the main menu.
- CARDS: open the training card menu while in training.
- Keyboard test: A/D or arrows to move, W/up to jump, Space to fire, I/J/K/L to aim.

## Online mode
The menu entry is present, but online matchmaking and network play are not implemented yet. Selecting it displays this status instead of pretending that a network match is available.

## Mod support (data-only JSON)
Mods are loaded from `user://mods/<folder>/mod.json`. Each mod folder contains one `mod.json`. Mods provide data only; arbitrary mod scripts are never executed.

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
    {"id": "mod_speed", "name": "Turbo", "desc": "Move faster", "effect": "swift"}
  ]
}
```

Supported skin fields: `id`, `name`, `color` (hex color).
Supported map fields: `id`, `name`, `platforms` (array of x/y/w/h platform objects).
Supported upgrade fields: `id`, `name`, `desc`, `effect`, `primary`, `buff`, `debuff`, and `art`. Effects currently supported: `swift`, `spring`, `wave`, `rapid`, `sturdy`.

## Open and build
Import this folder in Godot 4.3+ and run `scenes/main.tscn`. Android export requires matching Godot export templates and Android build tools. No APK has been built or device-tested yet.

The project uses original code and placeholder visuals; it does not contain ROUNDS source code or original game assets.
