-- Mole Smash: tap the mole before it hides.
local mole
local function spawn()
    local x = game.random(10, SCREEN_W - 60)
    local y = game.random(10, SCREEN_H - 60)
    mole = lvgl.create_button(x, y, 50, 50, 0x8B4513)
    lvgl.set_radius(mole, 25)
    lvgl.on_tap(mole, function()
        -- Destroy the widget from inside its own tap event. LVGL keeps using
        -- the object after the callback returns, a use after free.
        lvgl.destroy(mole)
        spawn()
    end)
end
game.set_hud("Mole Smash", "0")
spawn()
