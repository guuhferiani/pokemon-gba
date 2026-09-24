local Theme = require("src.ui.Theme")

local GbaCartView = {}

-- Cartridge State (rotation, drag, spring physics)
local state = {
  yaw = 0,
  pitch = 0,
  spinVel = 0,
  pitchVel = 0,
  isDragging = false,
  dragStartX = 0,
  dragStartY = 0,
  lastMouseX = 0,
  lastMouseY = 0,
  hoverJuice = 0,
  wasHovered = false,
  sparkleTimer = 0
}

local LABEL_CANVASES = {}

-- Generates a high-res GBA label texture for the specified game
local function getLabelCanvas(game)
  local key = game.id or "firered"
  if LABEL_CANVASES[key] then return LABEL_CANVASES[key] end

  local w, h = 320, 180
  local canvas = love.graphics.newCanvas(w, h)
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)

  -- Gradient / metallic background for label
  local col = game.color or { 230, 70, 40 }
  local accent = game.accent or { 255, 140, 60 }
  for y = 0, h do
    local t = y / h
    local r = (col[1] * (1 - t) + accent[1] * t) / 255
    local g = (col[2] * (1 - t) + accent[2] * t) / 255
    local b = (col[3] * (1 - t) + accent[3] * t) / 255
    love.graphics.setColor(r, g, b, 1)
    love.graphics.line(0, y, w, y)
  end

  -- Diagonal sheen stripes
  love.graphics.setColor(1, 1, 1, 0.08)
  for i = -100, w + 100, 24 do
    love.graphics.polygon("fill", i, 0, i + 12, 0, i - 40, h, i - 52, h)
  end

  -- Left side Pokeball watermark
  love.graphics.setColor(1, 1, 1, 0.15)
  local px, py, pr = 75, h / 2, 58
  love.graphics.circle("line", px, py, pr)
  love.graphics.circle("line", px, py, pr - 1)
  love.graphics.line(px - pr, py, px + pr, py)
  love.graphics.circle("fill", px, py, 16)
  love.graphics.setColor(col[1]/255, col[2]/255, col[3]/255, 1)
  love.graphics.circle("fill", px, py, 9)

  -- Title Text
  love.graphics.setColor(1, 1, 1, 0.95)
  Theme.setFont("header")
  love.graphics.print("POKÉMON", 140, 32)

  local isKJ = (game.id == "kantojohto" or game.short == "K&J")
  local sub = (isKJ and "KANTO & JOHTO")
    or (game.short == "FR" and "FIRE RED")
    or (game.short == "LG" and "LEAF GREEN")
    or (game.short == "E" and "EMERALD")
    or (game.short == "R" and "RUBY")
    or (game.short == "S" and "SAPPHIRE")
    or (game.name:gsub("Pokémon ", ""):upper())

  if isKJ then
    Theme.setFont("header")
    love.graphics.setColor(1, 0.95, 0.45, 1)
    love.graphics.print(sub, 140, 58)
  else
    Theme.setFont("title")
    love.graphics.setColor(1, 0.95, 0.4, 1)
    love.graphics.print(sub, 140, 56)
  end

  Theme.setFont("small")
  love.graphics.setColor(1, 1, 1, 0.85)
  local edition = isKJ and "DEFINITIVE EDITION" or "VERSION"
  love.graphics.print(edition, 142, 90)

  -- Bottom bar with code & Nintendo Seal
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.rectangle("fill", 0, h - 28, w, 28)

  Theme.setFont("micro")
  love.graphics.setColor(1, 1, 1, 0.75)
  love.graphics.print("AGB-" .. (game.code or "BPRE") .. "-USA", 16, h - 20)
  love.graphics.print("© 2004 Game Freak / Nintendo", 160, h - 20)

  -- Rounded border
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("line", 0, 0, w, h, 6, 6)

  love.graphics.setCanvas()
  love.graphics.pop()

  LABEL_CANVASES[key] = canvas
  return canvas
end

