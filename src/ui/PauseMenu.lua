local Theme = require("src.ui.Theme")
local Kit = require("src.ui.Kit")
local GbaItemInjector = require("src.core.GbaItemInjector")
local GbaShinyDex = require("src.core.GbaShinyDex")
local GbaSave = require("src.core.GbaSave")
local utf8 = require("utf8")

local function utf8Truncate(str, maxChars)
  if not str then return "" end
  local len = utf8.len(str)
  if len and len > maxChars then
    local offset = utf8.offset(str, maxChars + 1)
    if offset then return string.sub(str, 1, offset - 1) .. "..." end
  end
  return str
end

local PauseMenu = {}
PauseMenu.__index = PauseMenu

function PauseMenu.new(hud, env, cam)
  local pm = {
    isOpen = false,
    currentTab = "bag", -- "bag" | "shiny" | "world" | "saves"
    hud = hud,
    env = env,
    cam = cam,
    shinyScanResult = nil,
    itemsCategory = "all",
    selectedQty = 99
  }
  setmetatable(pm, PauseMenu)
  return pm
end

function PauseMenu:toggle()
  self.isOpen = not self.isOpen
  if self.isOpen and self.currentTab == "shiny" then
    self:refreshShinies()
  end
end

function PauseMenu:resolveSavePath()
  local candidates = {
    "saves/firered_slot1.sav",
    "FireRed.sav",
    "roms/FireRedDefinitivo.sav",
    "roms/FireRed_251+final.sav"
  }
  for _, cp in ipairs(candidates) do
    local f = io.open(cp, "rb")
    if f then f:close() return cp end
  end
  return "saves/firered_slot1.sav"
end

function PauseMenu:refreshShinies()
  local savePath = self:resolveSavePath()
  local f = io.open(savePath, "rb")
  if f then
    f:close()
    self.shinyScanResult = GbaShinyDex.scanSave(savePath)
  else
    self.shinyScanResult = { shinies = {}, totalPokemon = 0, totalShinies = 0 }
  end
end

function PauseMenu:update(dt)
  Kit.update(dt)
end

function PauseMenu:draw()
  if not self.isOpen then return end

  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()

  -- Dim backdrop
  Theme.col(Theme.PAL.black, 0.70)
  love.graphics.rectangle("fill", 0, 0, ww, wh)

  local mw = math.min(940, ww - 64)
  local mh = math.min(600, wh - 64)
  local mx = (ww - mw) / 2
  local my = (wh - mh) / 2

  Theme.card(mx, my, mw, mh, 10)

  -- Header Bar
  local headerH = 64
  Theme.col(Theme.PAL.cardHeader, 0.95)
  Theme.roundRect(mx, my, mw, headerH, 10, "fill")
  Theme.col(Theme.PAL.cardBorder, 0.8)
  love.graphics.line(mx, my + headerH, mx + mw, my + headerH)

  Theme.setFont("title")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("POKÉMON GBA 3D", mx + 24, my + 16)
  Theme.col(Theme.PAL.gbaPurple, 1)
  love.graphics.print("MENU", mx + 230, my + 16)

  -- Close Button
  if Kit.button("btn_close_menu", "✕ Fechar", mx + mw - 110, my + 16, 90, 32, { kind = "danger", font = "small" }) then
    self.isOpen = false
  end

  -- Tab Buttons
  local tabY = my + headerH + 12
  local tabX = mx + 24
  local tabs = {
    { id = "bag", label = "🎒 MOCHILA & ITENS" },
    { id = "shiny", label = "✨ SHINYDEX" },
    { id = "world", label = "🌍 MUNDO & CÂMERA" },
    { id = "saves", label = "💾 SAVES & SLOTS" }
  }

  for _, t in ipairs(tabs) do
    local isAct = (self.currentTab == t.id)
    local tw = love.graphics.getFont():getWidth(t.label) + 24
    if Kit.button("pm_tab_" .. t.id, t.label, tabX, tabY, tw, 30, {
      kind = "tab",
      active = isAct,
      accentCol = Theme.PAL.gbaPurple,
      font = "small"
    }) then
      self.currentTab = t.id
      if t.id == "shiny" then self:refreshShinies() end
    end
    tabX = tabX + tw + 8
  end

  -- Content Area
  local contentY = tabY + 40
  local contentW = mw - 48
  local contentH = mh - (contentY - my) - 20

  if self.currentTab == "bag" then
    self:drawBagContent(mx + 24, contentY, contentW, contentH)
  elseif self.currentTab == "shiny" then
    self:drawShinyContent(mx + 24, contentY, contentW, contentH)
  elseif self.currentTab == "world" then
    self:drawWorldContent(mx + 24, contentY, contentW, contentH)
  else
    self:drawSavesContent(mx + 24, contentY, contentW, contentH)
  end

  Kit.postUpdate()
