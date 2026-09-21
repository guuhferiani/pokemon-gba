local Theme = require("src.ui.Theme")
local Kit = require("src.ui.Kit")
local GbaRom = require("src.core.GbaRom")
local GbaSave = require("src.core.GbaSave")
local GbaMods = require("src.core.GbaMods")
local GbaCartView = require("src.ui.GbaCartView")
local GbaItemInjector = require("src.core.GbaItemInjector")

local LauncherView = {
  activeGameId = "firered",
  mainView = "game", -- "game" | "mods" | "items"
  modsFilter = nil,
  itemsCategory = "all",
  selectedQuantity = 99,
  discoveredRoms = {},
  slots = {},
  activeSlotId = "slot1",
  toastMessage = nil,
  toastTimer = 0,
  modal = nil, -- { type = "new_slot" | "rename", slotId = ..., text = ... }
}

function LauncherView.init()
  GbaMods.init()
  LauncherView.refreshLibrary()
  LauncherView.refreshSlots()
end

function LauncherView.showToast(msg, duration)
  LauncherView.toastMessage = msg
  LauncherView.toastTimer = duration or 3.0
end

function LauncherView.refreshLibrary()
  LauncherView.discoveredRoms = GbaRom.scanDirectory(".")
end

function LauncherView.refreshSlots()
  local slots, activeId = GbaSave.listSlots(LauncherView.activeGameId)
  LauncherView.slots = slots
  LauncherView.activeSlotId = activeId
end

function LauncherView.getActiveGame()
  return GbaRom.getGameById(LauncherView.activeGameId)
end

function LauncherView.getActiveRom()
  return LauncherView.discoveredRoms[LauncherView.activeGameId]
end

function LauncherView.update(dt)
  Kit.update(dt)

  if LauncherView.toastTimer > 0 then
    LauncherView.toastTimer = LauncherView.toastTimer - dt
    if LauncherView.toastTimer <= 0 then
      LauncherView.toastMessage = nil
    end
  end

  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()
  local leftW = math.floor(ww * 0.44)
  GbaCartView.update(dt, 24, 110, leftW, 280)
end

