-- Odd One Out: nine tiles, one is a slightly lighter shade. Tap it to score.
-- Each correct answer shrinks the contrast, making subsequent rounds harder.
local DURATION = 45
local COLS = 3
local ROWS = 3
local SIZE = 60
local GAP = 6
local time_left = DURATION
local tiles = {}
local odd = 1
local delta = 60
local base_r, base_g, base_b = 0x2D, 0x7D, 0xD2
local next_round
local function hud()
    game.set_hud("Score: " .. game.score(), time_left .. "s")
end
local function pack(r, g, b)
    return r * 0x10000 + g * 0x100 + b
end
local function clamp(v)
    if v < 0 then return 0 end
    if v > 255 then return 255 end
    return v
end
local total = COLS * ROWS
local grid_w = COLS * SIZE + (COLS - 1) * GAP
local grid_h = ROWS * SIZE + (ROWS - 1) * GAP
local x0 = (SCREEN_W - grid_w) // 2
local y0 = 20
for i = 1, total do
    local c = (i - 1) % COLS
    local r = (i - 1) // COLS
    local b = lvgl.create_button(x0 + c * (SIZE + GAP), y0 + r * (SIZE + GAP),
        SIZE, SIZE, pack(base_r, base_g, base_b))
    lvgl.set_radius(b, 8)
    tiles[i] = b
    lvgl.on_tap(b, function()
        if i == odd then
            game.add_score(1)
            if delta > 8 then delta = delta - 4 end
            hud()
            next_round()
        else
            game.toast("Wrong", "alert")
        end
    end)
end
next_round = function()
    odd = game.random(1, total)
    for i = 1, total do
        lvgl.set_color(tiles[i], pack(base_r, base_g, base_b))
    end
    lvgl.set_color(tiles[odd], pack(clamp(base_r + delta),
        clamp(base_g + delta), clamp(base_b + delta)))
end
game.timer(1000, true, function()
    time_left = time_left - 1
    hud()
    if time_left <= 0 then game.finish() end
end)
game.set_score(0)
hud()
next_round()
