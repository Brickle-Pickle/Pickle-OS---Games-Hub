-- Sequence Tap: tap the nine numbered tiles in order from 1 to 9. Numbers
-- are shuffled in a 3x3 grid each round. Complete as many rounds as possible
-- before time runs out.
local DURATION = 60
local CELL = 70
local GAP = 6
local cols, rows = 3, 3
local grid_w = cols * CELL + (cols - 1) * GAP
local grid_h = rows * CELL + (rows - 1) * GAP
local x0 = (SCREEN_W - grid_w) // 2
local y0 = (SCREEN_H - grid_h) // 2
local positions = {}
local tiles = {}
local labels = {}
local time_left = DURATION
local expected = 1
local function hud()
    game.set_hud("Score: " .. game.score(), time_left .. "s")
end
for i = 1, 9 do
    local c = (i - 1) % cols
    local r = (i - 1) // cols
    positions[i] = { x = x0 + c * (CELL + GAP), y = y0 + r * (CELL + GAP) }
    local b = lvgl.create_button(positions[i].x, positions[i].y, CELL, CELL,
        game.theme("primary_dark"))
    lvgl.set_radius(b, 10)
    tiles[i] = b
    local lbl = lvgl.create_label("?",
        positions[i].x + CELL // 2 - 6, positions[i].y + CELL // 2 - 12, "large")
    labels[i] = lbl
end
local order = {}
local function shuffle_round()
    expected = 1
    for i = 1, 9 do order[i] = i end
    for i = 9, 2, -1 do
        local j = game.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
    for i = 1, 9 do
        lvgl.set_text(labels[i], tostring(order[i]))
        lvgl.set_color(tiles[i], game.theme("primary_dark"))
    end
end
for i = 1, 9 do
    lvgl.on_tap(tiles[i], function()
        if order[i] == expected then
            lvgl.set_color(tiles[i], game.theme("secondary"))
            expected = expected + 1
            if expected > 9 then
                game.add_score(1)
                hud()
                shuffle_round()
            end
        else
            game.toast("Wrong order", "alert")
        end
    end)
end
game.timer(1000, true, function()
    time_left = time_left - 1
    hud()
    if time_left <= 0 then game.finish() end
end)
game.set_score(0)
hud()
shuffle_round()