function LauncherView.drawGamePanel(ww, wh, headerH, game, rom)
  local contentY = headerH + 20
  local pad = 24
  local gap = 24
  local availableW = ww - pad * 2 - gap
  local leftW = math.floor(availableW * 0.44)
  local rightX = pad + leftW + gap
  local rightW = ww - pad - rightX

  -- Left Column: Game Title & Cartridge
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print(game.name, pad, contentY)

  local romReady = (rom ~= nil)
  local pillLabel = romReady and "ROM PRONTA" or "ROM NÃO ENCONTRADA"
  local pillBg = romReady and { 25, 135, 65 } or { 140, 100, 20 }
  Kit.pill(pillLabel, pad + 210, contentY + 2, {
    bg = pillBg,
    color = Theme.PAL.white,
    font = "micro"
  })

  -- 3D GBA Cartridge
  local cartAreaH = 260
  GbaCartView.draw(pad, contentY + 28, leftW, cartAreaH, game)

  -- Play & Cart Buttons
  local btnY = contentY + 28 + cartAreaH + 10
  local playText = romReady and ("JOGAR " .. game.name:upper()) or "ROMS DISPONÍVEIS NA PASTA"
  if Kit.button("btn_play", playText, pad, btnY, leftW, 40, {
    kind = romReady and "primary" or "neutral",
    icon = romReady and "play" or nil,
    disabled = not romReady,
    font = "body"
  }) then
    local romPath = nil
    local candidates = {
      rom and rom.filepath,
      rom and rom.displayPath,
      "roms/FireRedDefinitivo.gba",
      "roms/Fire Red(BR-USA).gba",
      "FireRed.gba"
    }
    for _, cp in ipairs(candidates) do
      if cp then
        local f = io.open(cp, "rb")
        if f then f:close() romPath = cp break end
      end
    end
    if not romPath then
      romPath = "roms/FireRed_251+final.gba"
    end

    GbaSave.setActiveSlot(LauncherView.activeGameId, LauncherView.activeSlotId, romPath)
    LauncherView.showToast("Slot " .. LauncherView.activeSlotId .. " ativado para " .. romPath .. "!")

    -- Check if portable emulator is available
    local emuPaths = {
      "gba/emulator/mGBA.exe",
      "gba/emulator/mgba.exe",
      "emulator/mGBA.exe",
      "emulator/mgba.exe",
      "../emulator/mGBA.exe",
      "tools/mgba/mgba.exe"
    }
    local emuFound = nil
    for _, ep in ipairs(emuPaths) do
      local f = io.open(ep, "rb")
      if f then f:close() emuFound = ep break end
    end

    if emuFound then
      local winEmu = emuFound:gsub('/', '\\')
      local winRom = romPath:gsub('/', '\\')
      os.execute('start "" "' .. winEmu .. '" "' .. winRom .. '"')
      LauncherView.showToast("Iniciando no mGBA integrado...")
    else
      local absPath = love.filesystem.getRealDirectory and love.filesystem.getRealDirectory(romPath)
      if absPath then
        os.execute('start "" "' .. absPath .. '/' .. romPath .. '"')
      else
        os.execute('start "" "' .. romPath .. '"')
      end
    end
  end

  -- ROM Info Card
  local infoCardY = btnY + 48
  local infoCardH = 122
  Theme.card(pad, infoCardY, leftW, infoCardH)

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("INFORMAÇÕES DA ROM", pad + 16, infoCardY + 12)

  Kit.pill("mGBA EMBUTIDO", pad + leftW - 120, infoCardY + 10, {
    bg = { 25, 75, 155 },
    color = Theme.PAL.white,
    font = "micro"
  })

  Theme.setFont("body")
  Theme.col(Theme.PAL.text, 1)
  local romTitle = rom and rom.title or "Nenhuma ROM carregada"
  local romCode = rom and rom.gameCode or "----"
  local romSize = rom and rom.fileSizeMb or "--"
  local folder = rom and (rom.folder or "/gba") or "/gba"
  local displayPath = rom and (rom.displayPath or ("gba/" .. game.defaultRomName)) or ("gba/" .. game.defaultRomName)

  love.graphics.print("Pasta: " .. folder .. "  •  Arquivo: " .. (rom and rom.filename or (game.defaultRomName)), pad + 16, infoCardY + 36)
  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Caminho: " .. displayPath, pad + 16, infoCardY + 60)
  love.graphics.print("Código: " .. romCode .. "  •  Tamanho: " .. romSize .. "  •  GBA 32-bit ARM", pad + 16, infoCardY + 80)
  love.graphics.print("Status: " .. (romReady and "Pronto para jogar via mGBA" or "Coloque a ROM na pasta /gba"), pad + 16, infoCardY + 100)

  -- -------------------------------------------------------------
  -- RIGHT COLUMN: SAVE SLOTS MANAGER
  -- -------------------------------------------------------------
  local slotsCardH = wh - contentY - 60
  Theme.card(rightX, contentY, rightW, slotsCardH)

  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("SAVE SLOTS", rightX + 20, contentY + 18)

  local slotCount = #LauncherView.slots
  Kit.pill(slotCount .. " slots", rightX + 150, contentY + 22, { font = "micro" })

  if Kit.button("btn_import_save", "+ Importar Save (.sav)", rightX + rightW - 170, contentY + 16, 150, 30, {
    kind = "accent",
    font = "small"
  }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory() .. "/saves")
    LauncherView.showToast("Coloque o seu arquivo .sav na pasta de saves aberta!")
  end

  -- Active Hero Slot Card
  local heroY = contentY + 62
  local heroW = rightW - 40
  local heroH = 110
  local heroX = rightX + 20

  local activeSlot = nil
  for _, s in ipairs(LauncherView.slots) do
    if s.id == LauncherView.activeSlotId then activeSlot = s break end
  end

  Theme.col(Theme.PAL.rowBg, 1)
  Theme.roundRect(heroX, heroY, heroW, heroH, 8, "fill")
  Theme.col(game.color or Theme.PAL.gbaPurple, 0.8)
  Theme.roundRect(heroX, heroY, heroW, heroH, 8, "line")

  local trainerName = activeSlot and activeSlot.name or "ASH"
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print(trainerName, heroX + 18, heroY + 16)

  Kit.pill("LOADED", heroX + heroW - 85, heroY + 16, {
    bg = { 20, 140, 60 },
    color = Theme.PAL.white,
    font = "micro"
  })

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  local stats = "4 insígnias  •  Tempo: " .. (activeSlot and activeSlot.playTime or "33:30") .. "  •  59 capturados"
  love.graphics.print(stats, heroX + 18, heroY + 44)

  local actBtnY = heroY + 70
  local actBtnW = 75
  local actBtnH = 26

  if Kit.button("act_export", "Exportar", heroX + heroW - 255, actBtnY, actBtnW, actBtnH, { kind = "accent", font = "small" }) then
    LauncherView.showToast("Save exportado para saves/" .. game.id .. "_" .. activeSlot.id .. ".sav")
  end

  if Kit.button("act_rename", "Renomear", heroX + heroW - 170, actBtnY, actBtnW, actBtnH, { font = "small" }) then
    LauncherView.modal = { type = "rename", slotId = activeSlot.id, text = activeSlot.name }
  end

  if Kit.button("act_delete", "Excluir", heroX + heroW - 85, actBtnY, actBtnW, actBtnH, { kind = "danger", font = "small" }) then
    GbaSave.deleteSlot(game.id, activeSlot.id)
    LauncherView.refreshSlots()
    LauncherView.showToast("Slot excluído.")
  end

  -- Other slots list
  local listY = heroY + heroH + 16
  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("OUTROS SLOTS DISPONÍVEIS", heroX, listY)
  listY = listY + 22

  for _, s in ipairs(LauncherView.slots) do
    if s.id ~= LauncherView.activeSlotId then
      local rowH = 46
      local hover = Kit.inRect(heroX, listY, heroW, rowH)
      Theme.col(hover and Theme.PAL.rowHover or Theme.PAL.rowBg, 0.8)
      Theme.roundRect(heroX, listY, heroW, rowH, 6, "fill")
      Theme.col(Theme.PAL.cardBorder, 0.5)
      Theme.roundRect(heroX, listY, heroW, rowH, 6, "line")

      Theme.setFont("body")
      Theme.col(Theme.PAL.text, 1)
      love.graphics.print(s.name, heroX + 16, listY + 8)

      Theme.setFont("micro")
      Theme.col(Theme.PAL.textMuted, 1)
      love.graphics.print("Tempo: " .. s.playTime, heroX + 16, listY + 28)

      if Kit.button("load_" .. s.id, "Carregar", heroX + heroW - 85, listY + 10, 75, 26, { font = "small" }) then
        GbaSave.setActiveSlot(game.id, s.id, rom and rom.filepath)
        LauncherView.refreshSlots()
        LauncherView.showToast("Slot " .. s.name .. " ativado!")
      end

      listY = listY + rowH + 8
    end
  end

  -- + New Save Slot Button
  local newSlotBtnY = slotsCardH + contentY - 50
  if Kit.button("btn_new_slot", "+ Novo Save Slot", heroX, newSlotBtnY, heroW, 36, { kind = "primary", font = "body" }) then
    local nextIndex = #LauncherView.slots + 1
    LauncherView.modal = { type = "new_slot", text = "Slot " .. nextIndex }
  end
