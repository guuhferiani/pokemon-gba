local GbaSave = {}

-- Character encoding for Pokemon Gen 3 English (offsets 0xBB - 0xD4 = A-Z, 0xD5 - 0xEE = a-z, 0xA1 - 0xAA = 0-9)
local GEN3_CHARS = {}
for i = 0, 255 do GEN3_CHARS[i] = "?" end
GEN3_CHARS[0x00] = " "
local upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
for i = 1, #upper do
  GEN3_CHARS[0xBB + i - 1] = upper:sub(i, i)
end
local lower = "abcdefghijklmnopqrstuvwxyz"
for i = 1, #lower do
  GEN3_CHARS[0xD5 + i - 1] = lower:sub(i, i)
end
local digits = "0123456789"
for i = 1, #digits do
  GEN3_CHARS[0xA1 + i - 1] = digits:sub(i, i)
end
GEN3_CHARS[0xFF] = "" -- terminator

local function decodeGen3String(bytes)
  local str = ""
  for i = 1, #bytes do
    local b = string.byte(bytes, i)
    if b == 0xFF then break end
    str = str .. (GEN3_CHARS[b] or "")
  end
  return str:match("^%s*(.-)%s*$")
end

local function ensureDir(path)
  if love.filesystem then
    love.filesystem.createDirectory(path)
  else
    os.execute('mkdir "' .. path:gsub('/', '\\') .. '" 2>nul')
  end
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function writeFile(path, content)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

function GbaSave.inspectSaveFile(filepath)
  local f = io.open(filepath, "rb")
  if not f then return nil end
  local size = f:seek("end")
  if size < 4096 then
    f:close()
    return { name = "Novo Slot", playTime = "00:00", badges = 0 }
  end

  -- Search Section 0 & 1 in Slot A (0x0000) and Slot B (0xE000)
  local bestSec0 = nil
  local bestSec1 = nil
  local highestSaveIndex = -1

  local function checkChunk(offset)
    f:seek("set", offset + 0x0FF4)
    local headerBytes = f:read(12)
    if not headerBytes or #headerBytes < 12 then return end
    local secId = string.byte(headerBytes, 1) + string.byte(headerBytes, 2) * 256
    local sig = string.byte(headerBytes, 5) + string.byte(headerBytes, 6) * 256
      + string.byte(headerBytes, 7) * 65536 + string.byte(headerBytes, 8) * 16777216
    local saveIndex = string.byte(headerBytes, 9) + string.byte(headerBytes, 10) * 256
      + string.byte(headerBytes, 11) * 65536 + string.byte(headerBytes, 12) * 16777216

    if sig == 0x08012025 then
      if secId == 0 and saveIndex > highestSaveIndex then
        highestSaveIndex = saveIndex
        bestSec0 = offset
      end
      if secId == 1 then
        bestSec1 = offset
      end
    end
  end

  for i = 0, 13 do checkChunk(i * 4096) end
  for i = 0, 13 do checkChunk(0xE000 + i * 4096) end

  if not bestSec0 then
    f:close()
    return { name = "Treinador", playTime = "00:00", badges = 0, kantoBadges = 0, johtoBadges = 0, caught = 0, isChampion = false, valid = false }
  end

  -- Read Section 0 (Trainer Name, Time, Pokedex)
  f:seek("set", bestSec0)
  local sec0 = f:read(4096)
  if not sec0 or #sec0 < 0x60 then
    f:close()
    return { name = "Treinador", playTime = "00:00", badges = 0, kantoBadges = 0, johtoBadges = 0, caught = 0, isChampion = false, valid = false }
  end

  local nameBytes = sec0:sub(1, 7)
  local trainerName = decodeGen3String(nameBytes)
  if not trainerName or #trainerName == 0 then trainerName = "GU" end

  local hours = string.byte(sec0, 0x0F) + string.byte(sec0, 0x10) * 256
  local minutes = string.byte(sec0, 0x11)
  local playTime = string.format("%02d:%02d", hours, minutes)

  -- Count caught in Pokedex (bytes 0x0028 to 0x0058)
  local caught = 0
  for b = 0x28, 0x58 do
    local byteVal = string.byte(sec0, b + 1) or 0
    while byteVal > 0 do
      if byteVal % 2 == 1 then caught = caught + 1 end
      byteVal = math.floor(byteVal / 2)
    end
  end

  -- Read Section 1 (Badges and Hall of Fame clear)
  local kantoBadges = 0
  local isChampion = false
  if bestSec1 then
    f:seek("set", bestSec1)
    local sec1 = f:read(4096)
    if sec1 and #sec1 >= 0x0FF0 then
      -- Badges byte at flags offset + 0x104 (FLAG_BADGE01..08 = 0x820..0x827)
      local badgeByte = string.byte(sec1, 0x0EE0 + 0x104 + 1) or 0
      for bit = 0, 7 do
        if math.floor(badgeByte / (2^bit)) % 2 == 1 then
          kantoBadges = kantoBadges + 1
        end
      end
      -- FLAG_SYS_GAME_CLEAR = 0x82C (Hall of Fame)
      local clearByte = string.byte(sec1, 0x0EE0 + 0x105 + 1) or 0
      if math.floor(clearByte / 16) % 2 == 1 then
        isChampion = true
      end
    end
  end

  f:close()

  return {
    name = trainerName,
    playTime = playTime,
    saveIndex = highestSaveIndex,
    caught = caught,
    badges = kantoBadges,
    kantoBadges = kantoBadges,
    johtoBadges = 0,
    isChampion = isChampion,
    valid = true
  }
