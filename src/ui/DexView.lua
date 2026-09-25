local DexView = {}

-- ============================================================
-- DexView.lua — Componente visual da PokéDex no Studio++
-- Inspirado no estilo GBA: menu por região + grid de Pokémon
-- ============================================================

local Theme = require("src.ui.Theme")
local Kit   = require("src.ui.Kit")
local GbaDex = require("src.core.GbaDex")

-- Estado interno da view
DexView.dexData   = nil       -- resultado de GbaDex.readDex()
DexView.region    = nil       -- nil = menu principal | "kanto"|"johto"|"national"
DexView.scrollY   = 0
DexView.filter    = "all"     -- "all" | "seen" | "caught" | "missing"

-- Paleta de cores por região
local REGION_COLORS = {
  kanto    = { accent = { 235, 75, 45 },   dim = { 80, 25, 15 },  label = "Kanto" },
  johto    = { accent = { 56, 175, 110 },  dim = { 15, 60, 38 },  label = "Johto" },
  national = { accent = { 56, 139, 253 },  dim = { 15, 38, 80 },  label = "National" },
}

-- ============================================================
-- Ícones de estado (texto Unicode como substituto de sprites)
-- ============================================================
local function statusIcon(seen, caught)
  if caught then return "●" end   -- capturado
  if seen   then return "◐" end   -- visto
  return "○"                       -- não visto
end

local function statusColor(seen, caught)
  if caught then return { 80, 220, 120 } end   -- verde
  if seen   then return { 240, 200, 60 } end    -- amarelo
  return { 80, 80, 100 }                         -- cinza
end

-- ============================================================
-- Carrega dados do save
-- ============================================================
function DexView.refresh(savePath)
  DexView.dexData = GbaDex.readDex(savePath)
  DexView.scrollY = 0
  DexView.filter  = "all"
end

-- ============================================================
-- Desenha o menu principal (seleção de região)
-- ============================================================
function DexView.drawMenuScreen(x, y, w, h)
  local dex = DexView.dexData
  if not dex then return end

  -- Título
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("POKÉDEX", x + 24, y + 18)

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Selecione a região para explorar", x + 24, y + 46)

  -- Linha separadora
  Theme.col(Theme.PAL.cardBorder, 0.5)
  love.graphics.line(x + 24, y + 66, x + w - 24, y + 66)

  -- Cards de região
  local cardH = 72
  local cardW = w - 48
  local regions = {
    {
      id      = "kanto",
      label   = "Kanto Pokédex",
      range   = "#001 ~ #151",
      seen    = dex.seenKanto,
      caught  = dex.caughtKanto,
      total   = 151,
    },
    {
      id      = "johto",
      label   = "Johto Pokédex",
      range   = "#152 ~ #251",
      seen    = dex.seenJohto,
      caught  = dex.caughtJohto,
      total   = 100,
    },
    {
      id      = "national",
      label   = "National Pokédex",
      range   = "#001 ~ #386",
      seen    = dex.seenNational,
      caught  = dex.caughtNational,
      total   = 386,
    },
  }

  local ry = y + 80
  for _, reg in ipairs(regions) do
    local col = REGION_COLORS[reg.id]
    local hover = Kit.inRect(x + 24, ry, cardW, cardH)

    -- Card background
    if hover then
      Theme.col(col.dim, 0.9)
    else
      Theme.col(Theme.PAL.cardHeader, 0.7)
    end
    Theme.roundRect(x + 24, ry, cardW, cardH, 8, "fill")
    Theme.col(col.accent, hover and 0.9 or 0.45)
    Theme.roundRect(x + 24, ry, cardW, cardH, 8, "line")

    -- Seta de seleção
    if hover then
      Theme.setFont("header")
      Theme.col(col.accent, 1)
      love.graphics.print("▶", x + 32, ry + 22)
    end

    -- Label e range
    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print(reg.label, x + 52, ry + 12)

    Theme.setFont("micro")
    Theme.col(col.accent, 0.9)
    love.graphics.print(reg.range, x + 52, ry + 32)

    -- Contadores Seen / Obtained
    local statsX = x + w - 200

    Theme.setFont("micro")
    Theme.col(Theme.PAL.textMuted, 0.9)
    love.graphics.print("SEEN", statsX, ry + 12)
    love.graphics.print("OBTAINED", statsX + 75, ry + 12)

    Theme.setFont("header")
    Theme.col(col.accent, 1)
    love.graphics.print(reg.seen,   statsX, ry + 28)
    love.graphics.print(reg.caught, statsX + 75, ry + 28)

    -- Barra de progresso
    local barW = cardW - 170
    local barH = 4
    local barX = x + 52
    local barY = ry + cardH - 12
    Theme.col(Theme.PAL.cardBorder, 0.6)
    Theme.roundRect(barX, barY, barW, barH, 2, "fill")
    if reg.total > 0 then
      local pct = math.min(reg.caught / reg.total, 1)
      Theme.col(col.accent, 0.85)
      Theme.roundRect(barX, barY, math.max(4, barW * pct), barH, 2, "fill")
    end

    -- Clique no card
    if hover and Kit.mouseReleased then
      DexView.region  = reg.id
      DexView.scrollY = 0
      DexView.filter  = "all"
    end

    ry = ry + cardH + 12
  end

  -- Info de debug / status do save
  if not dex.valid then
    Theme.setFont("micro")
    Theme.col({ 240, 80, 60 }, 0.9)
    love.graphics.print("⚠ " .. (dex.error or "Erro desconhecido"), x + 24, y + h - 30)
  else
    Theme.setFont("micro")
    Theme.col(Theme.PAL.textDim, 0.7)
    love.graphics.print(
      string.format("Save: sec0=%04X  seen@%04X  caught@%04X",
        dex._sec0Offset or 0,
        dex._seenOffset or 0,
        dex._caughtOffset or 0),
      x + 24, y + h - 30
    )
  end