end

function LauncherView.drawModsPanel(ww, wh, headerH)
  local pad = 24
  local contentY = headerH + 20
  local contentW = ww - pad * 2
  local contentH = wh - contentY - 45

  Theme.card(pad, contentY, contentW, contentH)

  -- Header title & actions
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("GERENCIADOR DE MODS & PATCHES (GBA)", pad + 24, contentY + 20)

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Ative ou desative traduções, mecânicas QoL, patches e scripts para os jogos da Gen 3.", pad + 24, contentY + 48)

  local btnW = 160
  if Kit.button("btn_open_mods_dir", "📂 Pasta gba/mods/", pad + contentW - btnW * 2 - 34, contentY + 18, btnW, 32, { kind = "accent", font = "small" }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory() .. "/gba/mods")
    LauncherView.showToast("Pasta gba/mods aberta!")
  end

  if Kit.button("btn_online_mods", "🌐 Índice da Comunidade", pad + contentW - btnW - 20, contentY + 18, btnW, 32, { kind = "primary", font = "small" }) then
    love.system.openURL("https://bryanthaboi.github.io/gen1recomp-mod-index/")
    LauncherView.showToast("Abrindo https://bryanthaboi.github.io/gen1recomp-mod-index/...")
  end

  -- Filter separator
  local filterY = contentY + 76
  Theme.col(Theme.PAL.cardBorder, 0.6)
  love.graphics.line(pad + 24, filterY, pad + contentW - 24, filterY)

  filterY = filterY + 12
  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Filtrar por jogo:", pad + 24, filterY + 5)

  local fx = pad + 140
  local filters = {
    { id = nil, label = "Todos" },
    { id = "firered", label = "FireRed" },
    { id = "leafgreen", label = "LeafGreen" },
    { id = "emerald", label = "Emerald" },
  }

  for _, flt in ipairs(filters) do
    local isAct = (LauncherView.modsFilter == flt.id)
    local fw = 80
    if Kit.button("flt_" .. tostring(flt.id), flt.label, fx, filterY, fw, 26, {
      kind = "tab",
      active = isAct,
      accentCol = Theme.PAL.gbaPurple,
      font = "small"
    }) then
      LauncherView.modsFilter = flt.id
    end
    fx = fx + fw + 8
  end

  -- Mods list
  local listY = filterY + 38
  local mods = GbaMods.list(LauncherView.modsFilter)
  local rowH = 68
  local rowW = contentW - 48
  local rx = pad + 24

  for _, m in ipairs(mods) do
    local hover = Kit.inRect(rx, listY, rowW, rowH)
    Theme.col(hover and Theme.PAL.rowHover or Theme.PAL.rowBg, 0.9)
    Theme.roundRect(rx, listY, rowW, rowH, 6, "fill")
    Theme.col(m.enabled and { 46, 164, 79 } or Theme.PAL.cardBorder, m.enabled and 0.85 or 0.4)
    Theme.roundRect(rx, listY, rowW, rowH, 6, "line")

    -- Toggle button
    local tBtnW = 110
    local tBtnH = 34
    local tBtnX = rx + rowW - tBtnW - 16
    local tBtnY = listY + (rowH - tBtnH) / 2
    local tKind = m.enabled and "primary" or "neutral"
    local tText = m.enabled and "✔ ATIVO" or "DESATIVADO"

    if Kit.button("toggle_" .. m.id, tText, tBtnX, tBtnY, tBtnW, tBtnH, {
      kind = tKind,
      font = "small"
    }) then
      local newState = GbaMods.toggle(m.id)
      LauncherView.showToast((newState and "Ativado: " or "Desativado: ") .. m.name)
    end

    -- Mod Details
    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print(m.name, rx + 18, listY + 12)

    -- Pill for type/category
    local catX = rx + 18 + love.graphics.getFont():getWidth(m.name) + 12
    Kit.pill(m.category, catX, listY + 10, {
      bg = { 35, 45, 65 },
      color = Theme.PAL.blue,
      font = "micro"
    })

    Theme.setFont("micro")
    Theme.col(Theme.PAL.textDim, 1)
    love.graphics.print("v" .. m.version .. "  •  " .. m.author, rx + 18, listY + 33)

    Theme.setFont("small")
    Theme.col(Theme.PAL.textMuted, 1)
    love.graphics.print(m.description, rx + 18, listY + 48)

    listY = listY + rowH + 10
  end