end

function GbaSave.getSaveDir()
  return "saves"
end

function GbaSave.getManifestPath()
  return GbaSave.getSaveDir() .. "/manifest.json"
end

function GbaSave.loadManifest()
  ensureDir(GbaSave.getSaveDir())
  local content = readFile(GbaSave.getManifestPath())
  if not content then
    return { activeSlots = {}, customNames = {} }
  end
  -- Simple json parser for our manifest
  local active = {}
  local names = {}
  for game, slot in content:gmatch('"active_([%w_]+)"%s*:%s*"([^"]+)"') do
    active[game] = slot
  end
  for slotId, name in content:gmatch('"name_([%w_]+)"%s*:%s*"([^"]+)"') do
    names[slotId] = name
  end
  return { activeSlots = active, customNames = names }
end

function GbaSave.saveManifest(manifest)
  ensureDir(GbaSave.getSaveDir())
  local lines = { "{" }
  for k, v in pairs(manifest.activeSlots or {}) do
    table.insert(lines, string.format('  "active_%s": "%s",', k, v))
  end
  for k, v in pairs(manifest.customNames or {}) do
    table.insert(lines, string.format('  "name_%s": "%s",', k, v))
  end
  table.insert(lines, '  "version": 1')
  table.insert(lines, "}")
  writeFile(GbaSave.getManifestPath(), table.concat(lines, "\n"))
end

function GbaSave.syncSaveWithEmulator(gameId)
  local manifest = GbaSave.loadManifest()
  local activeSlotId = manifest.activeSlots[gameId] or "slot1"
  local slotPath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. activeSlotId .. ".sav"

  local candidates = {
    "roms/Pokemon_Kanto_Johto.sav",
    "Pokemon_Kanto_Johto.sav",
    "roms/FireRedDefinitivo.sav",
    "FireRed.sav"
  }

  for _, c in ipairs(candidates) do
    local f = io.open(c, "rb")
    if f then
      local size = f:seek("end")
      f:seek("set", 0)
      local content = f:read("*a")
      f:close()

      if content and #content >= 4096 then
        local slotContent = readFile(slotPath)
        if not slotContent or #slotContent ~= #content or slotContent ~= content then
          writeFile(slotPath, content)
          return true
        end
        return false
      end
    end
  end
  return false
end

