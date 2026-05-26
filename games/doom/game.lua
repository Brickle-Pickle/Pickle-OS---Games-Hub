-- DOOM - Raycaster shooter for Pickle OS
-- Single-floor DDA raycaster with imp sprites, a pistol, and a fire button.

local SW = SCREEN_W
local SH = SCREEN_H
local VIEW_H = 168
local HALF_VH = math.floor(VIEW_H / 2)

-- World map. 1=wall, 0=empty. Rows are Y, columns are X.
local MAP_W = 10
local MAP_H = 10
local map = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 1, 0, 0, 0, 0, 1},
    {1, 0, 1, 0, 0, 0, 1, 1, 0, 1},
    {1, 0, 1, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1, 1, 0, 1, 0, 1},
    {1, 0, 1, 0, 0, 0, 0, 1, 0, 1},
    {1, 0, 1, 0, 1, 0, 0, 0, 0, 1},
    {1, 0, 0, 0, 1, 0, 1, 0, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
}

-- Player state. The original game spawned the player on map[1][1] which is a
-- wall, locking every movement attempt. (2.5, 2.5) lands inside the first
-- open room.
local px = 2.5
local py = 2.5
local pa = 0.4
local health = 100
local ammo = 40
local kills = 0

-- Render parameters.
local FOV = 1.05
local NUM_COLS = 48
local COL_W = SW // NUM_COLS
local MOVE_SPEED = 0.25
local TURN_SPEED = 0.22
local PI = math.pi
local TWO_PI = PI * 2

-- Imps. hp falls per hit, alive flips to false on kill.
local enemies = {
    {x = 3.5, y = 5.5, hp = 2, alive = true},
    {x = 6.5, y = 2.5, hp = 2, alive = true},
    {x = 6.5, y = 7.5, hp = 2, alive = true},
    {x = 8.5, y = 4.5, hp = 2, alive = true},
    {x = 2.5, y = 8.5, hp = 2, alive = true},
    {x = 8.5, y = 8.5, hp = 2, alive = true},
}

-- Sky and floor are drawn once, behind everything.
lvgl.create_rect(0, 0, SW, HALF_VH, 0x141422)
lvgl.create_rect(0, HALF_VH, SW, VIEW_H - HALF_VH, 0x1e1a14)

-- One thin rectangle per ray column plus a Lua-side depth buffer used by the
-- sprite z-test below.
local colRects = {}
local colDist = {}
for i = 0, NUM_COLS - 1 do
    colRects[i] = lvgl.create_rect(i * COL_W, 0, COL_W, 1, 0x000000)
    colDist[i] = 1e9
end

-- Pre-allocated imp sprite rects: three layered rects per slot (body, head,
-- eyes) so we never allocate during the render loop.
local enemyRects = {}
for i = 1, #enemies do
    local body = lvgl.create_rect(-10, -10, 1, 1, 0x00aa00)
    local head = lvgl.create_rect(-10, -10, 1, 1, 0x004400)
    local eye  = lvgl.create_rect(-10, -10, 1, 1, 0xff2200)
    enemyRects[i] = {body = body, head = head, eye = eye, hidden = true}
end

local function hideEnemy(i)
    local r = enemyRects[i]
    if r.hidden then return end
    lvgl.set_pos(r.body, -10, -10); lvgl.set_size(r.body, 1, 1)
    lvgl.set_pos(r.head, -10, -10); lvgl.set_size(r.head, 1, 1)
    lvgl.set_pos(r.eye,  -10, -10); lvgl.set_size(r.eye,  1, 1)
    r.hidden = true
end