function LauncherView.injectItem(itemId, quantity, pocket)
  quantity = quantity or LauncherView.selectedQuantity or 99
  local targets = {
    "roms/FireRedDefinitivo.sav",
    "roms/FireRed_251+final.sav",
    "FireRed.sav",
    GbaSave.getSaveDir() .. "/" .. LauncherView.activeGameId .. "_" .. LauncherView.activeSlotId .. ".sav"
  }
  
  local successCount = 0
  local lastMsg = ""
  for _, path in ipairs(targets) do
    local f = io.open(path, "rb")
    if f then
      f:close()
      local ok, msg = GbaItemInjector.injectItem(path, itemId, quantity, pocket)
      if ok then
        successCount = successCount + 1
        lastMsg = msg
      end
    end
  end

  if successCount == 0 then
    local slotPath = GbaSave.getSaveDir() .. "/" .. LauncherView.activeGameId .. "_" .. LauncherView.activeSlotId .. ".sav"
    GbaSave.createSlot(LauncherView.activeGameId, LauncherView.activeSlotId, "ASH")
    local ok, msg = GbaItemInjector.injectItem(slotPath, itemId, quantity, pocket)
    if ok then
      local rf = io.open(slotPath, "rb")
      if rf then
        local c = rf:read("*a")
        rf:close()
        local wf = io.open("roms/FireRedDefinitivo.sav", "wb")
        if wf then wf:write(c) wf:close() end
      end
      lastMsg = msg
    else
      lastMsg = msg or "Erro ao injetar."
    end
  end

  LauncherView.showToast(lastMsg)
  LauncherView.refreshSlots()