function GbaSave.listSlots(gameId)
  GbaSave.syncSaveWithEmulator(gameId)
  local manifest = GbaSave.loadManifest()
  local activeSlotId = manifest.activeSlots[gameId] or "slot1"
  local slots = {}

  -- Support up to 5 slots
  for i = 1, 5 do
    local slotId = "slot" .. i
    local filename = string.format("%s_%s.sav", gameId, slotId)
    local filepath = GbaSave.getSaveDir() .. "/" .. filename
    local fileContent = readFile(filepath)
    local exists = fileContent ~= nil

    local info = nil
    if exists then
      info = GbaSave.inspectSaveFile(filepath)
    end

    local defaultName = (i == 1) and "ASH" or ("Slot " .. i)
    local customName = manifest.customNames[gameId .. "_" .. slotId]
    local displayName = customName or (info and info.name) or defaultName
    local playTime = (info and info.playTime) or "--:--"

    table.insert(slots, {
      id = slotId,
      index = i,
      name = displayName,
      playTime = playTime,
      exists = exists,
      filepath = filepath,
      isActive = (slotId == activeSlotId),
      sizeBytes = exists and #fileContent or 0,
      caught = (info and info.caught) or 0,
      badges = (info and info.badges) or 0,
      kantoBadges = (info and info.kantoBadges) or 0,
      johtoBadges = (info and info.johtoBadges) or 0,
      isChampion = (info and info.isChampion) or false,
      info = info
    })
  end

  return slots, activeSlotId
end

function GbaSave.createSlot(gameId, slotId, name)
  local manifest = GbaSave.loadManifest()
  manifest.customNames[gameId .. "_" .. slotId] = name or ("Slot " .. slotId)
  GbaSave.saveManifest(manifest)

  local filepath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. slotId .. ".sav"
  if not readFile(filepath) then
    local template = readFile(GbaSave.getSaveDir() .. "/" .. gameId .. "_slot1.sav")
      or readFile("FireRed.sav")
      or readFile("roms/FireRedDefinitivo.sav")
      or string.rep("\255", 131072)
    writeFile(filepath, template)
  end
  return true
end

function GbaSave.setActiveSlot(gameId, slotId, romPath)
  local manifest = GbaSave.loadManifest()
  local prevSlotId = manifest.activeSlots[gameId] or "slot1"

  local emulatorSavPath = nil
  local emulatorSrmPath = nil
  if romPath then
    emulatorSavPath = romPath:gsub("%.%w+$", ".sav")
    emulatorSrmPath = romPath:gsub("%.%w+$", ".srm")
  end

  -- Only sync from emulator to previous slot if switching to a DIFFERENT slot
  if prevSlotId ~= slotId and emulatorSavPath and readFile(emulatorSavPath) then
    local currentContent = readFile(emulatorSavPath)
    local prevSlotPath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. prevSlotId .. ".sav"
    writeFile(prevSlotPath, currentContent)
  end

  manifest.activeSlots[gameId] = slotId
  GbaSave.saveManifest(manifest)

  -- Copy active slot to emulator's .sav and .srm
  local newSlotPath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. slotId .. ".sav"
  local newContent = readFile(newSlotPath)
  if newContent and emulatorSavPath then
    writeFile(emulatorSavPath, newContent)
    if emulatorSrmPath then
      writeFile(emulatorSrmPath, newContent)
    end
  end

  return true
end

function GbaSave.renameSlot(gameId, slotId, newName)
  local manifest = GbaSave.loadManifest()
  manifest.customNames[gameId .. "_" .. slotId] = newName
  GbaSave.saveManifest(manifest)
  return true
end

function GbaSave.deleteSlot(gameId, slotId)
  local filepath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. slotId .. ".sav"
  os.remove(filepath)
  local manifest = GbaSave.loadManifest()
  manifest.customNames[gameId .. "_" .. slotId] = nil
  GbaSave.saveManifest(manifest)
  return true
end

return GbaSave
