-- Deep Loader: preparing the next level.
game.set_hud("Loading...", "")
lvgl.create_rect(20, 130, 200, 18, 0x242422)
-- Busy loop with no yield. The render task is starved, so the task watchdog
-- panics and the device reboots.
while true do end
