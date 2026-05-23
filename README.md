# Edible Planet: Cosmic Feast

Cooperative 2D game — two players control one edible planet!

## Quick Start on Windows

### Option 1: With Godot Editor (recommended for first time)

1. Download Godot 4.x from https://godotengine.org/download/windows/
2. Extract `godot4.exe` somewhere
3. Open terminal (PowerShell or cmd) and run:
```
godot4.exe --path "C:\path\to\EdiblePlanet"
```
4. Or: open Godot → Import → select `project.godot` in this folder → Run (F5)

### Option 2: Double-click launch

1. Download Godot 4.x and put `godot4.exe` in your PATH (or in this folder renamed to `godot.exe`)
2. Double-click `windows\launch.bat`

### Option 3: Export as standalone .exe (no Godot needed after export)

In Godot Editor:
1. Project → Export → Add → Windows Desktop
2. Export project → save as `EdiblePlanet.exe` in this folder
3. Then just run `EdiblePlanet.exe` — no Godot needed!

## Controls

| Mode | Player 1 (Tilt) | Player 2 (Magnet) |
|------|-----------------|-------------------|
| Mouse + Mouse | Mouse 1 horizontal | Mouse 2 LMB/PCB |
| Mouse + Keyboard | WASD | Mouse LMB/RMB |
| Keyboard + Keyboard | WASD | Arrows + Space/Shift |

Select your mode in Controls menu or at startup.

## Game

- 3 levels, 10 waves each + boss on wave 10
- Eat candy, bugs, butterflies, cakes
- Avoid sharp lollipops, pepper meteors, acid jelly
- Combo sync: both players affect same object = multiplier
- Vortex: magnet + tilt from opposite sides = x3 bonus
- Bonus boxes give: Double Magnet, Slow Time, Auto Mouth, Shield, Beacon
- Defeat all 3 bosses to win!

## License

MIT