end

-- ============================================================
-- Desenha a listagem de Pokémon de uma região
-- ============================================================
function DexView.drawRegionScreen(x, y, w, h)
  local dex = DexView.dexData
  if not dex or not DexView.region then return end

  local reg = DexView.region
  local col = REGION_COLORS[reg]
  local regions = GbaDex.REGIONS
  local regDef
  for _, r in ipairs(regions) do
    if r.id == reg then regDef = r break end
  end
  if not regDef then return end

  -- Header da região
  Theme.setFont("header")
  Theme.col(col.accent, 1)
  love.graphics.print("POKÉDEX — " .. col.label:upper(), x + 24, y + 14)

  -- Botão voltar
  if Kit.button("btn_dex_back", "◀ Voltar", x + w - 100, y + 12, 80, 26, { font = "micro" }) then
    DexView.region = nil
  end

  -- Contadores
  local seenCount, caughtCount
  if reg == "kanto" then
    seenCount   = dex.seenKanto
    caughtCount = dex.caughtKanto
  elseif reg == "johto" then
    seenCount   = dex.seenJohto
    caughtCount = dex.caughtJohto
  else
    seenCount   = dex.seenNational
    caughtCount = dex.caughtNational
  end

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print(
    string.format("Seen: %d  •  Obtained: %d  •  Total: %d",
      seenCount, caughtCount, regDef.to - regDef.from + 1),
    x + 24, y + 40
  )

  -- Filtros
  local filterY = y + 64
  local filters = {
    { id = "all",     label = "Todos" },
    { id = "caught",  label = "● Capturado" },
    { id = "seen",    label = "◐ Visto" },
    { id = "missing", label = "○ Não Visto" },
  }
  local fx = x + 24
  for _, fil in ipairs(filters) do
    local isAct = (DexView.filter == fil.id)
    local fw = love.graphics.getFont():getWidth(fil.label) + 18
    if Kit.button("dexfil_" .. fil.id, fil.label, fx, filterY, fw, 24, {
      kind = "tab",
      active = isAct,
      accentCol = col.accent,
      font = "micro"
    }) then
      DexView.filter = fil.id
      DexView.scrollY = 0
    end
    fx = fx + fw + 6
  end

  -- Linha separadora
  local sepY = filterY + 30
  Theme.col(Theme.PAL.cardBorder, 0.5)
  love.graphics.line(x + 24, sepY, x + w - 24, sepY)

  -- Grid de Pokémon
  local gridY = sepY + 8
  local gridH = h - (gridY - y) - 8
  local cols  = 4
  local cellW = math.floor((w - 48) / cols)
  local cellH = 44
  local cellPad = 4

  -- Constrói lista filtrada
  local list = {}
  for n = regDef.from, regDef.to do
    local s = dex.seen[n]   or false
    local c = dex.caught[n] or false
    local include = (DexView.filter == "all")
      or (DexView.filter == "caught"  and c)
      or (DexView.filter == "seen"    and s and not c)
      or (DexView.filter == "missing" and not s)
    if include then
      table.insert(list, { n = n, seen = s, caught = c })
    end
  end

  -- Scroll com mouse wheel (suporte via Kit)
  local visibleRows = math.floor(gridH / (cellH + cellPad))
  local totalRows   = math.ceil(#list / cols)
  local maxScroll   = math.max(0, totalRows - visibleRows)

  -- Clipping region para o grid
  love.graphics.setScissor(x, gridY, w, gridH)

  local offsetY = DexView.scrollY * (cellH + cellPad)
  for i, entry in ipairs(list) do
    local ci  = (i - 1) % cols
    local ri  = math.floor((i - 1) / cols)
    local cx  = x + 24 + ci * cellW
    local cy  = gridY + ri * (cellH + cellPad) - offsetY

    -- Skip se fora da área visível
    if cy + cellH >= gridY and cy <= gridY + gridH then
      local sColor = statusColor(entry.seen, entry.caught)
      local hover  = Kit.inRect(cx, cy, cellW - cellPad, cellH)

      -- Fundo da célula
      if hover then
        Theme.col(col.dim, 0.9)
      else
        Theme.col(entry.caught and { 20, 45, 28 } or (entry.seen and { 40, 35, 15 } or Theme.PAL.cardHeader), 0.6)
      end
      Theme.roundRect(cx, cy, cellW - cellPad, cellH, 5, "fill")
      Theme.col(sColor, hover and 0.9 or 0.35)
      Theme.roundRect(cx, cy, cellW - cellPad, cellH, 5, "line")

      -- Ícone de status
      Theme.setFont("body")
      Theme.col(sColor, 1)
      love.graphics.print(statusIcon(entry.seen, entry.caught), cx + 8, cy + 13)

      -- Número e nome
      Theme.setFont("micro")
      Theme.col(Theme.PAL.textMuted, 0.8)
      love.graphics.print(string.format("#%03d", entry.n), cx + 28, cy + 6)

      Theme.setFont("small")
      Theme.col(entry.caught and Theme.PAL.white or (entry.seen and { 240, 210, 130 } or Theme.PAL.textDim), 1)
      local name = GbaDex.SPECIES[entry.n] or ("Nº" .. entry.n)
      -- Truncar nome longo
      local maxNameW = cellW - 44
      while love.graphics.getFont():getWidth(name) > maxNameW and #name > 3 do
        name = name:sub(1, -2)
      end
      if GbaDex.SPECIES[entry.n] and love.graphics.getFont():getWidth(GbaDex.SPECIES[entry.n]) > maxNameW then
        name = name .. "."
      end
      love.graphics.print(name, cx + 28, cy + 22)
    end
  end

  love.graphics.setScissor()

  -- Scrollbar
  if totalRows > visibleRows then
    local sbH  = gridH
    local sbW  = 4
    local sbX  = x + w - 16
    local sbY  = gridY
    Theme.col(Theme.PAL.cardBorder, 0.5)
    Theme.roundRect(sbX, sbY, sbW, sbH, 2, "fill")
    local thumbH = math.max(20, sbH * (visibleRows / totalRows))
    local thumbY = sbY + (sbH - thumbH) * (DexView.scrollY / math.max(1, maxScroll))
    Theme.col(col.accent, 0.7)
    Theme.roundRect(sbX, thumbY, sbW, thumbH, 2, "fill")
  end

  -- Empty state
  if #list == 0 then
    love.graphics.setScissor()
    Theme.setFont("body")
    Theme.col(Theme.PAL.textMuted, 0.7)
    love.graphics.printf("Nenhum Pokémon nesta categoria ainda.", x + 24, gridY + 60, w - 48, "center")
  end
end

-- ============================================================
-- Scroll handler (chamado pelo LauncherView.wheelmoved)
-- ============================================================
function DexView.scroll(dy)
  if DexView.region then
    DexView.scrollY = math.max(0, DexView.scrollY - dy)
  end
end

-- ============================================================
-- Draw principal — roteador entre menu e listagem
-- ============================================================
function DexView.draw(x, y, w, h)
  if DexView.region then
    DexView.drawRegionScreen(x, y, w, h)
  else
    DexView.drawMenuScreen(x, y, w, h)
  end
end

return DexView
