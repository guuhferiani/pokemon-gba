local GbaRom = {}

-- Definitive Single-Game Profile: Pokémon Kanto & Johto (32MB)
GbaRom.KNOWN_GAMES = {
  {
    id = "kantojohto",
    code = "BPKJ",
    title = "POKEMON KJ",
    name = "Pokémon Kanto & Johto",
    short = "K&J",
    region = "Definitive 32MB",
    color = { 215, 155, 30 },
    accent = { 255, 215, 80 },
    bgGrad = { 40, 26, 10 },
    sparkle = true,
    defaultRomName = "Pokemon_Kanto_Johto.gba"
  }
}

function GbaRom.getGameById(id)
  return GbaRom.KNOWN_GAMES[1]
end

function GbaRom.getGameByCode(code)
  return GbaRom.KNOWN_GAMES[1]
end

function GbaRom.parseHeader(filepath)
  local f = io.open(filepath, "rb")
  if not f then return nil, "Could not open file" end

  local size = f:seek("end")
  if size < 0xC0 then
    f:close()
    return nil, "File too small for GBA header"
  end

  f:seek("set", 0xA0)
  local titleRaw = f:read(12) or ""
  local gameCode = f:read(4) or ""
  local maker = f:read(2) or ""
  f:seek("set", 0xBC)
  local versionByte = f:read(1)
  local version = versionByte and string.byte(versionByte) or 0
  f:close()

  local title = titleRaw:gsub("%z+$", ""):gsub("^%s+", ""):gsub("%s+$", "")
  local known = GbaRom.KNOWN_GAMES[1]
  local sizeMb = string.format("%.1f MB", size / (1024 * 1024))

  return {
    filepath = filepath,
    filename = filepath:match("([^/\\]+)$") or filepath,
    title = title ~= "" and title or "POKEMON KJ",
    gameCode = gameCode ~= "" and gameCode or "BPKJ",
    maker = maker,
    version = version,
    fileSizeBytes = size,
    fileSizeMb = sizeMb,
    known = known,
    ready = true
  }
end

function GbaRom.scanDirectory(dir)
  local results = {}
  local primaryGame = GbaRom.KNOWN_GAMES[1]

  -- Prioritized search candidates for Kanto & Johto ROM
  local candidates = {
    "roms/Pokemon Kanto Johto.gba",
    "Pokemon Kanto Johto.gba",
    "roms/Pokemon_Kanto_Johto.gba",
    "Pokemon_Kanto_Johto.gba",
    "roms/FireRedDefinitivo.gba",
    "roms/FireRed.gba"
  }

  for _, path in ipairs(candidates) do
    local f = io.open(path, "rb")
    if f then
      f:close()
      local info = GbaRom.parseHeader(path)
      if info then
        info.folder = path:match("^roms/") and "roms/" or "/"
        info.displayPath = path
        info.customTitle = "Pokémon Kanto & Johto (32MB Definitive)"
        results[primaryGame.id] = info
        break
      end
    end
  end

  return results
end

return GbaRom
