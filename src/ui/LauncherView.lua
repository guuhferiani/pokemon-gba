local Theme = require("src.ui.Theme")
local Kit = require("src.ui.Kit")
local GbaRom = require("src.core.GbaRom")
local GbaSave = require("src.core.GbaSave")
local GbaMods = require("src.core.GbaMods")
local GameCoverView = require("src.ui.GameCoverView")
local GbaItemInjector = require("src.core.GbaItemInjector")
local GbaShinyDex = require("src.core.GbaShinyDex")
local DexView = require("src.ui.DexView")
local utf8 = require("utf8")

local function utf8Truncate(str, maxChars)
  if not str then return "" end
  local len = utf8.len(str)
  if len and len > maxChars then
    local offset = utf8.offset(str, maxChars + 1)
    if offset then
      return string.sub(str, 1, offset - 1) .. "..."
    end
  end
  return str
end

local function utf8PopChar(s)
  if not s or s == "" then return "" end
  local byteoffset = utf8.offset(s, -1)
  if byteoffset then
    return string.sub(s, 1, byteoffset - 1)
  else
    return string.sub(s, 1, #s - 1)
  end
end

local LauncherView = {
  activeGameId = "kantojohto",
  mainView = "game", -- "game" | "mods" | "items" | "shiny" | "dex"
  modsFilter = nil,
  itemsCategory = "all",
  selectedQuantity = 99,
  shinyRate = "default",
  shinyScanResult = nil,
  dexData = nil,
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

function LauncherView.resolveActiveSavePath()
  -- 1. Check active slot save in saves/
  local slotPath = GbaSave.getSaveDir() .. "/" .. LauncherView.activeGameId .. "_" .. LauncherView.activeSlotId .. ".sav"
  local fSlot = io.open(slotPath, "rb")
  if fSlot then
    fSlot:close()
    return slotPath
  end

  -- 2. Check active ROM companion .sav
  local activeRom = LauncherView.getActiveRom()
  if activeRom and activeRom.displayPath then
    local compSav = activeRom.displayPath:gsub("%.%w+$", ".sav")
    local fComp = io.open(compSav, "rb")
    if fComp then
      fComp:close()
      return compSav
    end
  end

  -- 3. Check fallbacks
  local fallbacks = {
    "roms/" .. (activeRom and activeRom.filename and activeRom.filename:gsub("%.%w+$", ".sav") or "FireRedDefinitivo.sav"),
    "FireRed.sav",
    "roms/FireRedDefinitivo.sav",
    "roms/FireRed_251+final.sav",
    "roms/FireRed.sav"
  }
  for _, fp in ipairs(fallbacks) do
    local f = io.open(fp, "rb")
    if f then
      f:close()
      return fp
    end
  end

  return slotPath
end

function LauncherView.onFocus(focused)
  if focused then
    if GbaSave and GbaSave.syncSaveWithEmulator then
      if GbaSave.syncSaveWithEmulator(LauncherView.activeGameId) then
        LauncherView.refreshSlots()
      end
    end
  end
end

function LauncherView.update(dt)
  Kit.update(dt)

  -- Throttled Auto-Sync of emulator save file (every 1.5 seconds)
  LauncherView.saveSyncTimer = (LauncherView.saveSyncTimer or 0) + dt
  if LauncherView.saveSyncTimer >= 1.5 then
    LauncherView.saveSyncTimer = 0
    if GbaSave and GbaSave.syncSaveWithEmulator then
      if GbaSave.syncSaveWithEmulator(LauncherView.activeGameId) then
        LauncherView.refreshSlots()
      end
    end
  end

  if LauncherView.toastTimer > 0 then
    LauncherView.toastTimer = LauncherView.toastTimer - dt
    if LauncherView.toastTimer <= 0 then
      LauncherView.toastMessage = nil
    end
  end

  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()
  local leftW = math.floor(ww * 0.44)
  GameCoverView.update(dt, 24, 110, leftW, 260)
end

function LauncherView.drawGamePanel(ww, wh, headerH, game, rom)
  local contentY = headerH + 20
  local pad = 24
  local gap = 24
  local availableW = ww - pad * 2 - gap
  local leftW = math.floor(availableW * 0.44)
  local rightX = pad + leftW + gap
  local rightW = ww - pad - rightX

  -- Left Column: Game Title & Box Art
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print(game.name, pad, contentY)

  local romReady = (rom ~= nil)
  local pillLabel = romReady and "ROM PRONTA" or "ROM NÃO ENCONTRADA"
  local pillBg = romReady and { 25, 135, 65 } or { 140, 100, 20 }
  local titleW = love.graphics.getFont():getWidth(game.name)
  Kit.pill(pillLabel, pad + titleW + 14, contentY + 2, {
    bg = pillBg,
    color = Theme.PAL.white,
    font = "micro"
  })

  -- Authentic GBA Dual Cover Art (Charizard & Lugia)
  local cartAreaH = 260
  GameCoverView.draw(pad, contentY + 28, leftW, cartAreaH, game)

  -- Play & Cart Buttons
  local btnY = contentY + 28 + cartAreaH + 10
  local playText = romReady and ("JOGAR " .. game.name:upper()) or ("ROM " .. (game.defaultRomName or "GBA") .. " NÃO ENCONTRADA")
  local playW = romReady and (leftW - 130) or leftW
  if Kit.button("btn_play", playText, pad, btnY, playW, 40, {
    kind = romReady and "primary" or "neutral",
    icon = romReady and "play" or nil,
    disabled = not romReady,
    font = "body"
  }) then
    local romPath = rom and (rom.displayPath or rom.filepath)
    if romPath then
      GbaSave.setActiveSlot(LauncherView.activeGameId, LauncherView.activeSlotId, romPath)
      if GbaMods and GbaMods.syncCheatsFile then
        GbaMods.syncCheatsFile(romPath)
      end
      LauncherView.showToast("Slot " .. LauncherView.activeSlotId .. " ativado! Iniciando " .. game.name .. "...")

      -- Check if portable emulator is available
      local emuPaths = {
        "emulator/mGBA.exe",
        "gba/emulator/mGBA.exe",
        "emulator/mgba-sdl.exe",
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
        local winRom = romPath:gsub('/', '\\')
        os.execute('start "" "' .. winRom .. '"')
      end
    else
      LauncherView.showToast("Coloque a ROM " .. (game.defaultRomName or "") .. " na pasta roms/ para jogar!")
    end
  end

  if romReady then
    if Kit.button("btn_mods_folder", "MODS", pad + playW + 8, btnY, 122, 40, {
      kind = "accent",
      font = "small"
    }) then
      love.system.openURL("file://" .. love.filesystem.getWorkingDirectory() .. "/mods")
      LauncherView.showToast("Pasta mods/ aberta no Explorer!")
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
  local folder = rom and (rom.folder or "roms/") or "roms/"
  local displayPath = rom and (rom.displayPath or ("roms/" .. game.defaultRomName)) or ("roms/" .. game.defaultRomName)

  love.graphics.print("Pasta: " .. folder .. "  •  Arquivo: " .. (rom and rom.filename or (game.defaultRomName)), pad + 16, infoCardY + 36)
  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Caminho: " .. displayPath, pad + 16, infoCardY + 60)
  love.graphics.print("Código: " .. romCode .. "  •  Tamanho: " .. romSize .. "  •  GBA 32-bit ARM", pad + 16, infoCardY + 80)
  love.graphics.print("Status: " .. (romReady and "Pronto para jogar via mGBA" or "Coloque a ROM na pasta roms/"), pad + 16, infoCardY + 100)

  -- -------------------------------------------------------------
  -- -------------------------------------------------------------
  -- RIGHT COLUMN: KANTO & JOHTO CAMPAIGN & SAVE PROGRESS
  -- -------------------------------------------------------------
  local slotsCardH = wh - contentY - 60
  Theme.card(rightX, contentY, rightW, slotsCardH)

  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("STATUS DA JORNADA", rightX + 20, contentY + 18)

  Kit.pill("KANTO ➔ JOHTO", rightX + 225, contentY + 22, {
    bg = { 180, 130, 20 },
    color = Theme.PAL.white,
    font = "micro"
  })

  if Kit.button("btn_import_save", "+ Importar .sav", rightX + rightW - 145, contentY + 16, 125, 30, {
    kind = "accent",
    font = "small"
  }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory() .. "/saves")
    LauncherView.showToast("Coloque o seu arquivo .sav na pasta de saves aberta!")
  end

  -- Active Trainer Hero Card (Real Save Data)
  local heroY = contentY + 58
  local heroW = rightW - 40
  local heroH = 100
  local heroX = rightX + 20

  local activeSlot = nil
  for _, s in ipairs(LauncherView.slots) do
    if s.id == LauncherView.activeSlotId then activeSlot = s break end
  end

  Theme.col(Theme.PAL.rowBg, 1)
  Theme.roundRect(heroX, heroY, heroW, heroH, 8, "fill")
  Theme.col(game.color or Theme.PAL.gbaPurple, 0.8)
  Theme.roundRect(heroX, heroY, heroW, heroH, 8, "line")

  local trainerName = (activeSlot and activeSlot.name) or "GU"
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print(trainerName, heroX + 18, heroY + 14)

  Kit.pill("SAVE ATIVO", heroX + heroW - 105, heroY + 14, {
    bg = { 20, 140, 60 },
    color = Theme.PAL.white,
    font = "micro"
  })

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  local playTime = (activeSlot and activeSlot.playTime) or "00:00"
  local caughtCount = (activeSlot and activeSlot.caught) or 0
  local stats = "Tempo de Jogo: " .. playTime .. "  •  Pokédex: " .. caughtCount .. " capturados"
  love.graphics.print(stats, heroX + 18, heroY + 40)

  local actBtnY = heroY + 64
  local actBtnW = 75
  local actBtnH = 26

  if Kit.button("act_export", "Exportar", heroX + heroW - 255, actBtnY, actBtnW, actBtnH, { kind = "accent", font = "small" }) then
    LauncherView.showToast("Save exportado para saves/" .. game.id .. "_" .. (activeSlot and activeSlot.id or "slot1") .. ".sav")
  end

  if Kit.button("act_rename", "Renomear", heroX + heroW - 170, actBtnY, actBtnW, actBtnH, { font = "small" }) then
    if activeSlot then
      LauncherView.modal = { type = "rename", slotId = activeSlot.id, text = activeSlot.name }
    end
  end

  if Kit.button("act_delete", "Excluir", heroX + heroW - 85, actBtnY, actBtnW, actBtnH, { kind = "danger", font = "small" }) then
    if activeSlot then
      GbaSave.deleteSlot(game.id, activeSlot.id)
      LauncherView.refreshSlots()
      LauncherView.showToast("Slot excluído.")
    end
  end

  -- -------------------------------------------------------------
  -- PROGRESSION CARD: KANTO & JOHTO LEAGUES
  -- -------------------------------------------------------------
  local progY = heroY + heroH + 14
  local progH = 145
  Theme.col(Theme.PAL.cardHeader, 0.7)
  Theme.roundRect(heroX, progY, heroW, progH, 8, "fill")
  Theme.col(Theme.PAL.cardBorder, 0.6)
  Theme.roundRect(heroX, progY, heroW, progH, 8, "line")

  -- Kanto Badges Section
  Theme.setFont("body")
  Theme.col(Theme.PAL.white, 1)
  local kBadges = (activeSlot and activeSlot.kantoBadges) or 0
  love.graphics.print("Região 1: Kanto (Gen 1)", heroX + 16, progY + 12)
  Kit.pill(kBadges .. " / 8 Insígnias", heroX + heroW - 115, progY + 12, {
    bg = kBadges == 8 and { 20, 140, 60 } or { 50, 60, 75 },
    color = Theme.PAL.white,
    font = "micro"
  })

  -- Draw 8 Kanto Badge circles
  local kantoColors = {
    { 160, 160, 160 }, -- Pewter (Stone)
    { 60, 140, 240 },  -- Cerulean (Cascade)
    { 240, 200, 30 },  -- Vermilion (Thunder)
    { 50, 190, 80 },   -- Celadon (Rainbow)
    { 230, 80, 150 },  -- Fuchsia (Soul)
    { 230, 160, 40 },  -- Saffron (Marsh)
    { 230, 60, 40 },   -- Cinnabar (Volcano)
    { 40, 120, 60 }    -- Viridian (Earth)
  }
  local bx = heroX + 16
  local by = progY + 38
  for bIdx = 1, 8 do
    local hasBadge = (kBadges >= bIdx)
    local bCol = kantoColors[bIdx]
    if hasBadge then
      love.graphics.setColor(bCol[1]/255, bCol[2]/255, bCol[3]/255, 1)
      love.graphics.circle("fill", bx + 12, by + 10, 8)
    else
      love.graphics.setColor(0.3, 0.35, 0.4, 0.6)
      love.graphics.circle("line", bx + 12, by + 10, 8)
    end
    bx = bx + 28
  end

  -- Johto Badges Section
  local jProgY = progY + 70
  Theme.col(Theme.PAL.cardBorder, 0.4)
  love.graphics.line(heroX + 16, jProgY, heroX + heroW - 16, jProgY)

  Theme.setFont("body")
  Theme.col(Theme.PAL.white, 1)
  local jBadges = (activeSlot and activeSlot.johtoBadges) or 0
  love.graphics.print("Região 2: Johto (Níveis 58 a 87)", heroX + 16, jProgY + 12)
  Kit.pill(jBadges .. " / 8 Insígnias", heroX + heroW - 115, jProgY + 12, {
    bg = jBadges == 8 and { 20, 140, 60 } or { 80, 60, 20 },
    color = Theme.PAL.white,
    font = "micro"
  })

  local johtoColors = {
    { 140, 180, 230 }, -- Zephyr
    { 140, 200, 70 },  -- Hive
    { 240, 140, 180 }, -- Plain
    { 130, 90, 180 },  -- Fog
    { 180, 110, 60 },  -- Storm
    { 180, 190, 200 }, -- Mineral
    { 100, 220, 230 }, -- Glacier
    { 80, 80, 210 }    -- Rising
  }
  bx = heroX + 16
  by = jProgY + 38
  for bIdx = 1, 8 do
    local hasBadge = (jBadges >= bIdx)
    local bCol = johtoColors[bIdx]
    if hasBadge then
      love.graphics.setColor(bCol[1]/255, bCol[2]/255, bCol[3]/255, 1)
      love.graphics.circle("fill", bx + 12, by + 10, 8)
    else
      love.graphics.setColor(0.3, 0.35, 0.4, 0.6)
      love.graphics.circle("line", bx + 12, by + 10, 8)
    end
    bx = bx + 28
  end

  -- Johto badge circles are read-only (reflect save data)

  -- -------------------------------------------------------------
  -- SLOTS LIST & NEW SLOT
  -- -------------------------------------------------------------
  local listY = progY + progH + 14
  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("GERENCIADOR DE SLOTS", heroX, listY)
  listY = listY + 22

  local remainingSlots = 0
  for _, s in ipairs(LauncherView.slots) do
    if s.id ~= LauncherView.activeSlotId and remainingSlots < 3 then
      remainingSlots = remainingSlots + 1
      local rowH = 40
      local hover = Kit.inRect(heroX, listY, heroW, rowH)
      Theme.col(hover and Theme.PAL.rowHover or Theme.PAL.rowBg, 0.8)
      Theme.roundRect(heroX, listY, heroW, rowH, 6, "fill")
      Theme.col(Theme.PAL.cardBorder, 0.5)
      Theme.roundRect(heroX, listY, heroW, rowH, 6, "line")

      Theme.setFont("body")
      Theme.col(Theme.PAL.text, 1)
      love.graphics.print(s.name, heroX + 16, listY + 6)

      Theme.setFont("micro")
      Theme.col(Theme.PAL.textMuted, 1)
      love.graphics.print("Tempo: " .. (s.playTime or "00:00"), heroX + 16, listY + 23)

      if Kit.button("load_" .. s.id, "Carregar", heroX + heroW - 85, listY + 7, 75, 26, { font = "small" }) then
        GbaSave.setActiveSlot(game.id, s.id, rom and rom.filepath)
        LauncherView.refreshSlots()
        LauncherView.showToast("Slot " .. s.name .. " ativado!")
      end

      listY = listY + rowH + 6
    end
  end

  -- + New Save Slot Button
  local newSlotBtnY = slotsCardH + contentY - 48
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
  if Kit.button("btn_open_mods_dir", "Pasta mods/", pad + contentW - btnW * 2 - 34, contentY + 18, btnW, 32, { kind = "accent", font = "small" }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory() .. "/mods")
    LauncherView.showToast("Pasta mods/ aberta no Explorer!")
  end

  if Kit.button("btn_online_mods", "Índice da Comunidade", pad + contentW - btnW - 20, contentY + 18, btnW, 32, { kind = "primary", font = "small" }) then
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
    local tText = m.enabled and "ATIVO" or "DESATIVADO"

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

  -- Bottom hint
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 0.8)
  love.graphics.print("💡 Dica: Novos patches (.ips, .bps) e mods colocados em gba/mods/ são reconhecidos e listados automaticamente.", pad + 24, contentH + contentY - 24)
end

function LauncherView.syncSaveData(primarySave, data)
  if not data then return end
  
  if love and love.filesystem then
    love.filesystem.createDirectory(GbaSave.getSaveDir())
  else
    os.execute('mkdir "' .. GbaSave.getSaveDir() .. '" 2>nul')
  end

  local slotPath = GbaSave.getSaveDir() .. "/" .. LauncherView.activeGameId .. "_" .. LauncherView.activeSlotId .. ".sav"
  local fSlot = io.open(slotPath, "wb")
  if fSlot then fSlot:write(data) fSlot:close() end

  local activeRom = LauncherView.getActiveRom()
  if activeRom and activeRom.displayPath then
    local compSav = activeRom.displayPath:gsub("%.%w+$", ".sav")
    if compSav ~= primarySave and compSav ~= slotPath then
      local fComp = io.open(compSav, "wb")
      if fComp then fComp:write(data) fComp:close() end
    end
  end

  if primarySave and primarySave ~= slotPath then
    local fPri = io.open(primarySave, "wb")
    if fPri then fPri:write(data) fPri:close() end
  end
end

function LauncherView.injectItem(itemId, quantity, pocket)
  quantity = quantity or LauncherView.selectedQuantity or 99
  local primarySave = LauncherView.resolveActiveSavePath()

  local ok, msg = GbaItemInjector.injectItem(primarySave, itemId, quantity, pocket)
  if ok then
    local fRead = io.open(primarySave, "rb")
    if fRead then
      local data = fRead:read("*a")
      fRead:close()
      LauncherView.syncSaveData(primarySave, data)
    end
    LauncherView.showToast(tostring(msg))
  else
    LauncherView.showToast(tostring(msg or "Erro ao injetar item."))
  end
  LauncherView.refreshSlots()
end

function LauncherView.injectMoney(amount)
  amount = amount or 500000
  local primarySave = LauncherView.resolveActiveSavePath()

  local ok, msg = GbaItemInjector.injectMoney(primarySave, amount)
  if ok then
    local fRead = io.open(primarySave, "rb")
    if fRead then
      local data = fRead:read("*a")
      fRead:close()
      LauncherView.syncSaveData(primarySave, data)
    end
    LauncherView.showToast(tostring(msg))
  else
    LauncherView.showToast(tostring(msg or "Erro ao adicionar dinheiro."))
  end
  LauncherView.refreshSlots()
end

function LauncherView.unlockNationalDex()
  local primarySave = LauncherView.resolveActiveSavePath()

  local ok, msg = GbaItemInjector.unlockNationalDex(primarySave)
  if ok then
    local fRead = io.open(primarySave, "rb")
    if fRead then
      local data = fRead:read("*a")
      fRead:close()
      LauncherView.syncSaveData(primarySave, data)
    end
    LauncherView.showToast("Pokédex Nacional desbloqueada com sucesso!")
  else
    LauncherView.showToast(tostring(msg or "Erro ao desbloquear National Dex."))
  end
  LauncherView.refreshSlots()
end

function LauncherView.unlockKantoChampAndJohto()
  local primarySave = LauncherView.resolveActiveSavePath()
  local ok, msg = GbaItemInjector.unlockKantoChampAndJohto(primarySave)
  if ok then
    local fRead = io.open(primarySave, "rb")
    if fRead then
      local data = fRead:read("*a")
      fRead:close()
      LauncherView.syncSaveData(primarySave, data)
    end
    LauncherView.showToast("Kanto concluído! 8 Insígnias, Hall da Fama e Johto liberados!")
  else
    LauncherView.showToast(tostring(msg or "Erro ao desbloquear."))
  end
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
  love.graphics.print("AÇÕES RÁPIDAS:", pad + 24, qy + 5)

  local qx = pad + 130
  if Kit.button("btn_q_candy", "+99 Doces", qx, qy, 90, 26, { kind = "accent", font = "micro" }) then
    LauncherView.injectItem(0x0044, 99, "items")
  end
  qx = qx + 96
  if Kit.button("btn_q_mball", "+99 Master", qx, qy, 95, 26, { kind = "primary", font = "micro" }) then
    LauncherView.injectItem(0x0001, 99, "balls")
  end
  qx = qx + 101
  if Kit.button("btn_q_money", "+$500.000", qx, qy, 90, 26, { kind = "primary", font = "micro" }) then
    LauncherView.injectMoney(500000)
  end
  qx = qx + 96
  if Kit.button("btn_q_natdex", "Liberar Dex (386)", qx, qy, 125, 26, { kind = "accent", font = "micro" }) then
    LauncherView.unlockNationalDex()
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
    local shortDesc = utf8Truncate(it.desc or "", 36)
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

function LauncherView.refreshShinies()
  local savePath = LauncherView.resolveActiveSavePath()
  local f = io.open(savePath, "rb")
  if f then
    f:close()
    LauncherView.shinyScanResult = GbaShinyDex.scanSave(savePath)
    return
  end
  LauncherView.shinyScanResult = { shinies = {}, totalPokemon = 0, totalShinies = 0 }
end

function LauncherView.refreshDex()
  local savePath = LauncherView.resolveActiveSavePath()
  DexView.refresh(savePath)
  LauncherView.dexData = DexView.dexData
end

function LauncherView.drawDexPanel(ww, wh, headerH)
  if not DexView.dexData then
    LauncherView.refreshDex()
  end

  local pad = 24
  local contentY = headerH + 16
  local contentW = ww - pad * 2
  local contentH = wh - contentY - 48

  Theme.card(pad, contentY, contentW, contentH)

  -- Botão de atualização no canto superior direito do card
  if Kit.button("btn_dex_refresh", "🔄 Atualizar", pad + contentW - 85, contentY + 15, 65, 24, { kind = "accent", font = "micro" }) then
    LauncherView.refreshDex()
    LauncherView.showToast("Pokédex atualizada do save!")
  end

  -- Delega o desenho ao componente DexView
  DexView.draw(pad, contentY, contentW, contentH)
end

function LauncherView.drawShinyPanel(ww, wh, headerH)
  if not LauncherView.shinyScanResult then
    LauncherView.refreshShinies()
  end

  local pad = 24
  local contentY = headerH + 16
  local contentW = ww - pad * 2
  local contentH = wh - contentY - 48

  Theme.card(pad, contentY, contentW, contentH)

  -- Header Title
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("✨ REGISTRO DE POKÉMON SHINY (SHINYDEX)", pad + 24, contentY + 16)

  local scan = LauncherView.shinyScanResult or { shinies = {}, totalPokemon = 0, totalShinies = 0 }
  local pillLabel = string.format("✨ %d Shinies  •  %d Pokémon Registrados", scan.totalShinies, scan.totalPokemon)
  Kit.pill(pillLabel, pad + contentW - 270, contentY + 16, {
    bg = { 130, 95, 20 },
    color = { 255, 235, 120 },
    font = "micro"
  })

  if Kit.button("btn_refresh_shiny", "🔄 Atualizar", pad + contentW - 85, contentY + 15, 65, 24, { kind = "accent", font = "micro" }) then
    LauncherView.refreshShinies()
    LauncherView.showToast("Save escaneado! " .. scan.totalShinies .. " Shiny(s) encontrados.")
  end

  Theme.setFont("small")
  Theme.col(Theme.PAL.textMuted, 1)
  love.graphics.print("Gerencie a taxa de aparição de Shinies e acompanhe seus monstrinhos raros capturados.", pad + 24, contentY + 42)

  -- Top Section: Shiny Rate Selector
  local rateY = contentY + 68
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 1)
  love.graphics.print("TAXA DE APARIÇÃO DE SHINY:", pad + 24, rateY + 5)

  local rx = pad + 195
  for _, r in ipairs(GbaShinyDex.RATES) do
    local isAct = (LauncherView.shinyRate == r.id)
    local bw = love.graphics.getFont():getWidth(r.label) + 16
    if Kit.button("srate_" .. r.id, r.label, rx, rateY, bw, 26, {
      kind = "tab",
      active = isAct,
      accentCol = { 240, 190, 40 },
      font = "micro"
    }) then
      LauncherView.shinyRate = r.id
      LauncherView.showToast("Taxa de Shiny configurada para: " .. r.label)
    end
    rx = rx + bw + 6
  end

  -- Rate description hint
  local curRateDef = nil
  for _, r in ipairs(GbaShinyDex.RATES) do
    if r.id == LauncherView.shinyRate then curRateDef = r break end
  end
  local rateDesc = curRateDef and curRateDef.desc or ""
  local sepY = rateY + 34
  Theme.setFont("micro")
  Theme.col(Theme.PAL.amber, 0.9)
  love.graphics.print("ℹ️ " .. rateDesc, pad + 24, sepY)

  -- Separator line
  local lineY = sepY + 18
  Theme.col(Theme.PAL.cardBorder, 0.6)
  love.graphics.line(pad + 24, lineY, pad + contentW - 24, lineY)

  -- Bottom Section: Shinies Gallery
  local galY = lineY + 12
  Theme.setFont("header")
  Theme.col(Theme.PAL.white, 1)
  love.graphics.print("SHINIES CAPTURADOS", pad + 24, galY)

  local listY = galY + 32
  local colW = math.floor((contentW - 48 - 16) / 2)
  local rowH = 64

  if #scan.shinies == 0 then
    -- Empty State Card
    local emptyH = 130
    Theme.col(Theme.PAL.cardHeader, 0.6)
    Theme.roundRect(pad + 24, listY, contentW - 48, emptyH, 8, "fill")
    Theme.col({ 180, 130, 30 }, 0.5)
    Theme.roundRect(pad + 24, listY, contentW - 48, emptyH, 8, "line")

    Theme.setFont("body")
    Theme.col(Theme.PAL.amber, 1)
    love.graphics.print("✨ Nenhum Pokémon Shiny capturado ainda neste Save!", pad + 44, listY + 28)

    Theme.setFont("small")
    Theme.col(Theme.PAL.textMuted, 1)
    love.graphics.print("• Escolha uma taxa de aparição mais alta acima (ex: 1/512 ou 100% para teste).", pad + 44, listY + 56)
    love.graphics.print("• Entre na grama alta no jogo, capture o Pokémon e salve o jogo.", pad + 44, listY + 76)
    love.graphics.print("• Ao voltar nesta tela e clicar em 🔄 Atualizar, seu Shiny aparecerá registrado aqui!", pad + 44, listY + 96)
  else
    -- Shinies Cards Grid
    local maxShinies = 8
    for i = 1, math.min(#scan.shinies, maxShinies) do
      local sMon = scan.shinies[i]
      local colIndex = (i - 1) % 2
      local rowIndex = math.floor((i - 1) / 2)
      local sx = pad + 24 + colIndex * (colW + 16)
      local sy = listY + rowIndex * (rowH + 8)

      local hover = Kit.inRect(sx, sy, colW, rowH)
      Theme.col(hover and { 45, 38, 25 } or { 32, 28, 20 }, 0.95)
      Theme.roundRect(sx, sy, colW, rowH, 6, "fill")
      Theme.col({ 220, 175, 45 }, 0.8)
      Theme.roundRect(sx, sy, colW, rowH, 6, "line")

      -- Shiny badge
      Kit.pill("✨ SHINY", sx + 10, sy + 10, {
        bg = { 180, 135, 25 },
        color = Theme.PAL.white,
        font = "micro"
      })

      -- Name & Nickname
      Theme.setFont("body")
      Theme.col(Theme.PAL.white, 1)
      local dispTitle = string.format("%s (#%03d)", sMon.speciesName, sMon.speciesId)
      if sMon.nickname ~= sMon.speciesName then
        dispTitle = dispTitle .. ' "' .. sMon.nickname .. '"'
      end
      love.graphics.print(dispTitle, sx + 75, sy + 10)

      -- Stats line
      Theme.setFont("small")
      Theme.col(Theme.PAL.textMuted, 1)
      local statStr = string.format("Nv. %d  •  Natureza: %s  •  Local: %s", sMon.level, sMon.nature, sMon.location)
      love.graphics.print(statStr, sx + 12, sy + 36)
    end
  end

  -- Bottom status
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 0.8)
  love.graphics.print("🌟 Todos os dados são sincronizados em tempo real com o arquivo .sav do jogo.", pad + 24, contentH + contentY - 20)
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
  love.graphics.print("Pokémon Kanto & Johto", 24, 14)
  Theme.col({ 255, 215, 80 }, 1)
  local logoTextW = love.graphics.getFont():getWidth("Pokémon Kanto & Johto")
  love.graphics.print("++", 24 + logoTextW + 4, 14)

  Kit.pill("DEFINITIVE 32MB", 24 + logoTextW + 36, 20, {
    bg = { 160, 110, 20 },
    border = Theme.PAL.white,
    color = Theme.PAL.white,
    font = "micro"
  })

  -- Navigation tabs
  local tabX = 24
  local tabY = 54
  local tabH = 30

  local isGameTab = (LauncherView.mainView == "game")
  local gameTabW = 135
  if Kit.button("tab_main_game", "VISÃO DO JOGO", tabX, tabY, gameTabW, tabH, {
    kind = "tab",
    active = isGameTab,
    accentCol = { 215, 155, 30 },
    font = "small"
  }) then
    LauncherView.mainView = "game"
    LauncherView.refreshSlots()
  end

  local isModsTab = (LauncherView.mainView == "mods")
  local modsTabW = 105
  if Kit.button("tab_mods", "MODS & QoL", tabX + gameTabW + 8, tabY, modsTabW, tabH, {
    kind = "tab",
    active = isModsTab,
    accentCol = Theme.PAL.gbaPurple,
    font = "small"
  }) then
    LauncherView.mainView = "mods"
  end

  local isItemsTab = (LauncherView.mainView == "items")
  local itemsTabW = 135
  if Kit.button("tab_items", "MOCHILA & ITENS", tabX + gameTabW + modsTabW + 16, tabY, itemsTabW, tabH, {
    kind = "tab",
    active = isItemsTab,
    accentCol = { 220, 140, 40 },
    font = "small"
  }) then
    LauncherView.mainView = "items"
  end

  local isShinyTab = (LauncherView.mainView == "shiny")
  local shinyTabW = 110
  if Kit.button("tab_shiny", "SHINYDEX", tabX + gameTabW + modsTabW + itemsTabW + 24, tabY, shinyTabW, tabH, {
    kind = "tab",
    active = isShinyTab,
    accentCol = { 245, 195, 45 },
    font = "small"
  }) then
    LauncherView.mainView = "shiny"
    LauncherView.refreshShinies()
  end

  local isDexTab = (LauncherView.mainView == "dex")
  local dexTabW = 100
  if Kit.button("tab_dex", "POKÉDEX", tabX + gameTabW + modsTabW + itemsTabW + shinyTabW + 32, tabY, dexTabW, tabH, {
    kind = "tab",
    active = isDexTab,
    accentCol = { 120, 200, 80 },
    font = "small"
  }) then
    LauncherView.mainView = "dex"
    LauncherView.refreshDex()
  end

  -- Header right actions
  if Kit.button("btn_open_mods_folder", "Pasta Mods", ww - 275, 16, 120, 28, { kind = "primary", font = "small" }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory() .. "/mods")
    LauncherView.showToast("Pasta mods/ aberta no Explorer!")
  end

  if Kit.button("btn_open_folder", "Pasta GBA", ww - 145, 16, 125, 28, { font = "small" }) then
    love.system.openURL("file://" .. love.filesystem.getWorkingDirectory())
  end

  -- -------------------------------------------------------------
  -- 2. MAIN CONTENT (Mods, Items, Shiny, or Game Panel)
  -- -------------------------------------------------------------
  if LauncherView.mainView == "mods" then
    LauncherView.drawModsPanel(ww, wh, headerH)
  elseif LauncherView.mainView == "items" then
    LauncherView.drawItemsPanel(ww, wh, headerH)
  elseif LauncherView.mainView == "shiny" then
    LauncherView.drawShinyPanel(ww, wh, headerH)
  elseif LauncherView.mainView == "dex" then
    LauncherView.drawDexPanel(ww, wh, headerH)
  else
    LauncherView.drawGamePanel(ww, wh, headerH, game, rom)
  end

  -- -------------------------------------------------------------
  -- 3. FOOTER
  -- -------------------------------------------------------------
  local footY = wh - 30
  Theme.setFont("micro")
  Theme.col(Theme.PAL.textDim, 1)
  love.graphics.print("Pokémon Kanto & Johto Studio++  •  Edição Definitiva 32MB  •  saves/ e roms/  •  mGBA Integrado", 24, footY)

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
      LauncherView.modal.text = utf8PopChar(LauncherView.modal.text)
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

function LauncherView.wheelmoved(x, y)
  if LauncherView.mainView == "dex" then
    DexView.scroll(y)
  end
end

function LauncherView.mousereleased(x, y, button)
  if button == 1 then Kit.mouseReleased = true end
end

return LauncherView
