-- NOT DOOM - Raycaster for Pickle OS
-- A DDA raycaster running 100% in Lua on the ESP32.
-- Every OS must run Doom. This is close enough.

local SW = SCREEN_W
local SH = SCREEN_H
local VIEW_H = 196
local HALF_VH = math.floor(VIEW_H / 2)

-- Map: rows=Y, cols=X. 1=wall, 0=empty, 2=secret room.
local MAP_W = 10
local MAP_H = 10
local map = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 1, 1, 0, 0, 1, 0, 0, 1},
    {1, 0, 1, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 1, 0, 1, 0, 1},
    {1, 0, 0, 1, 0, 0, 0, 1, 0, 1},
    {1, 0, 0, 1, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 0, 1, 1, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

-- Player state
local px = 1.5
local py = 1.5
local pa = 0.5
local FOV = 1.1
local NUM_COLS = 48
local COL_W = math.floor(SW / NUM_COLS)

-- Button layout constants
local CY1 = VIEW_H + 8
local BH = 38
local CY2 = CY1 + BH + 4
local BW_SIDE = 72
local BW_MID = SW - (BW_SIDE * 2) - 8
local C_BTN = 0x0a1a0a
local C_TXT = 0x00ff88

-- Movement constants
local MOVE_SPEED = 0.28
local TURN_SPEED = 0.22

-- Score: steps taken (explorer metric)
local steps = 0

local function wallColor(dist, side)
    local b = math.floor(220 * math.max(0, 1 - dist / 7))
    if side == 0 then
        return b * 0x100
    end
    return b * 0x100 + math.floor(b * 0.5)
end

local function castRay(angle)
    local rc = math.cos(angle)
    local rs = math.sin(angle)
    local mx = math.floor(px)
    local my = math.floor(py)
    local ddx = (rc == 0) and 1e9 or math.abs(1 / rc)
    local ddy = (rs == 0) and 1e9 or math.abs(1 / rs)
    local sx, sdx, sy, sdy
    if rc < 0 then
        sx = -1
        sdx = (px - mx) * ddx
    else
        sx = 1
        sdx = (mx + 1.0 - px) * ddx
    end
    if rs < 0 then
        sy = -1
        sdy = (py - my) * ddy
    else
        sy = 1
        sdy = (my + 1.0 - py) * ddy
    end
    local side = 0
    for _ = 1, 20 do
        if sdx < sdy then
            sdx = sdx + ddx
            mx = mx + sx
            side = 0
        else
            sdy = sdy + ddy
            my = my + sy
            side = 1
        end
        if mx < 1 or mx > MAP_W or my < 1 or my > MAP_H then
            return 12, 0
        end
        if map[my] and map[my][mx] == 1 then
            break
        end
    end
    local d = (side == 0) and (sdx - ddx) or (sdy - ddy)
    if d < 0.05 then
        d = 0.05
    end
    return d, side
end

local function render()
    canvas.draw_rect(0, 0, SW, HALF_VH, 0x060614)
    canvas.draw_rect(0, HALF_VH, SW, HALF_VH, 0x0f0f08)
    for i = 0, NUM_COLS - 1 do
        local angle = pa - FOV * 0.5 + (i + 0.5) / NUM_COLS * FOV
        local dist, side = castRay(angle)
        local corrected = dist * math.cos(angle - pa)
        local wh = math.floor(VIEW_H / corrected)
        if wh > VIEW_H then
            wh = VIEW_H
        end
        local wy = math.floor(HALF_VH - wh / 2)
        if wy < 0 then
            wy = 0
        end
        if wy + wh > VIEW_H then
            wh = VIEW_H - wy
        end
        canvas.draw_rect(i * COL_W, wy, COL_W, wh, wallColor(dist, side))
    end
    game.set_hud("NOT DOOM", string.format("%d steps", steps))
end

local function tryMove(dx, dy)
    local nx = px + dx
    local ny = py + dy
    local mx = math.floor(nx)
    local my = math.floor(ny)
    if mx >= 1 and mx <= MAP_W and my >= 1 and my <= MAP_H then
        if map[my] and map[my][mx] == 0 then
            px = nx
            py = ny
            steps = steps + 1
            game.set_score(steps)
        end
    end
    render()
end

-- Canvas covers the 3D viewport
canvas.create(0, 0, SW, VIEW_H)
render()

-- Left turn button (spans both rows)
local bL = lvgl.create_button(0, CY1, BW_SIDE, BH * 2 + 4, C_BTN)
lvgl.set_radius(bL, 12)
local lblL = lvgl.create_label("<<", 16, CY1 + BH - 10, "large")
lvgl.set_text_color(lblL, C_TXT)

-- Forward button (top center)
local bF = lvgl.create_button(BW_SIDE + 4, CY1, BW_MID, BH, C_BTN)
lvgl.set_radius(bF, 12)
local lblF = lvgl.create_label("FWD", BW_SIDE + 4 + math.floor(BW_MID / 2) - 16, CY1 + 10, "normal")
lvgl.set_text_color(lblF, C_TXT)

-- Backward button (bottom center)
local bB = lvgl.create_button(BW_SIDE + 4, CY2, BW_MID, BH, C_BTN)
lvgl.set_radius(bB, 12)
local lblB = lvgl.create_label("BCK", BW_SIDE + 4 + math.floor(BW_MID / 2) - 16, CY2 + 10, "normal")
lvgl.set_text_color(lblB, C_TXT)

-- Right turn button (spans both rows)
local bR = lvgl.create_button(BW_SIDE + 4 + BW_MID + 4, CY1, BW_SIDE, BH * 2 + 4, C_BTN)
lvgl.set_radius(bR, 12)
local lblR = lvgl.create_label(">>", BW_SIDE + 4 + BW_MID + 4 + 16, CY1 + BH - 10, "large")
lvgl.set_text_color(lblR, C_TXT)

lvgl.on_tap(bL, function()
    pa = pa - TURN_SPEED
    render()
end)

lvgl.on_tap(bR, function()
    pa = pa + TURN_SPEED
    render()
end)

lvgl.on_tap(bF, function()
    tryMove(math.cos(pa) * MOVE_SPEED, math.sin(pa) * MOVE_SPEED)
end)

lvgl.on_tap(bB, function()
    tryMove(-math.cos(pa) * MOVE_SPEED, -math.sin(pa) * MOVE_SPEED)
end)

game.toast("NOT DOOM loaded. rip and tear.", "info")
