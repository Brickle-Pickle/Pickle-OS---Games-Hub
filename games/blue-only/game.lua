-- Blue Only: dots of two colors pop up. Tap the blue ones. Tapping a red
-- one or letting a blue one fade away costs a life. Survive as many ticks
-- as possible.
local TICK_MS = 700
local SIZE = 50
local lives = 3
local active = {}
local BLUE = 0x1E88E5
local RED = 0xE53935
local function hud()
    game.set_hud("Score: " .. game.score(), "Lives: " .. lives)
end
local function clear_all()
    for _, e in ipairs(active) do
        if e.btn then lvgl.destroy(e.btn) end
    end
    active = {}
end
local function spawn()
    local count = game.random(2, 4)
    for i = 1, count do
        local x = game.random(8, SCREEN_W - SIZE - 8)
        local y = game.random(8, SCREEN_H - SIZE - 8)
        local is_blue = game.random(0, 1) == 1
        local b = lvgl.create_button(x, y, SIZE, SIZE, is_blue and BLUE or RED)
        lvgl.set_radius(b, 999)
        local entry = { btn = b, blue = is_blue, tapped = false }
        active[#active + 1] = entry
        lvgl.on_tap(b, function()
            if entry.tapped then return end
            entry.tapped = true
            if entry.blue then
                game.add_score(1)
            else
                lives = lives - 1
            end
            hud()
        end)
    end
end
local function fade_check()
    for _, e in ipairs(active) do
        if e.blue and not e.tapped then
            lives = lives - 1
        end
    end
    hud()
    clear_all()
    if lives <= 0 then
        game.finish()
    else
        spawn()
    end
end
game.timer(TICK_MS, true, fade_check)
game.set_score(0)
hud()
spawn()
