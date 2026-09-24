local Theme = require("src.ui.Theme")
local Kit = require("src.ui.Kit")

local GameHUD = {}
GameHUD.__index = GameHUD

function GameHUD.new()
  local hud = {
    locationName = "CIDADE DE PALLET",
    locationDesc = "Cidade das sombras do seu destino",
    bannerTimer = 4.0,
    bannerAlpha = 1.0,
    toastMsg = nil,
    toastTimer = 0.0
  }
  setmetatable(hud, GameHUD)
  return hud
end

function GameHUD:showBanner(name, desc)
  self.locationName = name or self.locationName
  self.locationDesc = desc or self.locationDesc
  self.bannerTimer = 4.5
end

function GameHUD:showToast(msg, duration)
  self.toastMsg = msg
  self.toastTimer = duration or 3.0
end

function GameHUD:update(dt)
  if self.bannerTimer > 0 then
    self.bannerTimer = self.bannerTimer - dt
    if self.bannerTimer < 1.0 then
      self.bannerAlpha = self.bannerTimer
    else
      self.bannerAlpha = 1.0
    end
  else
    self.bannerAlpha = 0.0
  end

  if self.toastTimer > 0 then
    self.toastTimer = self.toastTimer - dt
    if self.toastTimer <= 0 then self.toastMsg = nil end
  end
end

function GameHUD:draw(env, cam, player)
  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()

  -- 1. Location Banner (Top Left)
  if self.bannerAlpha > 0.01 then
    local bw, bh = 340, 68
    local bx, by = 24, 20
    Theme.col(Theme.PAL.black, 0.45 * self.bannerAlpha)
    Theme.roundRect(bx, by + 2, bw, bh, 8, "fill")
    Theme.col(Theme.PAL.cardBg, 0.92 * self.bannerAlpha)
    Theme.roundRect(bx, by, bw, bh, 8, "fill")
    Theme.col(Theme.PAL.fireRed, 0.85 * self.bannerAlpha)
    Theme.roundRect(bx, by, bw, bh, 8, "line")

    -- Red Pokéball accent icon
    Theme.col(Theme.PAL.fireRed, self.bannerAlpha)
    love.graphics.circle("fill", bx + 28, by + 34, 14)
    Theme.col(Theme.PAL.white, self.bannerAlpha)
    love.graphics.circle("fill", bx + 28, by + 34, 5)
    love.graphics.line(bx + 14, by + 34, bx + 42, by + 34)

    Theme.setFont("header")
    Theme.col(Theme.PAL.white, self.bannerAlpha)
    love.graphics.print(self.locationName, bx + 52, by + 12)

    Theme.setFont("small")
    Theme.col(Theme.PAL.textMuted, self.bannerAlpha)
    love.graphics.print(self.locationDesc, bx + 52, by + 38)
  end

  -- 2. Top Right Info Bar: Clock, Camera Mode & Compass
  local rw = 320
  local rx = ww - rw - 24
  local ry = 20
  local rh = 40
  Theme.col(Theme.PAL.cardBg, 0.88)
  Theme.roundRect(rx, ry, rw, rh, 8, "fill")
  Theme.col(Theme.PAL.cardBorder, 0.75)
  Theme.roundRect(rx, ry, rw, rh, 8, "line")

  Theme.setFont("small")
  Theme.col(Theme.PAL.amber, 1)
  love.graphics.print(env:getTimeString(), rx + 14, ry + 12)

  local modeStr = "📷 " .. cam.mode:upper()
  if cam.mode == "isometric" then modeStr = "📷 ISOMÉTRICA (45°)"
  elseif cam.mode == "third_person" then modeStr = "📷 3ª PESSOA"
  elseif cam.mode == "top_down" then modeStr = "📷 CLÁSSICA TOP-DOWN"
  elseif cam.mode == "free_orbit" then modeStr = "📷 ÓRBITA LIVRE" end

  Theme.setFont("micro")
  Theme.col(Theme.PAL.white, 0.95)
  love.graphics.print(modeStr, rx + 175, ry + 13)

  -- 3. Bottom Controls Guide
  local barH = 34
  local barY = wh - barH - 12
  local barW = ww - 48
  Theme.col(Theme.PAL.cardBg, 0.85)
  Theme.roundRect(24, barY, barW, barH, 6, "fill")
  Theme.col(Theme.PAL.cardBorder, 0.6)
  Theme.roundRect(24, barY, barW, barH, 6, "line")

  Theme.setFont("micro")
  Theme.col(Theme.PAL.textMuted, 1)
  local hints = "🎮 [WASD / Setas]: Mover  •  [Shift / B]: Correr  •  [C]: Alternar Câmera  •  [T]: Avançar Horário  •  [M / Esc]: Menu / Mochila  •  [Mouse Dir]: Rotacionar 360°"
  love.graphics.printf(hints, 24, barY + 10, barW, "center")

  -- 4. Toast alert
  if self.toastMsg then
    local tw, th = 380, 42
    local tx = (ww - tw) / 2
    local ty = wh - 100
    Theme.col(Theme.PAL.black, 0.5)
    Theme.roundRect(tx, ty + 2, tw, th, 8, "fill")
    Theme.col(Theme.PAL.cardHeader, 0.95)
    Theme.roundRect(tx, ty, tw, th, 8, "fill")
    Theme.col(Theme.PAL.gbaPurple, 0.9)
    Theme.roundRect(tx, ty, tw, th, 8, "line")

    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.printf(self.toastMsg, tx, ty + 12, tw, "center")
  end
end

return GameHUD
