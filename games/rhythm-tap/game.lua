-- Rhythm Tap: the central pad flashes on a beat. Tap during the flash to
-- score. Tapping off-beat or missing a beat breaks the streak.
local ROUNDS = 20
local BEAT_MS = 900
local WINDOW_MS = 350
local rounds_left = ROUNDS
local flash_at = 0
local consumed = false
local streak = 0
local pad = lvgl.create_button(40, 60, 160, 160, game.theme("primary_dark"))
lvgl.set_radius(pad, 16)
local msg = lvgl.create_label("Get ready...", 0, 240, "normal")
lvgl.set_size(msg, SCREEN_W, 24)
lvgl.set_pos(msg, 0, 240)
local function hud()
    game.set_hud("Score: " .. game.score(), "Streak: " .. streak)
end
local function on_beat()
    if rounds_left <= 0 then
        game.finish()
        return
    end
    rounds_left = rounds_left - 1
    flash_at = game.now()
    consumed = false
    lvgl.set_color(pad, game.theme("secondary"))
    lvgl.set_text(msg, "TAP")
    game.timer(WINDOW_MS, false, function()
        lvgl.set_color(pad, game.theme("primary_dark"))
        lvgl.set_text(msg, "Wait...")
        if not consumed then
            streak = 0
            hud()
            game.toast("Missed", "alert")
        end
    end)
end
lvgl.on_tap(pad, function()
    local dt = game.now() - flash_at
    if consumed then return end
    if dt >= 0 and dt <= WINDOW_MS then
        consumed = true
        streak = streak + 1
        local bonus = 1 + streak // 5
        game.add_score(bonus)
        hud()
    else
        streak = 0
        hud()
        game.toast("Off-beat", "alert")
    end
end)
game.timer(BEAT_MS, true, on_beat)
game.set_score(0)
hud()
