local Theme = require("src.ui.Theme")

local Kit = {
  mouseX = 0,
  mouseY = 0,
  mouseDown = false,
  mouseClicked = false,
  mouseReleased = false,
  hotId = nil,
  activeId = nil,
  time = 0
}

function Kit.update(dt)
  Kit.time = Kit.time + dt
  Kit.mouseX, Kit.mouseY = love.mouse.getPosition()
  Kit.mouseDown = love.mouse.isDown(1)
end

function Kit.postUpdate()
  Kit.mouseClicked = false
  Kit.mouseReleased = false
end

function Kit.inRect(x, y, w, h)
  return Kit.mouseX >= x and Kit.mouseX <= x + w and Kit.mouseY >= y and Kit.mouseY <= y + h
end

function Kit.button(id, text, x, y, w, h, opts)
  opts = opts or {}
  local hover = Kit.inRect(x, y, w, h) and not opts.disabled
  local pressed = hover and Kit.mouseDown
  local clicked = false

  if hover then
    Kit.hotId = id
    if Kit.mouseClicked then
      Kit.activeId = id
    end
  end

  if Kit.mouseReleased and Kit.activeId == id then
    if hover then clicked = true end
    Kit.activeId = nil
  end

  -- Determine colors
  local bgCol = Theme.PAL.btnNeutral
  local textCol = Theme.PAL.text
  local borderCol = Theme.PAL.btnBorder

  if opts.kind == "primary" then
    bgCol = Theme.PAL.btnPrimary
    borderCol = { 65, 190, 100 }
    textCol = Theme.PAL.white
  elseif opts.kind == "accent" then
    bgCol = Theme.PAL.btnAccent
    borderCol = { 85, 160, 255 }
    textCol = Theme.PAL.white
  elseif opts.kind == "danger" then
    bgCol = Theme.PAL.btnDanger
    borderCol = { 255, 110, 105 }
    textCol = Theme.PAL.white
  elseif opts.kind == "tab" then
    if opts.active then
      bgCol = opts.accentCol or Theme.PAL.gbaPurple
      borderCol = Theme.PAL.white
      textCol = Theme.PAL.white
    else
      bgCol = { 20, 24, 32 }
      borderCol = { 38, 44, 54 }
      textCol = Theme.PAL.textMuted
    end
  end

  -- Hover/press adjustments
  local dy = 0
  if hover and not opts.disabled then
    if pressed then
      dy = 1
    else
      dy = -1
    end
  end

  local rad = opts.radius or 6

  -- Shadow
  if not opts.disabled and dy <= 0 then
    Theme.col(Theme.PAL.black, 0.20)
    Theme.roundRect(x, y + 2, w, h, rad, "fill")
  end

  -- Fill
  local alpha = opts.disabled and 0.45 or (hover and 0.92 or 1)
  Theme.col(bgCol, alpha)
  Theme.roundRect(x, y + dy, w, h, rad, "fill")

  -- Border
  Theme.col(borderCol, opts.active and 0.9 or 0.6)
  Theme.roundRect(x, y + dy, w, h, rad, "line")

  -- Label & Icon
  Theme.setFont(opts.font or "body")
  Theme.col(textCol, opts.disabled and 0.5 or 1)
  local font = love.graphics.getFont()
  local tw = font:getWidth(text)
  local th = font:getHeight()
  local iconW = (opts.icon == "play") and 14 or 0
  local totalW = tw + iconW
  local tx = math.floor(x + (w - totalW) / 2) + iconW
  local ty = math.floor(y + dy + (h - th) / 2)

  if opts.icon == "play" then
    local triX = tx - 14
    local triY = ty + math.floor((th - 10) / 2)
    love.graphics.polygon("fill", triX, triY, triX + 9, triY + 5, triX, triY + 10)
  end

  love.graphics.print(text, tx, ty)

  return clicked
end

function Kit.pill(text, x, y, opts)
  opts = opts or {}
  local fontName = opts.font or "small"
  Theme.setFont(fontName)
  local font = love.graphics.getFont()
  local tw = font:getWidth(text)
  local th = font:getHeight()

  local padX = opts.padX or 8
  local padY = opts.padY or 3
  local w = tw + padX * 2
  local h = th + padY * 2
  local r = h / 2

  local bg = opts.bg or Theme.PAL.cardHeader
  local border = opts.border or Theme.PAL.cardBorder
  local textColor = opts.color or Theme.PAL.text

  Theme.col(bg, opts.bgAlpha or 0.85)
  Theme.roundRect(x, y, w, h, r, "fill")
  Theme.col(border, opts.borderAlpha or 0.8)
  Theme.roundRect(x, y, w, h, r, "line")

  Theme.col(textColor, 1)
  love.graphics.print(text, math.floor(x + padX), math.floor(y + padY))
  return w, h
end

return Kit
