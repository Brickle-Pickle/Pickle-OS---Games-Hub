# Pickle OS Game Store

Backend that serves downloadable mini-games to the Pickle OS device. Each game is a small declarative JSON manifest interpreted by a runtime on the ESP32. New games are added by dropping a folder under `games/` with a `manifest.json` — no firmware update required.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Service info |
| GET | `/api/games` | List all available games (lightweight summary) |
| GET | `/api/games/:id` | Full manifest for a single game |
| GET | `/api/games/:id/files/:filename` | Download an asset file from a game folder |

## Game manifest format

```json
{
    "id": "quick-tap",
    "name": "Quick Tap",
    "author": "Pickle OS Team",
    "version": "1.0.0",
    "type": "tap",
    "icon": "play",
    "description": "Tap targets before they vanish.",
    "config": { ... }
}
```

Supported `type` values (each one is handled by a built-in runtime on the device):

- `tap` — tap moving targets within a time limit
- `quiz` — multiple-choice trivia
- `reaction` — wait for the green light, then tap
- `guess` — number guessing with higher/lower hints

`icon` is a logical name mapped to an `LV_SYMBOL_*` glyph on the device. Allowed values: `play`, `list`, `eye_open`, `ok`, `bell`, `bullet`, `home`, `image`, `file`, `settings`, `refresh`, `download`.

## Local development

```bash
cd backend
npm install
npm start
# server listens on http://localhost:3000
```

Open `http://localhost:3000/api/games` to see the list.

## Deploy to Railway

1. Create a new Railway project from this repo (or push the `backend/` folder as the project root).
2. Railway will pick up `package.json` and `railway.json`, build with Nixpacks, and run `npm start`.
3. Expose the public domain (Railway → Settings → Networking → Generate Domain).
4. Copy the public URL and set it in the device:
    - `/pickle-os/sys/config.txt` on the SD card: `game_server=https://your-app.up.railway.app`
    - Or change the default in `src/network/game_api.h` (`PICKLE_GAME_SERVER_DEFAULT`).

## Adding a new game

1. Create `games/<id>/manifest.json` following one of the existing examples.
2. Optionally add asset files in the same folder — they will be reachable via `/api/games/<id>/files/<filename>`.
3. Commit and redeploy. The device will see the new game on its next store refresh.