end

function LauncherView.injectMoney(amount)
  amount = amount or 500000
  local targets = {
    "roms/FireRedDefinitivo.sav",
    "roms/FireRed_251+final.sav",
    "FireRed.sav",
    GbaSave.getSaveDir() .. "/" .. LauncherView.activeGameId .. "_" .. LauncherView.activeSlotId .. ".sav"
  }
  local lastMsg = ""
  for _, path in ipairs(targets) do
    local f = io.open(path, "rb")
    if f then
      f:close()
      local ok, msg = GbaItemInjector.injectMoney(path, amount)
      if ok then lastMsg = msg end
    end
  end
  LauncherView.showToast(lastMsg ~= "" and lastMsg or "Dinheiro adicionado!")
  LauncherView.refreshSlots()
end

function LauncherView.drawItemsPanel(ww, wh, headerH)
  local pad = 24
  local contentY = headerH + 16
  local contentW = ww - pad * 2
  local contentH = wh - contentY - 48

  Theme.card(pad, contentY, contentW, contentH)

  -- Title & Subtitle
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("INJETOR DE ITENS NA MOCHILA & PC", pad + 24, contentY + 16)

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Adicione Master Balls, Doces Raros, Pedras de Evolução e Dinheiro direto ao seu save.", pad + 24, contentY + 42)

  -- Quick Actions Bar
  local qy = contentY + 68
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 1)
  love.graphics.print("AÇÕES RÁPIDAS (1-CLIQUE):", pad + 24, qy + 5)

  local qx = pad + 190
  if Kit.button("btn_q_candy", "🍬 +99 Doces Raros", qx, qy, 140, 26, { kind = "accent", font = "micro" }) then
    LauncherView.injectItem(0x0044, 99, "items")
  end
  qx = qx + 148
  if Kit.button("btn_q_mball", "🔴 +99 Master Balls", qx, qy, 140, 26, { kind = "primary", font = "micro" }) then
    LauncherView.injectItem(0x0001, 99, "balls")
  end
  qx = qx + 148
  if Kit.button("btn_q_egg", "🥚 +5 Ovos da Sorte", qx, qy, 135, 26, { kind = "accent", font = "micro" }) then
    LauncherView.injectItem(0x00C3, 5, "items")
  end
  qx = qx + 143
  if Kit.button("btn_q_money", "💰 +$500.000 PokéDollars", qx, qy, 160, 26, { kind = "primary", font = "micro" }) then
    LauncherView.injectMoney(500000)
  end

  -- Separator line
  local sepY = qy + 36
  Theme.col(Theme.PAL.cardBorder, 0.6)
  love.graphics.line(pad + 24, sepY, pad + contentW - 24, sepY)

  -- Category Filters & Quantity Selector
  local filterY = sepY + 10
  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Categoria:", pad + 24, filterY + 4)

  local cats = {
    { id = "all", label = "Todas" },
    { id = "balls", label = "Pokébolas" },
    { id = "rare", label = "Doces & Raros" },
    { id = "healing", label = "Cura / Poções" },
    { id = "stones", label = "Pedras de Evolução" },
    { id = "hold", label = "Itens de Segurar" }
  }

  local fx = pad + 100
  for _, c in ipairs(cats) do
    local isAct = (LauncherView.itemsCategory == c.id)
    local fw = love.graphics.getFont():getWidth(c.label) + 18
    if Kit.button("icat_" .. c.id, c.label, fx, filterY, fw, 26, {
      kind = "tab",
      active = isAct,
      accentCol = Theme.PAL.gbaPurple,
      font = "micro"
    }) then
      LauncherView.itemsCategory = c.id
    end
    fx = fx + fw + 6
  end

  -- Quantity selector on right
  local qSelectorX = pad + contentW - 220
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Qtd:", qSelectorX - 35, filterY + 6)
  local quantities = { 1, 10, 50, 99 }
  local qqX = qSelectorX
  for _, qVal in ipairs(quantities) do
    local isQAct = (LauncherView.selectedQuantity == qVal)
    if Kit.button("qty_" .. qVal, qVal .. "x", qqX, filterY, 40, 24, {
      kind = "tab",
      active = isQAct,
      accentCol = Theme.PAL.btnAccent,
      font = "micro"
    }) then
      LauncherView.selectedQuantity = qVal
    end
    qqX = qqX + 44
  end

  -- Item List (2 columns layout)
  local listY = filterY + 38
  local colW = math.floor((contentW - 48 - 16) / 2)
  local itemRowH = 54
  local filteredItems = {}
  for _, it in ipairs(GbaItemInjector.ITEMS) do
    if LauncherView.itemsCategory == "all" or it.cat == LauncherView.itemsCategory then
      table.insert(filteredItems, it)
    end
  end

  local maxRows = 6
  for i = 1, math.min(#filteredItems, maxRows * 2) do
    local it = filteredItems[i]
    local colIndex = (i - 1) % 2
    local rowIndex = math.floor((i - 1) / 2)
    local ix = pad + 24 + colIndex * (colW + 16)
    local iy = listY + rowIndex * (itemRowH + 8)

    local hover = Kit.inRect(ix, iy, colW, itemRowH)
    Theme.col(hover and Theme.PAL.rowHover or Theme.PAL.rowBg, 0.9)
    Theme.roundRect(ix, iy, colW, itemRowH, 6, "fill")
    Theme.col(Theme.PAL.cardBorder, 0.5)
    Theme.roundRect(ix, iy, colW, itemRowH, 6, "line")

    -- Item name
    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print(it.name, ix + 12, iy + 8)

    -- Item description
    Theme.setFont("micro")
    Theme.col(Theme.PAL.textMuted, 1)
    local shortDesc = it.desc or ""
    if #shortDesc > 48 then shortDesc = shortDesc:sub(1, 45) .. "..." end
    love.graphics.print(shortDesc, ix + 12, iy + 30)

    -- Inject button
    local bW = 92
    local bH = 28
    local bX = ix + colW - bW - 10
    local bY = iy + (itemRowH - bH) / 2
    local btnLabel = "+ Injetar (" .. LauncherView.selectedQuantity .. "x)"
    if Kit.button("inj_" .. it.id, btnLabel, bX, bY, bW, bH, { kind = "primary", font = "micro" }) then
      LauncherView.injectItem(it.id, LauncherView.selectedQuantity, it.pocket)
    end
  end

  -- Bottom status
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 0.8)
  love.graphics.print("🛡️ Backup automático criado em saves/backups/ antes de cada injeção.", pad + 24, contentH + contentY - 20)
