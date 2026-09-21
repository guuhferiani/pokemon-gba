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

  -- Search explicitly in /roms, /gba, local and relative paths
  local searchCandidates = {
    { prefix = "roms/FireRed_251+final.gba", folder = "roms/", id = "firered" },
    { prefix = "roms/FireRedDefinitivo.gba", folder = "roms/", id = "firered" },
    { prefix = "roms/Fire Red(BR-USA).gba", folder = "roms/", id = "firered" },
    { prefix = "roms/", folder = "roms/" },
    { prefix = sourceDir .. "/roms/", folder = "roms/" },
    { prefix = "gba/", folder = "/gba" },
    { prefix = sourceDir .. "/gba/", folder = "/gba" },
    { prefix = sourceDir .. "/", folder = "/" },
    { prefix = "", folder = "/" }
  }

  -- 1. Check verified 100% PT-BR FireRed ROMs first
  local ptbrCandidates = {
    "roms/FireRedDefinitivo.gba",
    "roms/Fire Red(BR-USA).gba",
    "roms/Mega Pack Hack Roms Pokémon/44. Pokemon Fire Red Definitivo 2.0.gba",
    "FireRed.gba"
  }

  for _, ptPath in ipairs(ptbrCandidates) do
    local f = io.open(ptPath, "rb")
    if f then
      f:close()
      local info = GbaRom.parseHeader(ptPath)
      if info then
        info.folder = "roms/"
        info.displayPath = ptPath
        info.customTitle = "Pokémon FireRed (100% PT-BR)"
        results["firered"] = info
        break
      end
    end
  end

  -- 2. Try default filename per game
  for _, g in ipairs(GbaRom.KNOWN_GAMES) do
    if not results[g.id] then
      for _, candidate in ipairs(searchCandidates) do
        if candidate.prefix and not candidate.id then
          local path = candidate.prefix .. g.defaultRomName
          local fRom = io.open(path, "rb")
          if fRom then
            fRom:close()
            local info = GbaRom.parseHeader(path)
            if info then
              info.folder = candidate.folder
              info.displayPath = candidate.prefix .. g.defaultRomName
              results[g.id] = info
              break
            end
          end
        end
      end
    end
  end

  -- 3. Scan directory items for any .gba file in root and roms
  if love and love.filesystem and love.filesystem.getDirectoryItems then
    local scanFolders = { "", "roms", "gba" }
    for _, sFolder in ipairs(scanFolders) do
      local pfx = sFolder ~= "" and (sFolder .. "/") or ""
      local ok, items = pcall(love.filesystem.getDirectoryItems, sFolder)
      if ok and items then
        for _, item in ipairs(items) do
          if item:lower():match("%.gba$") then
            local relativePath = pfx .. item
            local fullItemPath = (sourceDir ~= "" and (sourceDir .. "/" .. relativePath)) or relativePath
            local info = GbaRom.parseHeader(fullItemPath) or GbaRom.parseHeader(relativePath)
            if info and info.known and not results[info.known.id] then
              info.folder = sFolder ~= "" and (sFolder .. "/") or "/"
              info.displayPath = relativePath
              results[info.known.id] = info
            end
          end
        end
      end
    end
  end

  return results
end

return GbaRom
