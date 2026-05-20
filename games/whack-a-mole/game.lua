-- Whack a Mole: a mole pops out of one of nine holes; tap it before it hides.
local DURATION = 30
local POP_MS = 800
local CELL = 70
local GAP = 6
local cols, rows = 3, 3
local grid_w = cols * CELL + (cols - 1) * GAP
local grid_h = rows * CELL + (rows - 1) * GAP
local x0 = (SCREEN_W - grid_w) // 2
local y0 = (SCREEN_H - grid_h) // 2
local holes = {}
local active = nil
local time_left = DURATION
local function hud()
    game.set_hud("Score: " .. game.score(), time_left .. "s")
end
local function hide()
    if active then
        lvgl.set_color(active, game.theme("background_popup"))
        active = nil
    end
end
local function pop()
    hide()
    active = holes[game.random(1, #holes)]
    lvgl.set_color(active, game.theme("secondary"))
end
for r = 0, rows - 1 do
    for c = 0, cols - 1 do
        local x = x0 + c * (CELL + GAP)
        local y = y0 + r * (CELL + GAP)
        local h = lvgl.create_button(x, y, CELL, CELL, game.theme("background_popup"))
        lvgl.set_radius(h, 10)
        holes[#holes + 1] = h
        lvgl.on_tap(h, function()
            if h == active then
                game.add_score(1)
                hud()
                hide()
            end
        end)
    end
end
game.timer(POP_MS, true, pop)
game.timer(1000, true, function()
    time_left = time_left - 1
    hud()
    if time_left <= 0 then
        hide()
        game.finish()
    end
end)
game.set_score(0)
hud()
pop()
