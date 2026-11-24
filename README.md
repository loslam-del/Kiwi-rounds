# Kiwi Rounds

An original 2D arena prototype for Android, inspired by the round-based arena-fighter genre.

## Implemented in the current prototype
- Landscape 2D arena with platform physics
- Player versus a simple CPU rival
- Touch controls for movement, jumping and harmless energy pulses
- Energy pulses push characters away; no realistic weapons
- Best-of-five rounds
- Three arena layouts that rotate between rounds
- Three random upgrade choices after each round
- Procedurally drawn placeholder visuals; no external assets required

## Open the project
1. Install/open Godot 4.3 or newer.
2. Import this repository folder as a project.
3. Run `scenes/main.tscn`.

Keyboard testing: A/D or arrow keys to move, W/up to jump, Space for an energy pulse.

## Android build
The project is configured for landscape orientation and a 1280×720 base viewport. To create an APK, use Godot's Android export workflow and the matching export templates. An APK has not been built or device-tested yet.

## Planned next steps
- Replace placeholder drawings with finished original art and effects
- Add more arenas and a larger upgrade pool
- Add menus, settings, sound and animation
- Add online 1v1 after the offline gameplay is stable

This project uses original code and placeholder visuals. It does not include ROUNDS source code or original game assets.
