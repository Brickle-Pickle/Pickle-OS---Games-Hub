-- Quick Tap: tap the moving target before it vanishes.
-- One point per successful tap; the target lifetime shrinks as the score
-- grows, making the game progressively harder. The round ends after 30s.
local DURATION = 30
local TARGET_SZ = 56
local LIFE_START = 1300
local LIFE_DECAY = 25
local LIFE_FLOOR = 500
local time_left = DURATION
local target = nil
local function update_hud()
    game.set_hud("Score: " .. game.score(), time_left .. "s")
end
local function spawn_target()
    if target then lvgl.destroy(target); target = nil end
    local x = game.random(8, SCREEN_W - TARGET_SZ - 8)
    local y = game.random(8, SCREEN_H - TARGET_SZ - 8)
    target = lvgl.create_button(x, y, TARGET_SZ, TARGET_SZ, game.theme("primary"))
    lvgl.set_radius(target, 999)
    lvgl.on_tap(target, function()
        game.add_score(1)
        update_hud()
        spawn_target()
    end)
    local life = LIFE_START - game.score() * LIFE_DECAY
    if life < LIFE_FLOOR then life = LIFE_FLOOR end
    game.timer(life, false, function()
        if target then spawn_target() end
    end)
end
game.timer(1000, true, function()
    time_left = time_left - 1
    update_hud()
    if time_left <= 0 then
        if target then lvgl.destroy(target); target = nil end
        game.finish()
    end
end)
game.set_score(0)
update_hud()
spawn_target()
