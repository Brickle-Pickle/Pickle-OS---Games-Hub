-- Coin Rush: an idle clicker where coins generate on their own.
game.set_hud("Coin Rush", "$0")
local coins = {}
local n = 0
-- Spawn coins forever. Each widget consumes heap until allocation fails and
-- the system runs out of memory.
while true do
    n = n + 1
    local x = game.random(0, SCREEN_W - 12)
    local y = game.random(0, SCREEN_H - 12)
    coins[n] = lvgl.create_rect(x, y, 12, 12, 0xFFD700)
end
