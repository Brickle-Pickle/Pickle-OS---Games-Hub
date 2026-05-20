-- Bubble Pop: a bubble grows from a small dot. Tap it before it explodes.
-- A pop scores by remaining headroom; missing it ends the game.
local START = 24
local MAX = 140
local STEP = 4
local TICK_MS = 100
local bubble = nil
local size = START
local cx, cy = 0, 0
local lives = 3
local function hud()
    game.set_hud("Score: " .. game.score(), "Lives: " .. lives)
end
local function clear_bubble()
    if bubble then
        lvgl.destroy(bubble)
        bubble = nil
    end
end
local function spawn()
    clear_bubble()
    size = START
    local margin = MAX // 2 + 8
    cx = game.random(margin, SCREEN_W - margin)
    cy = game.random(margin, SCREEN_H - margin)
    bubble = lvgl.create_button(cx - size // 2, cy - size // 2, size, size,
        game.theme("primary"))
    lvgl.set_radius(bubble, 999)
    lvgl.on_tap(bubble, function()
        if not bubble then return end
        local gained = math.max(1, (MAX - size) // 8)
        game.add_score(gained)
        hud()
        spawn()
    end)
end
game.timer(TICK_MS, true, function()
    if not bubble then return end
    size = size + STEP
    if size >= MAX then
        clear_bubble()
        lives = lives - 1
        hud()
        if lives <= 0 then
            game.finish()
            return
        end
        spawn()
        return
    end
    lvgl.set_size(bubble, size, size)
    lvgl.set_pos(bubble, cx - size // 2, cy - size // 2)
end)
game.set_score(0)
hud()
spawn()
