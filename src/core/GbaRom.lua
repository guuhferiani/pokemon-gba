local GbaRom = {}

GbaRom.KNOWN_GAMES = {
  {
    id = "firered",
    code = "BPRE",
    title = "POKEMON FIRE",
    name = "Pokémon FireRed",
    short = "FR",
    region = "US / Global",
    color = { 230, 70, 40 },
    accent = { 255, 140, 60 },
    bgGrad = { 35, 18, 16 },
    sparkle = false,
    defaultRomName = "FireRed.gba"
  },
  {
    id = "leafgreen",
    code = "BPGE",
    title = "POKEMON LEAF",
    name = "Pokémon LeafGreen",
    short = "LG",
    region = "US / Global",
    color = { 46, 190, 100 },
    accent = { 95, 235, 150 },
    bgGrad = { 16, 32, 22 },
    sparkle = false,
    defaultRomName = "LeafGreen.gba"
  },
  {
    id = "emerald",
    code = "BPEE",
    title = "POKEMON EMER",
    name = "Pokémon Emerald",
    short = "E",
    region = "US / Global",
    color = { 18, 155, 90 },
    accent = { 50, 220, 140 },
    bgGrad = { 14, 30, 24 },
    sparkle = true,
    defaultRomName = "Emerald.gba"
  },
  {
    id = "ruby",
    code = "AXVE",
    title = "POKEMON RUBY",
    name = "Pokémon Ruby",
    short = "R",
    region = "US / Global",
    color = { 195, 30, 65 },
    accent = { 245, 65, 105 },
    bgGrad = { 34, 14, 20 },
    sparkle = false,
    defaultRomName = "Ruby.gba"
  },
  {
    id = "sapphire",
    code = "AXPE",
    title = "POKEMON SAPP",
    name = "Pokémon Sapphire",
    short = "S",
    region = "US / Global",
    color = { 30, 85, 215 },
    accent = { 75, 135, 255 },
    bgGrad = { 14, 20, 36 },
    sparkle = false,
    defaultRomName = "Sapphire.gba"
  }
}

function GbaRom.getGameById(id)
  for _, g in ipairs(GbaRom.KNOWN_GAMES) do
    if g.id == id then return g end
  end
  return GbaRom.KNOWN_GAMES[1]
end

function GbaRom.getGameByCode(code)
  for _, g in ipairs(GbaRom.KNOWN_GAMES) do
    if g.code == code then return g end
  end
  return nil
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

  -- Clean title (strip trailing nulls)
  local title = titleRaw:gsub("%z+$", ""):gsub("^%s+", ""):gsub("%s+$", "")

  local known = GbaRom.getGameByCode(gameCode)
  local sizeMb = string.format("%.1f MB", size / (1024 * 1024))

  return {
    filepath = filepath,
    filename = filepath:match("([^/\\]+)$") or filepath,
    title = title,
    gameCode = gameCode,
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
  
  -- Resolve absolute base path if running under LOVE
  local sourceDir = ""
  if love and love.filesystem and love.filesystem.getSource then
    sourceDir = love.filesystem.getSource():gsub("\\", "/")
  end

  -- Search explicitly in /gba first, then local and relative paths
  local searchCandidates = {
    { prefix = "gba/", folder = "/gba" },
    { prefix = sourceDir .. "/", folder = "/gba" },
    { prefix = sourceDir .. "/gba/", folder = "/gba" },
    { prefix = "", folder = "/gba" },
    { prefix = "../gba/", folder = "/gba" },
    { prefix = "roms/", folder = "roms/" }
  }

  -- 1. Try default filename per game first in /gba
  for _, g in ipairs(GbaRom.KNOWN_GAMES) do
    local found = nil
    for _, candidate in ipairs(searchCandidates) do
      local path = candidate.prefix .. g.defaultRomName
      local f = io.open(path, "rb")
      if f then
        f:close()
        local info = GbaRom.parseHeader(path)
        if info then
          info.folder = "/gba"
          info.displayPath = "gba/" .. g.defaultRomName
          found = info
          break
        end
      end
    end
    results[g.id] = found
  end

  -- 2. Scan directory items for any .gba file in /gba
  if love and love.filesystem and love.filesystem.getDirectoryItems then
    local items = love.filesystem.getDirectoryItems("")
    for _, item in ipairs(items) do
      if item:lower():match("%.gba$") then
        local fullItemPath = (sourceDir ~= "" and (sourceDir .. "/" .. item)) or item
        local info = GbaRom.parseHeader(fullItemPath) or GbaRom.parseHeader(item)
        if info and info.known and not results[info.known.id] then
          info.folder = "/gba"
          info.displayPath = "gba/" .. item
          results[info.known.id] = info
        end
      end
    end
  end

  return results
end

return GbaRom
