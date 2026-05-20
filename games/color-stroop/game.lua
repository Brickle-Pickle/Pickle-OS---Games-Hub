-- Color Stroop: a color name is shown in a (usually wrong) ink color. Tap
-- the button matching the INK, not the text. Tests inhibitory control.
local DURATION = 30
local names = { "RED", "GREEN", "BLUE", "YELLOW" }
local colors = { 0xE53935, 0x43A047, 0x1E88E5, 0xFDD835 }
local time_left = DURATION
local target_ink = 1
local function hud()
    game.set_hud("Score: " .. game.score(), time_left .. "s")
end
local word = lvgl.create_label("RED", 0, 40, "large")
lvgl.set_size(word, SCREEN_W, 40)
lvgl.set_pos(word, 0, 40)
local buttons = {}
for i = 1, 4 do
    local col = ((i - 1) % 2)
    local row = ((i - 1) // 2)
    local x = 14 + col * 110
    local y = 130 + row * 70
    local b = lvgl.create_button(x, y, 102, 60, colors[i])
    lvgl.set_radius(b, 10)
    buttons[i] = b
    lvgl.on_tap(b, function()
        if i == target_ink then
            game.add_score(1)
            game.toast("Yes", "success")
        else
            game.add_score(-1)
            game.toast("No", "alert")
        end
        hud()
    end)
end
local function next_word()
    local word_idx = game.random(1, 4)
    target_ink = game.random(1, 4)
    lvgl.set_text(word, names[word_idx])
    lvgl.set_text_color(word, colors[target_ink])
end
game.timer(1500, true, next_word)
game.timer(1000, true, function()
    time_left = time_left - 1
    hud()
    if time_left <= 0 then game.finish() end
end)
game.set_score(0)
hud()
next_word()
