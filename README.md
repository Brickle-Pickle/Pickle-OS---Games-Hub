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
    "author": "Brickle Pickle",
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

## Deploy to Render

1. Push this repository to GitHub.
2. In the [Render dashboard](https://dashboard.render.com), click **New → Web Service** and connect the GitHub repo.
3. Configure the service:
    - **Root Directory**: `backend`
    - **Runtime**: `Node`
    - **Build Command**: `npm install`
    - **Start Command**: `npm start`
    - **Instance Type**: `Free`
4. Click **Create Web Service**. Render builds and deploys automatically.
5. Once live, copy the public URL (e.g. `https://pickle-os-game-store.onrender.com`) and set it on the device:
    - `/pickle-os/sys/config.txt` on the SD card: `game_server=https://your-service.onrender.com`
    - Or change the default in `src/network/game_api.h` (`PICKLE_GAME_SERVER_DEFAULT`).

The included [`render.yaml`](render.yaml) Blueprint lets you skip steps 3-4: use **New → Blueprint** in Render, point it at the repo, and the service is created with the right settings.

> Render's free instances sleep after 15 minutes of inactivity. The first request after sleep takes ~30 s to wake. The device tolerates this thanks to the 8 s HTTP timeout plus retry from the Refresh button — but expect a one-time delay on the first store load.

## Adding a new game

1. Create `games/<id>/manifest.json` following one of the existing examples.
2. Optionally add asset files in the same folder — they will be reachable via `/api/games/<id>/files/<filename>`.
3. Commit and redeploy. The device will see the new game on its next store refresh.