-- 3D Projector with camera perspective
local function project(cx, cy, yaw, pitch, x, y, z)
  -- Rotate Yaw around Y
  local cosY, sinY = math.cos(yaw), math.sin(yaw)
  local x1 = x * cosY + z * sinY
  local z1 = -x * sinY + z * cosY

  -- Rotate Pitch around X
  local cosP, sinP = math.cos(pitch), math.sin(pitch)
  local y2 = y * cosP - z1 * sinP
  local z2 = y * sinP + z1 * cosP

  -- Perspective
  local fov = 420
  local factor = fov / (fov + z2)
  return cx + x1 * factor, cy + y2 * factor, z2
end

function GbaCartView.update(dt, x, y, w, h)
  local mx, my = love.mouse.getPosition()
  local isHovered = mx >= x and mx <= x + w and my >= y and my <= y + h

  state.sparkleTimer = state.sparkleTimer + dt

  -- Mouse entering bounce
  if isHovered and not state.wasHovered then
    state.hoverJuice = 1.0
  end
  state.wasHovered = isHovered
  state.hoverJuice = math.max(0, state.hoverJuice - dt * 3.5)

  -- Mouse drag handling
  if love.mouse.isDown(1) then
    if isHovered and not state.isDragging then
      state.isDragging = true
      state.lastMouseX = mx
      state.lastMouseY = my
    end

    if state.isDragging then
      local dx = mx - state.lastMouseX
      local dy = my - state.lastMouseY
      state.yaw = state.yaw + dx * 0.015
      state.pitch = math.max(-0.65, math.min(0.65, state.pitch + dy * 0.010))
      state.spinVel = dx * 0.015
      state.pitchVel = dy * 0.010
      state.lastMouseX = mx
      state.lastMouseY = my
    end
  else
    state.isDragging = false
    -- Spring back to natural upright rest (yaw = 0, pitch = 0)
    local springK = 9.0
    local damping = 0.82
    local targetYaw = 0
    local targetPitch = 0

    local diffYaw = targetYaw - state.yaw
    state.spinVel = (state.spinVel + diffYaw * springK * dt) * damping
    state.yaw = state.yaw + state.spinVel

    local diffPitch = targetPitch - state.pitch
    state.pitchVel = (state.pitchVel + diffPitch * springK * dt) * damping
    state.pitch = state.pitch + state.pitchVel
  end
end

