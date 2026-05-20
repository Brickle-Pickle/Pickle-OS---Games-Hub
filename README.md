# Pickle OS Game Store

Backend that serves downloadable mini-games to the Pickle OS device. Each game is shipped as a manifest plus a Lua script that the device executes through an embedded Lua 5.4 runtime. New games are added by dropping a folder under `games/` with a `manifest.json` and a `game.lua`, no firmware update required.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Service info |
| GET | `/api/games` | List all available games (lightweight summary) |
| GET | `/api/games/:id` | Full manifest for a single game |
| GET | `/api/games/:id/files/:filename` | Download a file from a game folder |

## Game manifest format

```json
{
    "id": "quick-tap",
    "name": "Quick Tap",
    "author": "Brickle Pickle",
    "version": "1.0.0",
    "entry": "game.lua",
    "icon": "play",
    "description": "Tap targets before they vanish."
}
```

The `entry` field names the Lua script that the device downloads alongside the manifest and runs through the embedded runtime. `icon` is a logical name mapped to an `LV_SYMBOL_*` glyph on the device. Allowed values: `play`, `list`, `eye_open`, `ok`, `bell`, `bullet`, `home`, `image`, `file`, `settings`, `refresh`, `download`.

## Lua runtime API

A downloaded script can access three globals: `lvgl` (widget primitives), `canvas` (low level drawing) and `game` (control flow such as scoring, timers, HUD, game over). The exact bindings live in `pickle-os-gui/src/scripting/lua_engine.cpp`.

## Local development

```bash
cd backend
npm install
npm start
# server listens on http://localhost:3000
```

Open `http://localhost:3000/api/games` to see the list.

## Deploy to Render

1. Push this repository to GitHub.
2. In the [Render dashboard](https://dashboard.render.com), click `New > Web Service` and connect the GitHub repo.
3. Configure the service:
    - Root Directory: `backend`
    - Runtime: `Node`
    - Build Command: `npm install`
    - Start Command: `npm start`
    - Instance Type: `Free`
4. Click `Create Web Service`. Render builds and deploys automatically.
5. Once live, copy the public URL (for example `https://pickle-os-game-store.onrender.com`) and set it on the device:
    - `/pickle-os/sys/config.txt` on the SD card: `game_server=https://your-service.onrender.com`
    - Or change the default in `src/network/game_api.h` (`PICKLE_GAME_SERVER_DEFAULT`).

The included [`render.yaml`](render.yaml) Blueprint lets you skip steps 3 and 4: use `New > Blueprint` in Render, point it at the repo, and the service is created with the right settings.

> Render free instances sleep after 15 minutes of inactivity. The first request after sleep takes around 30 seconds to wake. The device tolerates this thanks to the long HTTP timeout plus the refresh button.

## Adding a new game

1. Create `games/<id>/manifest.json` following the example above.
2. Add a `game.lua` (or whatever name you set in `entry`) with the script logic.
3. Commit and redeploy. The device sees the new game on its next store refresh.
