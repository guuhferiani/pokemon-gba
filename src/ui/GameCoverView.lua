local Theme = require("src.ui.Theme")
local Kit = require("src.ui.Kit")

local GameCoverView = {
  coverImage = nil,
  imageLoaded = false,
  glowAlpha = 0,
}

function GameCoverView.init()
  if not GameCoverView.imageLoaded then
    local path = "assets/kanto_johto_box_art.jpg"
    local ok, img = pcall(love.graphics.newImage, path)
    if not (ok and img) then
      path = "assets/kanto_johto_dual_cover.jpg"
      ok, img = pcall(love.graphics.newImage, path)
    end
    if ok and img then
      GameCoverView.coverImage = img
      GameCoverView.imageLoaded = true
    end
  end
end

function GameCoverView.update(dt, x, y, w, h)
  local mx, my = love.mouse.getPosition()
  local isHovered = (mx >= x and mx <= x + w and my >= y and my <= y + h)

  -- Smooth elegant border glow on hover (no wobble/jitter!)
  local targetGlow = isHovered and 1.0 or 0.0
  GameCoverView.glowAlpha = GameCoverView.glowAlpha + (targetGlow - GameCoverView.glowAlpha) * math.min(1.0, dt * 6.0)
end

function GameCoverView.draw(x, y, w, h, game)
  GameCoverView.init()

  love.graphics.push("all")

  -- Outer Soft Drop Shadow
  Theme.col(Theme.PAL.black, 0.45)
  Theme.roundRect(x, y + 4, w, h, 10, "fill")

  -- Outer Glow when hovered (warm golden amber)
  if GameCoverView.glowAlpha > 0.01 then
    love.graphics.setColor(1.0, 0.75, 0.25, 0.35 * GameCoverView.glowAlpha)
    Theme.roundRect(x - 3, y - 3, w + 6, h + 6, 12, "line")
    love.graphics.setColor(1.0, 0.85, 0.40, 0.60 * GameCoverView.glowAlpha)
    Theme.roundRect(x - 1, y - 1, w + 2, h + 2, 10, "line")
  end

  -- Card Background
  Theme.col(Theme.PAL.cardBg, 1.0)
  Theme.roundRect(x, y, w, h, 8, "fill")

  -- Stencil to clip content within rounded box
  love.graphics.stencil(function()
    Theme.roundRect(x, y, w, h, 8, "fill")
  end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)

  -- Subtle ambient split gradient behind the box (Fire red on left, Ocean blue on right)
  for step = 0, w, 4 do
    local t = step / w
    local r = (180 * (1 - t) + 20 * t) / 255
    local g = (45 * (1 - t) + 60 * t) / 255
    local b = (20 * (1 - t) + 160 * t) / 255
    love.graphics.setColor(r, g, b, 0.16)
    love.graphics.rectangle("fill", x + step, y, 4, h)
  end

  -- Box Dimensions (Square 1:1 Retail GBA Box)
  local padInner = 10
  local boxH = h - padInner * 2
  local boxW = boxH
  local boxX = x + padInner
  local boxY = y + padInner

  -- Retail Box Drop Shadow
  love.graphics.setColor(0, 0, 0, 0.55)
  Theme.roundRect(boxX + 4, boxY + 4, boxW, boxH, 6, "fill")

  -- Draw the Authentic GBA Retail Box Cover (with Charizard & Lugia, metallic GBA spine, Pokemon logo)
  if GameCoverView.coverImage then
    local iw = GameCoverView.coverImage:getWidth()
    local ih = GameCoverView.coverImage:getHeight()
    local scale = boxH / ih

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(GameCoverView.coverImage, boxX, boxY, 0, scale, scale)

    -- Subtle box lighting gloss / bevel
    love.graphics.setColor(1, 1, 1, 0.20)
    love.graphics.line(boxX, boxY, boxX + boxW, boxY)
    love.graphics.line(boxX, boxY, boxX, boxY + boxH)
    love.graphics.setColor(0, 0, 0, 0.40)
    love.graphics.line(boxX + boxW, boxY, boxX + boxW, boxY + boxH)
    love.graphics.line(boxX, boxY + boxH, boxX + boxW, boxY + boxH)
  end

  -- Right Side: Official Edition Specifications & Feature Badges
  local infoX = boxX + boxW + 16
  local infoW = (x + w) - infoX - padInner

  if infoW > 120 then
    local curY = y + 14

    -- Title
    Theme.setFont("bodyBold")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print("EDICAO DEFINITIVA", infoX, curY)
    curY = curY + 22

    -- Badges
    Kit.pill("32MB ROM", infoX, curY, { bg = { 200, 70, 20 }, color = Theme.PAL.white, font = "micro" })
    local p1W = love.graphics.getFont():getWidth("32MB ROM") + 16
    Kit.pill("100% PT-BR", infoX + p1W + 6, curY, { bg = { 30, 130, 60 }, color = Theme.PAL.white, font = "micro" })
    curY = curY + 26

    -- Feature Checklist
    local features = {
      { text = "Kanto + Johto no mesmo save", col = Theme.PAL.textSecondary },
      { text = "16 Ginasios + Liga Indigo", col = Theme.PAL.textSecondary },
      { text = "Pokedex Unificada (Sem Travas)", col = Theme.PAL.gold },
      { text = "Curva Johto Lv 58 a 100", col = Theme.PAL.textSecondary },
      { text = "Batalha Epica no Mt. Silver", col = Theme.PAL.accentLight },
    }

    Theme.setFont("micro")
    for _, feat in ipairs(features) do
      Theme.col(feat.col or Theme.PAL.textSecondary, 0.95)
      love.graphics.print("•  " .. feat.text, infoX, curY)
      curY = curY + 18
    end

    -- Bottom subnote
    Theme.setFont("micro")
    Theme.col(Theme.PAL.textMuted, 0.75)
    love.graphics.print("Compativel com PC, Android & Switch", infoX, y + h - 20)
  end

  -- Card Outer Border
  love.graphics.setStencilTest()
  love.graphics.setColor(0.35, 0.4, 0.5, 0.4)
  Theme.roundRect(x, y, w, h, 8, "line")

  love.graphics.pop()
end

return GameCoverView
