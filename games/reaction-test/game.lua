-- Reaction Test: when the panel turns green, tap as fast as possible.
-- Five rounds. Total milliseconds wins (lower is better). Tapping early adds
-- a penalty so you cannot cheat by spamming.
local ROUNDS = 5
local WAIT_MIN = 1200
local WAIT_MAX = 4000
local PENALTY = 2000
local round = 0
local total = 0
local armed = false
local arm_at = 0
local panel = lvgl.create_button(10, 20, 220, 180, game.theme("error"))
lvgl.set_radius(panel, 12)
local msg = lvgl.create_label("Wait for green...", 0, 220, "normal")
lvgl.set_size(msg, SCREEN_W, 24)
lvgl.set_pos(msg, 0, 220)
local function hud()
    game.set_hud("Round " .. (round) .. "/" .. ROUNDS, total .. " ms")
end
local function next_round()
    if round >= ROUNDS then
        game.set_score(math.max(1, 100000 // math.max(total, 1)))
        game.finish()
        return
    end
    armed = false
    lvgl.set_color(panel, game.theme("error"))
    lvgl.set_text(msg, "Wait for green...")
    local delay = game.random(WAIT_MIN, WAIT_MAX)
    game.timer(delay, false, function()
        armed = true
        arm_at = game.now()
        lvgl.set_color(panel, game.theme("success"))
        lvgl.set_text(msg, "TAP NOW")
    end)
end
lvgl.on_tap(panel, function()
    if not armed then
        total = total + PENALTY
        lvgl.set_text(msg, "Too early. +" .. PENALTY .. " ms")
        hud()
        return
    end
    local dt = game.now() - arm_at
    total = total + dt
    round = round + 1
    game.toast(dt .. " ms", "success")
    hud()
    next_round()
end)
round = 1
hud()
next_round()
