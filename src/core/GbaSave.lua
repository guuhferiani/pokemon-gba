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

  -- Search Section 0 in Slot A (0x0000 - 0x0FFF) and Slot B (0xE000 - 0xEFFF)
  -- The last 12 bytes of each 4KB chunk contain Section ID (uint16 at +0x0FF4)
  local bestSlot = nil
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

    if secId == 0 and sig == 0x08012025 then
      if saveIndex > highestSaveIndex then
        highestSaveIndex = saveIndex
        bestSlot = offset
      end
    end
  end

  -- Scan 14 sections of Slot A
  for i = 0, 13 do checkChunk(i * 4096) end
  -- Scan 14 sections of Slot B
  for i = 0, 13 do checkChunk(0xE000 + i * 4096) end

  if not bestSlot then
    f:close()
    return { name = "Treinador", playTime = "00:00", badges = 0, valid = false }
  end

  -- Read Section 0
  f:seek("set", bestSlot)
  local sec0 = f:read(32)
  f:close()

  if not sec0 or #sec0 < 20 then
    return { name = "Treinador", playTime = "00:00", badges = 0, valid = false }
  end

  local nameBytes = sec0:sub(1, 7)
  local trainerName = decodeGen3String(nameBytes)
  if not trainerName or #trainerName == 0 then trainerName = "ASH" end

  local hours = string.byte(sec0, 0x0F) + string.byte(sec0, 0x10) * 256
  local minutes = string.byte(sec0, 0x11)
  local playTime = string.format("%02d:%02d", hours, minutes)

  return {
    name = trainerName,
    playTime = playTime,
    saveIndex = highestSaveIndex,
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

function GbaSave.listSlots(gameId)
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
      sizeBytes = exists and #fileContent or 0
    })
  end

  return slots, activeSlotId
end

function GbaSave.createSlot(gameId, slotId, name)
  local manifest = GbaSave.loadManifest()
  manifest.customNames[gameId .. "_" .. slotId] = name or ("Slot " .. slotId)
  GbaSave.saveManifest(manifest)

  local filepath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. slotId .. ".sav"
  -- Create blank 128KB save if not present
  if not readFile(filepath) then
    local blank = string.rep("\255", 131072)
    writeFile(filepath, blank)
  end
  return true
end

function GbaSave.setActiveSlot(gameId, slotId, romPath)
  local manifest = GbaSave.loadManifest()
  local prevSlotId = manifest.activeSlots[gameId] or "slot1"

  -- If ROM path is provided, sync previous active slot from emulator's .sav
  local emulatorSavPath = nil
  if romPath then
    emulatorSavPath = romPath:gsub("%.%w+$", ".sav")
  end

  if emulatorSavPath and readFile(emulatorSavPath) then
    local currentContent = readFile(emulatorSavPath)
    local prevSlotPath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. prevSlotId .. ".sav"
    writeFile(prevSlotPath, currentContent)
  end

  -- Now load the new slot into emulator's .sav
  manifest.activeSlots[gameId] = slotId
  GbaSave.saveManifest(manifest)

  local newSlotPath = GbaSave.getSaveDir() .. "/" .. gameId .. "_" .. slotId .. ".sav"
  local newContent = readFile(newSlotPath)
  if newContent and emulatorSavPath then
    writeFile(emulatorSavPath, newContent)
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
