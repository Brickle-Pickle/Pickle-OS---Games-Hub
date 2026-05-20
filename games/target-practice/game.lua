-- Target Practice: a target slides across the screen bouncing off the
-- edges. Tap it; every hit slightly speeds the target up.
local DURATION = 30
local SIZE = 48
local FRAME_MS = 40
local time_left = DURATION
local x = SCREEN_W // 2
local y = SCREEN_H // 2
local vx = 4
local vy = 3
local target = lvgl.create_button(x - SIZE // 2, y - SIZE // 2, SIZE, SIZE,
    game.theme("primary"))
lvgl.set_radius(target, 999)
local function hud()
    game.set_hud("Score: " .. game.score(), time_left .. "s")
end
lvgl.on_tap(target, function()
    game.add_score(1)
    if vx > 0 then vx = vx + 1 else vx = vx - 1 end
    if vy > 0 then vy = vy + 1 else vy = vy - 1 end
    hud()
end)
game.timer(FRAME_MS, true, function()
    x = x + vx
    y = y + vy
    if x < SIZE // 2 then x = SIZE // 2; vx = -vx end
    if x > SCREEN_W - SIZE // 2 then x = SCREEN_W - SIZE // 2; vx = -vx end
    if y < SIZE // 2 then y = SIZE // 2; vy = -vy end
    if y > SCREEN_H - SIZE // 2 then y = SCREEN_H - SIZE // 2; vy = -vy end
    lvgl.set_pos(target, x - SIZE // 2, y - SIZE // 2)
end)
game.timer(1000, true, function()
    time_left = time_left - 1
    hud()
    if time_left <= 0 then
        lvgl.destroy(target)
        target = nil
        game.finish()
    end
end)
game.set_score(0)
hud()
