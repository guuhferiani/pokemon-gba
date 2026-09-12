local Theme = {}

Theme.PAL = {
  bg          = { 13, 16, 23 },      -- #0d1017 deep slate field
  cardBg      = { 22, 27, 34 },      -- #161b22 raised surface
  cardBorder  = { 48, 54, 61 },      -- #30363d subtle border
  cardHeader  = { 28, 34, 43 },      -- #1c222b slightly raised header
  rowBg       = { 17, 21, 28 },      -- #11151c inner row
  rowHover    = { 33, 40, 52 },      -- #212834 row hover
  
  -- Accents
  gbaPurple   = { 108, 92, 231 },    -- #6c5ce7 Iconic GBA Indigo
  gbaIndigo   = { 85, 65, 210 },
  fireRed     = { 235, 75, 45 },     -- #eb4b2d
  leafGreen   = { 46, 204, 113 },    -- #2ecc71
  emerald     = { 26, 188, 156 },    -- #1abc9c
  ruby        = { 232, 67, 147 },    -- #e84393
  sapphire    = { 9, 132, 227 },     -- #0984e3
  
  -- Text
  text        = { 240, 246, 252 },   -- #f0f6fc primary white
  textMuted   = { 139, 148, 158 },   -- #8b949e secondary
  textDim     = { 100, 110, 120 },   -- #646e78 muted
  textDark    = { 15, 20, 25 },
  
  -- Buttons & Actions
  btnPrimary  = { 46, 164, 79 },     -- #2ea44f vibrant green
  btnAccent   = { 56, 139, 253 },    -- #388bfd blue
  btnDanger   = { 248, 81, 73 },     -- #f85149 red
  btnNeutral  = { 33, 38, 45 },      -- #21262d
  btnBorder   = { 54, 62, 72 },
  
  white       = { 255, 255, 255 },
  black       = { 0, 0, 0 }
}

function Theme.col(c, a)
  if not c then return end
  a = a or 1
  love.graphics.setColor((c[1] or 255) / 255, (c[2] or 255) / 255, (c[3] or 255) / 255, a)
end

function Theme.roundRect(x, y, w, h, r, mode)
  mode = mode or "fill"
  r = r or 6
  r = math.min(r, w / 2, h / 2)
  love.graphics.rectangle(mode, math.floor(x), math.floor(y), math.floor(w), math.floor(h), r, r)
end

function Theme.card(x, y, w, h, r)
  r = r or 8
  -- Drop shadow
  Theme.col(Theme.PAL.black, 0.25)
  Theme.roundRect(x, y + 3, w, h, r, "fill")
  -- Background surface
  Theme.col(Theme.PAL.cardBg, 1)
  Theme.roundRect(x, y, w, h, r, "fill")
  -- Border
  Theme.col(Theme.PAL.cardBorder, 0.85)
  Theme.roundRect(x, y, w, h, r, "line")
end

function Theme.initFonts()
  Theme.fonts = {}
  local ok, f = pcall(love.graphics.newFont, 24)
  Theme.fonts.title = ok and f or love.graphics.getFont()
  
  ok, f = pcall(love.graphics.newFont, 18)
  Theme.fonts.header = ok and f or love.graphics.getFont()
  
  ok, f = pcall(love.graphics.newFont, 14)
  Theme.fonts.body = ok and f or love.graphics.getFont()
  
  ok, f = pcall(love.graphics.newFont, 12)
  Theme.fonts.small = ok and f or love.graphics.getFont()
  
  ok, f = pcall(love.graphics.newFont, 10)
  Theme.fonts.micro = ok and f or love.graphics.getFont()
end

function Theme.setFont(name)
  if not Theme.fonts then Theme.initFonts() end
  love.graphics.setFont(Theme.fonts[name] or Theme.fonts.body)
end

return Theme
