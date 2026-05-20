-- Falling Coins: gold coins fall from the top. Tap a coin to catch it.
-- Letting three coins reach the bottom ends the round.
local SPAWN_MS = 700
local FRAME_MS = 50
local SIZE = 36
local SPEED_BASE = 4
local missed = 0
local coins = {}
local function hud()
    game.set_hud("Score: " .. game.score(), "Missed: " .. missed .. "/3")
end
local function spawn()
    local x = game.random(8, SCREEN_W - SIZE - 8)
    local speed = SPEED_BASE + math.min(game.score() // 5, 8)
    local b = lvgl.create_button(x, -SIZE, SIZE, SIZE, 0xFDD835)
    lvgl.set_radius(b, 999)
    local entry = { btn = b, x = x, y = -SIZE, speed = speed, alive = true }
    coins[#coins + 1] = entry
    lvgl.on_tap(b, function()
        if not entry.alive then return end
        entry.alive = false
        lvgl.destroy(b)
        entry.btn = nil
        game.add_score(1)
        hud()
    end)
end
game.timer(SPAWN_MS, true, spawn)
game.timer(FRAME_MS, true, function()
    for _, c in ipairs(coins) do
        if c.alive then
            c.y = c.y + c.speed
            if c.y > SCREEN_H then
                c.alive = false
                if c.btn then lvgl.destroy(c.btn); c.btn = nil end
                missed = missed + 1
                hud()
                if missed >= 3 then
                    game.finish()
                    return
                end
            elseif c.btn then
                lvgl.set_pos(c.btn, c.x, c.y)
            end
        end
    end
end)
game.set_score(0)
hud()