-- Pistol overlay anchored to the bottom of the view.
local WPN_W = 88
local WPN_H = 38
local WPN_X = (SW - WPN_W) // 2
local WPN_Y = VIEW_H - WPN_H
lvgl.create_rect(WPN_X, WPN_Y, WPN_W, WPN_H, 0x2a2a30)
lvgl.create_rect(WPN_X + 8, WPN_Y + 6, WPN_W - 16, 6, 0x444450)
lvgl.create_rect(SW // 2 - 7, WPN_Y - 22, 14, 24, 0x1a1a20)

-- Muzzle flash sits above the barrel, hidden until a shot fires.
local flash = lvgl.create_rect(SW // 2 - 9, WPN_Y - 34, 18, 14, 0x141422)
local flashAge = 0

-- Crosshair: two thin perpendicular bars over the view center.
lvgl.create_rect(SW // 2 - 5, HALF_VH - 1, 10, 2, 0xff5028)
lvgl.create_rect(SW // 2 - 1, HALF_VH - 5, 2, 10, 0xff5028)

local function wallColor(dist, side)
    local b = 1 - dist / 8.5
    if b < 0.13 then b = 0.13 end
    if side == 1 then b = b * 0.62 end
    local r = math.floor(195 * b)
    local g = math.floor(50 * b)
    local bb = math.floor(22 * b)
    return r * 0x10000 + g * 0x100 + bb
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
        sx = -1; sdx = (px - mx) * ddx
    else
        sx = 1; sdx = (mx + 1 - px) * ddx
    end
    if rs < 0 then
        sy = -1; sdy = (py - my) * ddy
    else
        sy = 1; sdy = (my + 1 - py) * ddy
    end
    local side = 0
    for _ = 1, 24 do
        if sdx < sdy then
            sdx = sdx + ddx; mx = mx + sx; side = 0
        else
            sdy = sdy + ddy; my = my + sy; side = 1
        end
        if mx < 1 or mx > MAP_W or my < 1 or my > MAP_H then
            return 16, 0
        end
        if map[my] and map[my][mx] == 1 then break end
    end
    local d = (side == 0) and (sdx - ddx) or (sdy - ddy)
    if d < 0.05 then d = 0.05 end
    return d, side
end

-- Wrap to (-pi, pi] so cone-of-fire and FOV checks are sign-aware.
local function normAng(a)
    while a < -PI do a = a + TWO_PI end
    while a > PI do a = a - TWO_PI end
    return a
end

local function renderWalls()
    for i = 0, NUM_COLS - 1 do
        local angle = pa - FOV * 0.5 + (i + 0.5) / NUM_COLS * FOV
        local dist, side = castRay(angle)
        local corrected = dist * math.cos(angle - pa)
        colDist[i] = corrected
        local wh = math.floor(VIEW_H / corrected)
        if wh > VIEW_H then wh = VIEW_H end
        local wy = HALF_VH - wh // 2
        if wy < 0 then wy = 0 end
        if wy + wh > VIEW_H then wh = VIEW_H - wy end
        local r = colRects[i]
        lvgl.set_pos(r, i * COL_W, wy)
        lvgl.set_size(r, COL_W, wh)
        lvgl.set_color(r, wallColor(dist, side))
    end
end

local function renderEnemies()
    for i, e in ipairs(enemies) do
        if not e.alive then
            hideEnemy(i)
        else
            local dx = e.x - px
            local dy = e.y - py
            local distRaw = math.sqrt(dx * dx + dy * dy)
            local ang = normAng(math.atan(dy, dx) - pa)
            if math.abs(ang) > FOV * 0.55 or distRaw > 12 then
                hideEnemy(i)
            else
                local corrected = distRaw * math.cos(ang)
                if corrected < 0.2 then
                    hideEnemy(i)
                else
                    local screenX = math.floor((ang + FOV * 0.5) / FOV * SW)
                    local size = math.floor(VIEW_H * 0.75 / corrected)
                    if size > VIEW_H then size = VIEW_H end
                    if size < 6 then size = 6 end
                    -- Center-column z-test against the wall depth buffer.
                    -- Good enough for ESP32: per-slice occlusion would cost
                    -- 6 sprites x 12 LVGL ops every frame.
                    local colIdx = screenX // COL_W
                    if colIdx < 0 then colIdx = 0 end
                    if colIdx >= NUM_COLS then colIdx = NUM_COLS - 1 end
                    if colDist[colIdx] <= corrected then
                        hideEnemy(i)
                    else
                        local bw = size
                        local bh = math.floor(size * 0.92)
                        local bx = screenX - bw // 2
                        local by = HALF_VH + size // 2 - bh
                        if by < 0 then by = 0 end
                        if by + bh > VIEW_H then bh = VIEW_H - by end
                        if bh < 4 then bh = 4 end
                        local shade = 1 - corrected / 11
                        if shade < 0.32 then shade = 0.32 end
                        local body_g = math.floor(180 * shade)
                        local body_r = math.floor(40 * shade)
                        local head_g = math.floor(90 * shade)
                        local eye_r = math.floor(255 * shade)
                        local eye_g = math.floor(70 * shade)
                        local body_color = body_r * 0x10000 + body_g * 0x100
                        local head_color = head_g * 0x100
                        local eye_color = eye_r * 0x10000 + eye_g * 0x100
                        local r = enemyRects[i]
                        local hh = math.floor(bh * 0.34)
                        local body_y = by + hh
                        local body_h = bh - hh
                        local hw = math.floor(bw * 0.62)
                        local hx = screenX - hw // 2
                        lvgl.set_pos(r.body, bx, body_y)
                        lvgl.set_size(r.body, bw, body_h)
                        lvgl.set_color(r.body, body_color)
                        lvgl.set_pos(r.head, hx, by)
                        lvgl.set_size(r.head, hw, hh)
                        lvgl.set_color(r.head, head_color)
                        local ew = math.max(2, bw // 5)
                        local eh = math.max(2, hh // 3)
                        lvgl.set_pos(r.eye, screenX - ew // 2, by + hh // 2 - eh // 2)
                        lvgl.set_size(r.eye, ew, eh)
                        lvgl.set_color(r.eye, eye_color)
                        r.hidden = false
                    end
                end
            end
        end
    end
end

local function setHud()
    game.set_hud(string.format("HP %d  AMMO %d", health, ammo),
                 string.format("%d kills", kills))
end

local function render()
    renderWalls()
    renderEnemies()
    setHud()
end

-- Slide along walls: try axes independently so grazing a corner does not stop
-- the player dead in their tracks.
local function tryMove(dx, dy)
    local nx = px + dx
    local ny = py + dy
    local cx = math.floor(nx)
    local cy = math.floor(py)
    if cx >= 1 and cx <= MAP_W and cy >= 1 and cy <= MAP_H
       and map[cy] and map[cy][cx] == 0 then
        px = nx
    end
    cx = math.floor(px)
    cy = math.floor(ny)
    if cx >= 1 and cx <= MAP_W and cy >= 1 and cy <= MAP_H
       and map[cy] and map[cy][cx] == 0 then
        py = ny
    end
    -- Contact damage from any live imp within bite range.
    for _, e in ipairs(enemies) do
        if e.alive then
            local ddx = e.x - px
            local ddy = e.y - py
            if ddx * ddx + ddy * ddy < 0.55 then
                health = health - 6
                if health < 0 then health = 0 end
            end
        end
    end
    render()
    if health <= 0 then
        game.toast("You died.", "alert")
        game.set_score(kills * 100)
        game.finish()
    end
end

local function fire()
    if ammo <= 0 then
        game.toast("Out of ammo", "alert")
        return
    end
    ammo = ammo - 1
    flashAge = flashAge + 1
    lvgl.set_color(flash, 0xffe060)
    game.timer(90, false, function()
        flashAge = flashAge - 1
        if flashAge <= 0 then
            lvgl.set_color(flash, 0x141422)
        end
    end)
    -- Pick the nearest imp inside a narrow cone that is not occluded by a wall.
    local wallDist = castRay(pa)
    local hit = nil
    local hitDist = wallDist
    for i, e in ipairs(enemies) do
        if e.alive then
            local dx = e.x - px
            local dy = e.y - py
            local d = math.sqrt(dx * dx + dy * dy)
            local ang = math.abs(normAng(math.atan(dy, dx) - pa))
            if ang < 0.18 and d < hitDist then
                hitDist = d
                hit = i
            end
        end
    end
    if hit then
        local e = enemies[hit]
        e.hp = e.hp - 1
        if e.hp <= 0 then
            e.alive = false
            kills = kills + 1
            game.set_score(kills * 100)
            game.toast("Imp down!", "success")
            local any = false
            for _, en in ipairs(enemies) do
                if en.alive then any = true; break end
            end
            if not any then
                game.toast("Stage clear!", "success")
                game.set_score(kills * 100 + health)
                game.finish()
                return
            end
        end
    end
    render()
end

-- Imp AI: every 700 ms an imp shuffles one half-step toward the player along
-- the dominant axis if the next cell is open.
game.timer(700, true, function()
    local moved = false
    for _, e in ipairs(enemies) do
        if e.alive then
            local dx = px - e.x
            local dy = py - e.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d < 7 and d > 0.4 then
                local sx, sy
                if math.abs(dx) > math.abs(dy) then
                    sx = (dx > 0) and 0.22 or -0.22
                    sy = 0
                else
                    sx = 0
                    sy = (dy > 0) and 0.22 or -0.22
                end
                local nx = e.x + sx
                local ny = e.y + sy
                local mx = math.floor(nx)
                local my = math.floor(ny)
                if mx >= 1 and mx <= MAP_W and my >= 1 and my <= MAP_H
                   and map[my] and map[my][mx] == 0 then
                    e.x = nx
                    e.y = ny
                    moved = true
                end
            end
        end
    end
    if moved then render() end
end)

-- Control panel below the view.
local C_BTN = 0x121208
local C_BTN_FIRE = 0x4a1410
local C_TXT = 0xff7a44

local PANEL_Y = VIEW_H + 2
local SIDE_W = 52
local MID_X = SIDE_W + 4
local MID_W = SW - 2 * SIDE_W - 8
local TURN_H = 78
local ROW_H = (TURN_H - 4) // 2

local bL = lvgl.create_button(0, PANEL_Y, SIDE_W, TURN_H, C_BTN)
lvgl.set_radius(bL, 10)
local lblL = lvgl.create_label("<<", SIDE_W // 2 - 10, PANEL_Y + TURN_H // 2 - 10, "large")
lvgl.set_text_color(lblL, C_TXT)

local bF = lvgl.create_button(MID_X, PANEL_Y, MID_W, ROW_H, C_BTN)
lvgl.set_radius(bF, 10)
local lblF = lvgl.create_label("FWD", MID_X + MID_W // 2 - 14, PANEL_Y + ROW_H // 2 - 8, "normal")
lvgl.set_text_color(lblF, C_TXT)

local bB = lvgl.create_button(MID_X, PANEL_Y + ROW_H + 4, MID_W, ROW_H, C_BTN)
lvgl.set_radius(bB, 10)
local lblB = lvgl.create_label("BCK", MID_X + MID_W // 2 - 14, PANEL_Y + ROW_H + 4 + ROW_H // 2 - 8, "normal")
lvgl.set_text_color(lblB, C_TXT)

local bR = lvgl.create_button(SW - SIDE_W, PANEL_Y, SIDE_W, TURN_H, C_BTN)
lvgl.set_radius(bR, 10)
local lblR = lvgl.create_label(">>", SW - SIDE_W + SIDE_W // 2 - 10, PANEL_Y + TURN_H // 2 - 10, "large")
lvgl.set_text_color(lblR, C_TXT)

local FIRE_Y = PANEL_Y + TURN_H + 4
local FIRE_H = SH - FIRE_Y - 2
if FIRE_H < 24 then FIRE_H = 24 end
local bFire = lvgl.create_button(0, FIRE_Y, SW, FIRE_H, C_BTN_FIRE)
lvgl.set_radius(bFire, 10)
local lblFire = lvgl.create_label("FIRE", SW // 2 - 16, FIRE_Y + FIRE_H // 2 - 8, "normal")
lvgl.set_text_color(lblFire, 0xff5028)

lvgl.on_tap(bL, function()
    pa = normAng(pa - TURN_SPEED)
    render()
end)
lvgl.on_tap(bR, function()
    pa = normAng(pa + TURN_SPEED)
    render()
end)
lvgl.on_tap(bF, function()
    tryMove(math.cos(pa) * MOVE_SPEED, math.sin(pa) * MOVE_SPEED)
end)
lvgl.on_tap(bB, function()
    tryMove(-math.cos(pa) * MOVE_SPEED, -math.sin(pa) * MOVE_SPEED)
end)
lvgl.on_tap(bFire, fire)

game.set_score(0)
render()
game.toast("DOOM: clear the imps!", "info")
