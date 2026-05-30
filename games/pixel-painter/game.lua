-- Pixel Painter: tap a swatch to label its color.
local SWATCH = 0x2D7DD2
local pad = lvgl.create_rect(20, 40, 200, 160, SWATCH)
lvgl.set_radius(pad, 8)
game.set_hud("Pixel Painter", "")
-- A rect is not a label, so the binding casts it to a label and reallocs a
-- wild pointer inside lv_label_set_text, which corrupts the heap.
lvgl.set_text(pad, "blue")