function GbaCartView.draw(x, y, w, h, game)
  local cx = x + w / 2
  local cy = y + h / 2

  local cartW = math.floor(w * 0.88)
  local cartH = math.floor(cartW * 0.58) -- Authentic GBA 1.7:1 landscape aspect
  local halfW = cartW / 2
  local halfH = cartH / 2
  local depth = 16 -- Thickness of cart

  -- Interactive tilt when hovering
  local tiltYaw = state.yaw
  local tiltPitch = state.pitch
  if not state.isDragging and state.wasHovered then
    local mx, my = love.mouse.getPosition()
    tiltYaw = tiltYaw + ((mx - cx) / (w / 2)) * 0.12
    tiltPitch = tiltPitch + ((my - cy) / (h / 2)) * 0.08
  end

  local function p(px, py, pz)
    return project(cx, cy, tiltYaw, tiltPitch, px, py, pz)
  end

  local shellColor = game.color or { 230, 70, 40 }
  local sideColor = {
    math.floor(shellColor[1] * 0.62),
    math.floor(shellColor[2] * 0.62),
    math.floor(shellColor[3] * 0.62)
  }
  local topLipColor = {
    math.floor(shellColor[1] * 0.78),
    math.floor(shellColor[2] * 0.78),
    math.floor(shellColor[3] * 0.78)
  }

  -- 3D Points: Front Face & Back Face
  -- GBA shape: notch steps at the lower sides
  local stepH = halfH * 0.35
  local stepInset = 6
  local topLipH = halfH * 0.32

  -- Front Face points (clockwise from top-left)
  local f_tl = { p(-halfW, -halfH, depth) }
  local f_tr = { p(halfW, -halfH, depth) }
  local f_mr = { p(halfW, halfH - stepH, depth) }
  local f_sr = { p(halfW - stepInset, halfH - stepH, depth) }
  local f_br = { p(halfW - stepInset, halfH, depth) }
  local f_bl = { p(-halfW + stepInset, halfH, depth) }
  local f_sl = { p(-halfW + stepInset, halfH - stepH, depth) }
  local f_ml = { p(-halfW, halfH - stepH, depth) }

  -- Back Face points
  local b_tl = { p(-halfW, -halfH, -depth) }
  local b_tr = { p(halfW, -halfH, -depth) }
  local b_mr = { p(halfW, halfH - stepH, -depth) }
  local b_sr = { p(halfW - stepInset, halfH - stepH, -depth) }
  local b_br = { p(halfW - stepInset, halfH, -depth) }
  local b_bl = { p(-halfW + stepInset, halfH, -depth) }
  local b_sl = { p(-halfW + stepInset, halfH - stepH, -depth) }
  local b_ml = { p(-halfW, halfH - stepH, -depth) }

  -- Normal test for facing (Z component of normal vector)
  local isFacingFront = (f_tr[1] - f_tl[1]) * (f_bl[2] - f_tl[2]) - (f_tr[2] - f_tl[2]) * (f_bl[1] - f_tl[1]) > 0

  -- 1. Draw Back Shell if facing front (or front shell if facing back)
  if isFacingFront then
    Theme.col(sideColor, 1)
    love.graphics.polygon("fill",
      b_tl[1], b_tl[2], b_tr[1], b_tr[2], b_mr[1], b_mr[2],
      b_sr[1], b_sr[2], b_br[1], b_br[2], b_bl[1], b_bl[2],
      b_sl[1], b_sl[2], b_ml[1], b_ml[2]
    )
  end

  -- 2. Draw Side Walls (Extrusions)
  local function drawWall(p1, p2, p3, p4, col)
    Theme.col(col or sideColor, 1)
    love.graphics.polygon("fill", p1[1], p1[2], p2[1], p2[2], p3[1], p3[2], p4[1], p4[2])
    Theme.col(Theme.PAL.black, 0.35)
    love.graphics.polygon("line", p1[1], p1[2], p2[1], p2[2], p3[1], p3[2], p4[1], p4[2])
  end

  -- Top wall
  drawWall(f_tl, f_tr, b_tr, b_tl, topLipColor)
  -- Right upper wall
  drawWall(f_tr, f_mr, b_mr, b_tr, sideColor)
  -- Right step wall
  drawWall(f_mr, f_sr, b_sr, b_mr, sideColor)
  -- Right lower wall
  drawWall(f_sr, f_br, b_br, b_sr, sideColor)
  -- Bottom wall
  drawWall(f_br, f_bl, b_bl, b_br, sideColor)
  -- Left lower wall
  drawWall(f_bl, f_sl, b_sl, b_bl, sideColor)
  -- Left step wall
  drawWall(f_sl, f_ml, b_ml, b_sl, sideColor)
  -- Left upper wall
  drawWall(f_ml, f_tl, b_tl, b_ml, sideColor)

  -- 3. Draw Main Face
  if isFacingFront then
    -- Front Shell
    Theme.col(shellColor, 0.96)
    love.graphics.polygon("fill",
      f_tl[1], f_tl[2], f_tr[1], f_tr[2], f_mr[1], f_mr[2],
      f_sr[1], f_sr[2], f_br[1], f_br[2], f_bl[1], f_bl[2],
      f_sl[1], f_sl[2], f_ml[1], f_ml[2]
    )
    Theme.col(Theme.PAL.black, 0.5)
    love.graphics.polygon("line",
      f_tl[1], f_tl[2], f_tr[1], f_tr[2], f_mr[1], f_mr[2],
      f_sr[1], f_sr[2], f_br[1], f_br[2], f_bl[1], f_bl[2],
      f_sl[1], f_sl[2], f_ml[1], f_ml[2]
    )

    -- Top Grip Inset: "GAME BOY ADVANCE" Emboss Bar
    local lipW = halfW * 0.72
    local lipT = -halfH + 3
    local lipB = -halfH + topLipH - 2
    local l1 = { p(-lipW, lipT, depth + 1) }
    local l2 = { p(lipW, lipT, depth + 1) }
    local l3 = { p(lipW, lipB, depth + 1) }
    local l4 = { p(-lipW, lipB, depth + 1) }

    Theme.col(topLipColor, 1)
    love.graphics.polygon("fill", l1[1], l1[2], l2[1], l2[2], l3[1], l3[2], l4[1], l4[2])
    Theme.col(Theme.PAL.black, 0.4)
    love.graphics.polygon("line", l1[1], l1[2], l2[1], l2[2], l3[1], l3[2], l4[1], l4[2])

    -- Embossed Text
    local textPos = { p(0, (lipT + lipB) / 2, depth + 2) }
    Theme.setFont("micro")
    Theme.col(Theme.PAL.black, 0.6)
    love.graphics.print("GAME BOY ADVANCE", textPos[1] - 48, textPos[2] - 5)
    Theme.col(Theme.PAL.white, 0.35)
    love.graphics.print("GAME BOY ADVANCE", textPos[1] - 49, textPos[2] - 6)

    -- Cartridge Label (Centered Landscape Rectangle with Mesh Texture)
    local lblInsetX = 14
    local lblTop = -halfH + topLipH + 4
    local lblBottom = halfH - 8
    local lblW = halfW - lblInsetX

    local lbl_tl = { p(-lblW, lblTop, depth + 1) }
    local lbl_tr = { p(lblW, lblTop, depth + 1) }
    local lbl_br = { p(lblW, lblBottom, depth + 1) }
    local lbl_bl = { p(-lblW, lblBottom, depth + 1) }

    local labelImg = getLabelCanvas(game)
    local mesh = love.graphics.newMesh({
      { lbl_tl[1], lbl_tl[2], 0, 0, 255, 255, 255, 255 },
      { lbl_tr[1], lbl_tr[2], 1, 0, 255, 255, 255, 255 },
      { lbl_br[1], lbl_br[2], 1, 1, 255, 255, 255, 255 },
      { lbl_bl[1], lbl_bl[2], 0, 1, 255, 255, 255, 255 },
    }, "fan", "dynamic")
    mesh:setTexture(labelImg)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mesh)

    -- Dynamic holographic sheen sweep across the label
    local sweep = (state.sparkleTimer * 0.8 + tiltYaw * 1.5) % 2.0
    if sweep > 0 and sweep < 1.2 then
      local sx = -lblW + sweep * (lblW * 2)
      local s1 = { p(sx - 20, lblTop, depth + 2) }
      local s2 = { p(sx + 15, lblTop, depth + 2) }
      local s3 = { p(sx + 5, lblBottom, depth + 2) }
      local s4 = { p(sx - 30, lblBottom, depth + 2) }
      Theme.col(Theme.PAL.white, 0.22)
      love.graphics.polygon("fill", s1[1], s1[2], s2[1], s2[2], s3[1], s3[2], s4[1], s4[2])
    end

    -- Label border
    Theme.col(Theme.PAL.black, 0.5)
    love.graphics.polygon("line", lbl_tl[1], lbl_tl[2], lbl_tr[1], lbl_tr[2], lbl_br[1], lbl_br[2], lbl_bl[1], lbl_bl[2])

  else
    -- Back Shell Details (When flipped)
    Theme.col(shellColor, 0.96)
    love.graphics.polygon("fill",
      b_tl[1], b_tl[2], b_tr[1], b_tr[2], b_mr[1], b_mr[2],
      b_sr[1], b_sr[2], b_br[1], b_br[2], b_bl[1], b_bl[2],
      b_sl[1], b_sl[2], b_ml[1], b_ml[2]
    )

    -- Central Security Screw
    local screwCenter = { p(0, -10, -depth - 1) }
    Theme.col({ 60, 60, 65 }, 1)
    love.graphics.circle("fill", screwCenter[1], screwCenter[2], 9)
    Theme.col({ 195, 195, 195 }, 1)
    love.graphics.circle("fill", screwCenter[1], screwCenter[2], 7)
    -- Screw threads
    Theme.col({ 80, 80, 80 }, 1)
    love.graphics.line(screwCenter[1] - 4, screwCenter[2], screwCenter[1] + 4, screwCenter[2])

    -- Nintendo text on rear
    local ninPos = { p(0, -halfH + 18, -depth - 1) }
    Theme.setFont("micro")
    Theme.col(Theme.PAL.black, 0.7)
    love.graphics.print("Nintendo", ninPos[1] - 18, ninPos[2])
    love.graphics.print("MODEL NO. AGB-002", ninPos[1] - 42, ninPos[2] + 12)
  end

  -- Hint under cart
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 0.75)
  love.graphics.printf("(Arraste com o mouse para girar o cartucho em 3D)", x, y + h - 18, w, "center")
end

return GbaCartView
