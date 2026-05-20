import express from "express";
import cors from "cors";
import morgan from "morgan";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const GAMES_DIR = path.resolve(__dirname, "..", "games");
const PORT = process.env.PORT || 3000;

const app = express();
app.use(cors());
app.use(morgan("tiny"));
app.use(express.json());

function loadGame(id) {
    const manifestPath = path.join(GAMES_DIR, id, "manifest.json");
    if (!fs.existsSync(manifestPath)) return null;
    try {
        const raw = fs.readFileSync(manifestPath, "utf8");
        return JSON.parse(raw);
    } catch (err) {
        console.error(`[store] failed to parse ${id}/manifest.json`, err);
        return null;
    }
}

function listGames() {
    if (!fs.existsSync(GAMES_DIR)) return [];
    return fs.readdirSync(GAMES_DIR, { withFileTypes: true })
        .filter((d) => d.isDirectory())
        .map((d) => loadGame(d.name))
        .filter(Boolean);
}

function safeJoin(base, target) {
    const resolved = path.resolve(base, target);
    if (!resolved.startsWith(path.resolve(base) + path.sep)) return null;
    return resolved;
}

app.get("/", (req, res) => {
    res.json({
        service: "pickle-os-game-store",
        version: "1.0.0",
        endpoints: [
            "GET /api/games",
            "GET /api/games/:id",
            "GET /api/games/:id/files/:filename"
        ]
    });
});

app.get("/api/games", (req, res) => {
    const games = listGames().map((g) => ({
        id: g.id,
        name: g.name,
        author: g.author,
        version: g.version,
        type: g.type,
        icon: g.icon,
        description: g.description,
        size: JSON.stringify(g).length
    }));
    res.json({ count: games.length, games });
});

app.get("/api/games/:id", (req, res) => {
    const game = loadGame(req.params.id);
    if (!game) return res.status(404).json({ error: "game not found" });
    res.json(game);
});

app.get("/api/games/:id/files/:filename", (req, res) => {
    const gameDir = path.join(GAMES_DIR, req.params.id);
    if (!fs.existsSync(gameDir)) return res.status(404).json({ error: "game not found" });
    const filePath = safeJoin(gameDir, req.params.filename);
    if (!filePath || !fs.existsSync(filePath)) {
        return res.status(404).json({ error: "file not found" });
    }
    res.sendFile(filePath);
});

app.listen(PORT, () => {
    console.log(`[store] Pickle OS game store listening on port ${PORT}`);
    console.log(`[store] Games directory: ${GAMES_DIR}`);
    const games = listGames();
    console.log(`[store] Loaded ${games.length} game(s): ${games.map((g) => g.id).join(", ")}`);
});
