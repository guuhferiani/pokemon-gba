local GbaMods = {}

local CONFIG_FILE = "mods/mods_config.json"
local DEFAULT_MODS = {
  {
    id = "ptbr_firered",
    name = "Tradução Português-BR (FireRed)",
    author = "Comunidade GBA / PokéPT",
    version = "1.2.0",
    type = "patch",
    category = "Tradução",
    description = "Traduz 100% dos textos, diálogos, itens e nomes de golpes para Português do Brasil.",
    games = { "firered" },
    enabled = true
  },
  {
    id = "exp_share_modern",
    name = "Exp. Share Moderno (Gen 6+)",
    author = "GbaQoL",
    version = "1.0.4",
    type = "script",
    category = "Mecânica QoL",
    description = "Distribui pontos de experiência para todos os Pokémon da equipe automaticamente.",
    games = { "firered", "leafgreen", "emerald", "ruby", "sapphire" },
    enabled = true
  },
  {
    id = "run_indoors",
    name = "Correr em Ambientes Fechados",
    author = "QoL Team",
    version = "1.1.0",
    type = "script",
    category = "Conveniência",
    description = "Permite segurar o botão B para correr dentro de casas, centros pokémon e cavernas.",
    games = { "firered", "leafgreen", "emerald" },
    enabled = true
  },
  {
    id = "fast_text_instant",
    name = "Texto Instantâneo",
    author = "SpeedMod",
    version = "2.0.0",
    type = "script",
    category = "Velocidade",
    description = "Exibe caixas de diálogo e mensagens de batalha instantaneamente sem delay.",
    games = { "firered", "leafgreen", "emerald", "ruby", "sapphire" },
    enabled = false
  },
  {
    id = "reusable_tms",
    name = "TMs Infinitos (Reutilizáveis)",
    author = "ModernGen",
    version = "1.0.0",
    type = "script",
    category = "Mecânica QoL",
    description = "TMs não quebram após o uso, funcionando como nas gerações modernas da franquia.",
    games = { "firered", "leafgreen", "emerald" },
    enabled = false
  }
}

local function getBaseDir()
  return "mods"
end

local function getConfigPath()
  return "mods/mods_config.json"
end

local function ensureDir(path)
  local winPath = path:gsub('/', '\\')
  os.execute('if not exist "' .. winPath .. '" mkdir "' .. winPath .. '" 2>nul')
  if love and love.filesystem then
    pcall(love.filesystem.createDirectory, path)
  end
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local c = f:read("*a")
  f:close()
  return c
end

local function writeFile(path, content)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

function GbaMods.init()
  ensureDir("mods")
  for _, m in ipairs(DEFAULT_MODS) do
    local modDir = "mods/" .. m.id
    ensureDir(modDir)
    local manifestPath = modDir .. "/manifest.json"
    if not readFile(manifestPath) then
      local json = string.format([[
{
  "id": "%s",
  "name": "%s",
  "author": "%s",
  "version": "%s",
  "type": "%s",
  "category": "%s",
  "description": "%s"
}
]], m.id, m.name, m.author, m.version, m.type, m.category, m.description)
      writeFile(manifestPath, json)
    end
  end
  GbaMods.loadConfig()
end

function GbaMods.loadConfig()
  local content = readFile(getConfigPath())
  GbaMods.enabledMap = {}
  if content then
    for id, state in content:gmatch('"([%w_]+)"%s*:%s*(%a+)') do
      GbaMods.enabledMap[id] = (state == "true")
    end
  else
    for _, m in ipairs(DEFAULT_MODS) do
      GbaMods.enabledMap[m.id] = m.enabled
    end
    GbaMods.saveConfig()
  end
end

function GbaMods.saveConfig()
  ensureDir(getBaseDir())
  local lines = { "{" }
  for k, v in pairs(GbaMods.enabledMap or {}) do
    table.insert(lines, string.format('  "%s": %s,', k, tostring(v)))
  end
  table.insert(lines, '  "version": 1')
  table.insert(lines, "}")
  writeFile(getConfigPath(), table.concat(lines, "\n"))
end

function GbaMods.list(filterGameId)
  if not GbaMods.enabledMap then GbaMods.loadConfig() end
  local mods = {}

  for _, m in ipairs(DEFAULT_MODS) do
    local match = true
    if filterGameId and m.games then
      match = false
      for _, g in ipairs(m.games) do
        if g == filterGameId then match = true break end
      end
    end

    if match then
      local isAct = GbaMods.enabledMap[m.id]
      if isAct == nil then isAct = m.enabled end
      table.insert(mods, {
        id = m.id,
        name = m.name,
        author = m.author,
        version = m.version,
        type = m.type,
        category = m.category,
        description = m.description,
        games = m.games,
        enabled = isAct
      })
    end
  end

  return mods
end

function GbaMods.toggle(modId)
  if not GbaMods.enabledMap then GbaMods.loadConfig() end
  GbaMods.enabledMap[modId] = not GbaMods.enabledMap[modId]
  GbaMods.saveConfig()
  return GbaMods.enabledMap[modId]
end

function GbaMods.isEnabled(modId)
  if not GbaMods.enabledMap then GbaMods.loadConfig() end
  return GbaMods.enabledMap[modId] == true
end

function GbaMods.syncCheatsFile(romPath)
  if not romPath then return end
  local chtPath = romPath:gsub("%.%w+$", ".cht")
  local cheats = {
    "; Generated automatically by Pokemon GBA Studio++",
    "",
    "[Master Code (Obrigatorio)]",
    "000014D1 000A",
    "1003DAE6 0007",
    ""
  }

  if GbaMods.isEnabled("run_indoors") then
    table.insert(cheats, "[Correr em Qualquer Lugar (Indoors)]")
    table.insert(cheats, "72025982 0200")
    table.insert(cheats, "82025982 0000")
    table.insert(cheats, "")
  end

  if GbaMods.isEnabled("fast_text_instant") then
    table.insert(cheats, "[Texto Instantaneo]")
    table.insert(cheats, "32003885 0000")
    table.insert(cheats, "")
  end

  if GbaMods.isEnabled("reusable_tms") then
    table.insert(cheats, "[TMs Reutilizaveis]")
    table.insert(cheats, "82025840 0121")
    table.insert(cheats, "")
  end

  local f = io.open(chtPath, "w")
  if f then
    f:write(table.concat(cheats, "\n"))
    f:close()
  end
end

return GbaMods