end

function PauseMenu:drawBagContent(x, y, w, h)
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("INJETOR DE ITENS NA MOCHILA", x, y)

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Injete itens raros e recursos diretamente no seu save de 128KB Flash:", x, y + 26)

  -- Quick Action Buttons
  local qy = y + 54
  local qx = x
  if Kit.button("btn_pm_candy", "🍬 +99 Doces Raros", qx, qy, 145, 30, { kind = "accent", font = "small" }) then
    local pSave = self:resolveSavePath()
    local ok, msg = GbaItemInjector.injectItem(pSave, 0x0044, 99, "items")
    self.hud:showToast(ok and "🍬 +99 Doces Raros injetados!" or tostring(msg))
  end
  qx = qx + 155
  if Kit.button("btn_pm_mball", "🔴 +99 Master Balls", qx, qy, 155, 30, { kind = "primary", font = "small" }) then
    local pSave = self:resolveSavePath()
    local ok, msg = GbaItemInjector.injectItem(pSave, 0x0001, 99, "balls")
    self.hud:showToast(ok and "🔴 +99 Master Balls injetadas!" or tostring(msg))
  end
  qx = qx + 165
  if Kit.button("btn_pm_money", "💰 +$500.000 PokéDollars", qx, qy, 175, 30, { kind = "accent", font = "small" }) then
    local pSave = self:resolveSavePath()
    local ok, msg = GbaItemInjector.injectMoney(pSave, 500000)
    self.hud:showToast(ok and "💰 Dinheiro adicionado com sucesso!" or tostring(msg))
  end
  qx = qx + 185
  if Kit.button("btn_pm_natdex", "📖 Desbloquear National Dex", qx, qy, 190, 30, { kind = "primary", font = "small" }) then
    local pSave = self:resolveSavePath()
    local ok, msg = GbaItemInjector.unlockNationalDex(pSave)
    self.hud:showToast(ok and "📖 Pokédex Nacional 100% Desbloqueada!" or tostring(msg))
  end

  -- Grid of items
  local listY = qy + 44
  local colW = math.floor((w - 16) / 2)
  local rowH = 46

  for i = 1, math.min(#GbaItemInjector.ITEMS, 12) do
    local it = GbaItemInjector.ITEMS[i]
    local colIndex = (i - 1) % 2
    local rowIndex = math.floor((i - 1) / 2)
    local ix = x + colIndex * (colW + 16)
    local iy = listY + rowIndex * (rowH + 6)

    Theme.col(Theme.PAL.rowBg, 0.9)
    Theme.roundRect(ix, iy, colW, rowH, 6, "fill")
    Theme.col(Theme.PAL.cardBorder, 0.5)
    Theme.roundRect(ix, iy, colW, rowH, 6, "line")

    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print(it.name, ix + 10, iy + 6)

    Theme.setFont("micro")
    Theme.col(Theme.PAL.textMuted, 1)
    local sDesc = utf8Truncate(it.desc or "", 38)
    love.graphics.print(sDesc, ix + 10, iy + 26)

    if Kit.button("inj_pm_" .. it.id, "+ Injetar", ix + colW - 75, iy + 10, 65, 26, { kind = "primary", font = "micro" }) then
      local pSave = self:resolveSavePath()
      local ok, msg = GbaItemInjector.injectItem(pSave, it.id, 99, it.pocket)
      self.hud:showToast(ok and ("+99 " .. it.name .. " injetado!") or tostring(msg))
    end
  end
end

function PauseMenu:drawShinyContent(x, y, w, h)
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("✨ SHINYDEX (REGISTRO DE SHINIES)", x, y)

  local scan = self.shinyScanResult or { shinies = {}, totalPokemon = 0, totalShinies = 0 }
  local pillLabel = string.format("%d Shinies  •  %d Pokémon Registrados", scan.totalShinies, scan.totalPokemon)
  Kit.pill(pillLabel, x + w - 260, y + 2, { bg = { 150, 110, 20 }, color = Theme.PAL.white, font = "micro" })

  if Kit.button("btn_rescan_shiny", "🔄 Re-escanear Save", x + w - 140, y, 140, 26, { kind = "accent", font = "micro" }) then
    self:refreshShinies()
  end

  if #scan.shinies == 0 then
    Theme.col(Theme.PAL.rowBg, 0.9)
    Theme.roundRect(x, y + 45, w, 140, 8, "fill")
    Theme.setFont("header")
    Theme.col(Theme.PAL.amber, 1)
    love.graphics.printf("✨ Nenhum Pokémon Shiny capturado no save ativo ainda!", x, y + 75, w, "center")
    Theme.setFont("small")
    Theme.col(Theme.PAL.textMuted, 1)
    love.graphics.printf("Explore o mundo, entre na grama alta e salve seu progresso para registrar novos Pokémon!", x, y + 105, w, "center")
  else
    local colW = math.floor((w - 16) / 2)
    local rowH = 58
    local gy = y + 45
    for i = 1, math.min(#scan.shinies, 8) do
      local sMon = scan.shinies[i]
      local colIndex = (i - 1) % 2
      local rowIndex = math.floor((i - 1) / 2)
      local sx = x + colIndex * (colW + 16)
      local sy = gy + rowIndex * (rowH + 8)

      Theme.col({ 38, 32, 22 }, 0.95)
      Theme.roundRect(sx, sy, colW, rowH, 6, "fill")
      Theme.col({ 220, 175, 45 }, 0.8)
      Theme.roundRect(sx, sy, colW, rowH, 6, "line")

      Kit.pill("✨ SHINY", sx + 10, sy + 10, { bg = { 180, 135, 25 }, color = Theme.PAL.white, font = "micro" })

      Theme.setFont("body")
      Theme.col(Theme.PAL.white, 1)
      love.graphics.print(string.format("%s (#%03d)", sMon.speciesName, sMon.speciesId), sx + 75, sy + 10)

      Theme.setFont("small")
      Theme.col(Theme.PAL.textMuted, 1)
      love.graphics.print(string.format("Nv. %d  •  %s  •  %s", sMon.level, sMon.nature, sMon.location), sx + 12, sy + 34)
    end
  end
end

function PauseMenu:drawWorldContent(x, y, w, h)
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("CONFIGURAÇÕES DO MUNDO 3D & CÂMERA", x, y)

  local cy = y + 40
  Theme.setFont("body")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("MODO DE CÂMERA:", x, cy)

  local camModes = {
    { id = "isometric", label = "📐 Isométrica 45°" },
    { id = "third_person", label = "👤 3ª Pessoa" },
    { id = "top_down", label = "🕹️ Clássica Top-Down" },
    { id = "free_orbit", label = "🌐 Órbita Livre 360°" }
  }

  local cx = x + 160
  for _, cm in ipairs(camModes) do
    local isAct = (self.cam.mode == cm.id)
    if Kit.button("cm_" .. cm.id, cm.label, cx, cy - 4, 150, 30, { kind = "tab", active = isAct, font = "small" }) then
      self.cam:setMode(cm.id)
      self.hud:showToast("Câmera: " .. cm.label)
    end
    cx = cx + 158
  end

  local ty = cy + 50
  Theme.setFont("body")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("HORÁRIO DO DIA:", x, ty)

  local times = {
    { h = 8.0, label = "🌅 Manhã (08:00)" },
    { h = 12.0, label = "☀️ Meio-dia (12:00)" },
    { h = 17.5, label = "🌇 Pôr do Sol (17:30)" },
    { h = 22.0, label = "🌙 Noite (22:00)" }
  }

  local tx = x + 160
  for _, tm in ipairs(times) do
    if Kit.button("time_" .. tm.h, tm.label, tx, ty - 4, 150, 30, { kind = "tab", active = false, font = "small" }) then
      self.env:setTime(tm.h)
      self.hud:showToast("Horário ajustado para: " .. tm.label)
    end
    tx = tx + 158
  end
end

function PauseMenu:drawSavesContent(x, y, w, h)
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("GERENCIADOR DE SAVES & SLOTS", x, y)

  local slots, activeId = GbaSave.listSlots("firered")
  local sy = y + 40
  for _, s in ipairs(slots) do
    Theme.col(s.isActive and Theme.PAL.rowHover or Theme.PAL.rowBg, 0.9)
    Theme.roundRect(x, sy, w, 48, 6, "fill")
    Theme.col(s.isActive and Theme.PAL.gbaPurple or Theme.PAL.cardBorder, s.isActive and 0.9 or 0.5)
    Theme.roundRect(x, sy, w, 48, 6, "line")

    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print(s.name, x + 16, sy + 8)

    Theme.setFont("small")
    Theme.col(Theme.PAL.textMuted, 1)
    love.graphics.print("Tempo de Jogo: " .. s.playTime .. "  •  128KB Flash", x + 16, sy + 28)

    if s.isActive then
      Kit.pill("ATIVO", x + w - 100, sy + 14, { bg = { 20, 140, 60 }, color = Theme.PAL.white, font = "micro" })
    end

    sy = sy + 56
  end
end

return PauseMenu