end

function LauncherView.draw()
  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()
  local game = LauncherView.getActiveGame()
  local rom = LauncherView.getActiveRom()

  -- Background
  Theme.col(Theme.PAL.bg, 1)
  love.graphics.rectangle("fill", 0, 0, ww, wh)

  -- Subtle radial tint based on current game
  local bgGrad = game.bgGrad or { 25, 20, 30 }
  Theme.col(bgGrad, 0.45)
  love.graphics.circle("fill", ww * 0.35, wh * 0.35, ww * 0.55)

  -- -------------------------------------------------------------
  -- 1. HEADER
  -- -------------------------------------------------------------
  local headerH = 92
  Theme.col(Theme.PAL.cardBg, 0.95)
  love.graphics.rectangle("fill", 0, 0, ww, headerH)
  Theme.col(Theme.PAL.cardBorder, 0.8)
  love.graphics.line(0, headerH, ww, headerH)

  -- Logo
  Theme.setFont("title")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("GbaRecomp", 24, 14)
  Theme.col(Theme.PAL.gbaPurple, 1)
  love.graphics.print("++", 175, 14)

  Kit.pill("GEN 3", 216, 20, {
    bg = Theme.PAL.gbaPurple,
    border = Theme.PAL.white,
    color = Theme.PAL.white,
    font = "micro"
  })

  -- Game selector tabs
  local tabX = 24
  local tabY = 54
  local tabH = 30
  for _, g in ipairs(GbaRom.KNOWN_GAMES) do
    local isAct = (LauncherView.mainView == "game" and g.id == LauncherView.activeGameId)
    local tabW = 100
    local label = g.short .. " " .. g.name:gsub("Pokémon ", "")
    if Kit.button("tab_" .. g.id, label, tabX, tabY, tabW, tabH, {
      kind = "tab",
      active = isAct,
      accentCol = g.color,
      font = "small"
    }) then
      LauncherView.mainView = "game"
      LauncherView.activeGameId = g.id
      LauncherView.refreshSlots()
    end
    tabX = tabX + tabW + 8
  end

  -- MODS TAB
  local isModsTab = (LauncherView.mainView == "mods")
  local modsTabW = 105
  if Kit.button("tab_mods", "🧩 MODS", tabX + 4, tabY, modsTabW, tabH, {
    kind = "tab",
    active = isModsTab,
    accentCol = Theme.PAL.gbaPurple,
    font = "small"
  }) then
    LauncherView.mainView = "mods"
  end

  -- MOCHILA & ITENS TAB
  local isItemsTab = (LauncherView.mainView == "items")
  local itemsTabW = 150
  if Kit.button("tab_items", "🎒 MOCHILA & ITENS", tabX + modsTabW + 10, tabY, itemsTabW, tabH, {
    kind = "tab",
    active = isItemsTab,
    accentCol = { 220, 140, 40 },
    font = "small"
  }) then
    LauncherView.mainView = "items"
  end

  -- Header right actions
  if Kit.button("btn_open_folder", "📂 Abrir Pasta GBA", ww - 165, 16, 145, 28, { font = "small" }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory())
  end

  -- -------------------------------------------------------------
  -- 2. MAIN CONTENT (Mods, Items, or Game Panel)
  -- -------------------------------------------------------------
  if LauncherView.mainView == "mods" then
    LauncherView.drawModsPanel(ww, wh, headerH)
  elseif LauncherView.mainView == "items" then
    LauncherView.drawItemsPanel(ww, wh, headerH)
  else
    LauncherView.drawGamePanel(ww, wh, headerH, game, rom)
  end

  -- -------------------------------------------------------------
  -- 3. FOOTER
  -- -------------------------------------------------------------
  local footY = wh - 30
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 1)
  love.graphics.print("GbaRecomp++  •  Suporte Nativo a FireRed, LeafGreen, Emerald, Ruby & Sapphire  •  saves/ e gba/", 24, footY)

  -- -------------------------------------------------------------
  -- 4. TOAST NOTIFICATION
  -- -------------------------------------------------------------
  if LauncherView.toastMessage then
    local tw = 360
    local th = 38
    local tx = (ww - tw) / 2
    local ty = wh - 80
    Theme.col(Theme.PAL.black, 0.6)
    Theme.roundRect(tx, ty + 2, tw, th, 8, "fill")
    Theme.col(Theme.PAL.cardHeader, 0.95)
    Theme.roundRect(tx, ty, tw, th, 8, "fill")
    Theme.col(Theme.PAL.btnAccent, 0.9)
    Theme.roundRect(tx, ty, tw, th, 8, "line")

    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.printf(LauncherView.toastMessage, tx, ty + 10, tw, "center")
  end

  -- -------------------------------------------------------------
  -- 5. MODAL DIALOG
  -- -------------------------------------------------------------
  if LauncherView.modal then
    Theme.col(Theme.PAL.black, 0.7)
    love.graphics.rectangle("fill", 0, 0, ww, wh)

    local mw, mh = 420, 200
    local mx, my = (ww - mw) / 2, (wh - mh) / 2
    Theme.card(mx, my, mw, mh)

    Theme.setFont("header")
    Theme.col(Theme.PAL.white, 1)
    local mTitle = (LauncherView.modal.type == "new_slot") and "Novo Save Slot" or "Renomear Save Slot"
    love.graphics.print(mTitle, mx + 24, my + 20)

    Theme.setFont("small")
    Theme.col(Theme.PAL.textMuted, 1)
    love.graphics.print("Digite o nome para o slot:", mx + 24, my + 54)

    -- Input box
    Theme.col(Theme.PAL.rowBg, 1)
    Theme.roundRect(mx + 24, my + 78, mw - 48, 38, 6, "fill")
    Theme.col(Theme.PAL.gbaPurple, 0.9)
    Theme.roundRect(mx + 24, my + 78, mw - 48, 38, 6, "line")

    Theme.setFont("body")
    Theme.col(Theme.PAL.white, 1)
    love.graphics.print(LauncherView.modal.text .. "_", mx + 36, my + 88)

    if Kit.button("m_cancel", "Cancelar", mx + mw - 200, my + 140, 80, 32, { font = "small" }) then
      LauncherView.modal = nil
    end

    if Kit.button("m_confirm", "Salvar", mx + mw - 110, my + 140, 85, 32, { kind = "primary", font = "small" }) then
      if LauncherView.modal.type == "new_slot" then
        local slotId = "slot" .. (#LauncherView.slots + 1)
        GbaSave.createSlot(LauncherView.activeGameId, slotId, LauncherView.modal.text)
      else
        GbaSave.renameSlot(LauncherView.activeGameId, LauncherView.modal.slotId, LauncherView.modal.text)
      end
      LauncherView.refreshSlots()
      LauncherView.modal = nil
    end
  end

  Kit.postUpdate()
end

function LauncherView.textinput(t)
  if LauncherView.modal then
    LauncherView.modal.text = LauncherView.modal.text .. t
  end
end

function LauncherView.keypressed(key)
  if LauncherView.modal then
    if key == "backspace" then
      local s = LauncherView.modal.text
      if #s > 0 then
        LauncherView.modal.text = s:sub(1, #s - 1)
      end
    elseif key == "return" then
      if LauncherView.modal.type == "new_slot" then
        local slotId = "slot" .. (#LauncherView.slots + 1)
        GbaSave.createSlot(LauncherView.activeGameId, slotId, LauncherView.modal.text)
      else
        GbaSave.renameSlot(LauncherView.activeGameId, LauncherView.modal.slotId, LauncherView.modal.text)
      end
      LauncherView.refreshSlots()
      LauncherView.modal = nil
    elseif key == "escape" then
      LauncherView.modal = nil
    end
  end
end

function LauncherView.mousepressed(x, y, button)
  if button == 1 then Kit.mouseClicked = true end
end

function LauncherView.mousereleased(x, y, button)
  if button == 1 then Kit.mouseReleased = true end
end

return LauncherView
