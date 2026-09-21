local GbaShinyDex = {}

-- 251 Gen 1 & Gen 2 Pokémon Names in Portuguese / English standard
GbaShinyDex.SPECIES = {
  [1] = "Bulbasaur", [2] = "Ivysaur", [3] = "Venusaur",
  [4] = "Charmander", [5] = "Charmeleon", [6] = "Charizard",
  [7] = "Squirtle", [8] = "Wartortle", [9] = "Blastoise",
  [10] = "Caterpie", [11] = "Metapod", [12] = "Butterfree",
  [13] = "Weedle", [14] = "Kakuna", [15] = "Beedrill",
  [16] = "Pidgey", [17] = "Pidgeotto", [18] = "Pidgeot",
  [19] = "Rattata", [20] = "Raticate", [21] = "Spearow", [22] = "Fearow",
  [23] = "Ekans", [24] = "Arbok", [25] = "Pikachu", [26] = "Raichu",
  [27] = "Sandshrew", [28] = "Sandslash", [29] = "Nidoran♀", [30] = "Nidorina",
  [31] = "Nidoqueen", [32] = "Nidoran♂", [33] = "Nidorino", [34] = "Nidoking",
  [35] = "Clefairy", [36] = "Clefable", [37] = "Vulpix", [38] = "Ninetales",
  [39] = "Jigglypuff", [40] = "Wigglytuff", [41] = "Zubat", [42] = "Golbat",
  [43] = "Oddish", [44] = "Gloom", [45] = "Vileplume", [46] = "Paras",
  [47] = "Parasect", [48] = "Venonat", [49] = "Venomoth", [50] = "Diglett",
  [51] = "Dugtrio", [52] = "Meowth", [53] = "Persian", [54] = "Psyduck",
  [55] = "Golduck", [56] = "Mankey", [57] = "Primeape", [58] = "Growlithe",
  [59] = "Arcanine", [60] = "Poliwag", [61] = "Poliwhirl", [62] = "Poliwrath",
  [63] = "Abra", [64] = "Kadabra", [65] = "Alakazam", [66] = "Machop",
  [67] = "Machoke", [68] = "Machamp", [69] = "Bellsprout", [70] = "Weepinbell",
  [71] = "Victreebel", [72] = "Tentacool", [73] = "Tentacruel", [74] = "Geodude",
  [75] = "Graveler", [76] = "Golem", [77] = "Ponyta", [78] = "Rapidash",
  [79] = "Slowpoke", [80] = "Slowbro", [81] = "Magnemite", [82] = "Magneton",
  [83] = "Farfetch'd", [84] = "Doduo", [85] = "Dodrio", [86] = "Seel",
  [87] = "Dewgong", [88] = "Grimer", [89] = "Muk", [90] = "Shellder",
  [91] = "Cloyster", [92] = "Gastly", [93] = "Haunter", [94] = "Gengar",
  [95] = "Onix", [96] = "Drowzee", [97] = "Hypno", [98] = "Krabby",
  [99] = "Kingler", [100] = "Voltorb", [101] = "Electrode", [102] = "Exeggcute",
  [103] = "Exeggutor", [104] = "Cubone", [105] = "Marowak", [106] = "Hitmonlee",
  [107] = "Hitmonchan", [108] = "Lickitung", [109] = "Koffing", [110] = "Weezing",
  [111] = "Rhyhorn", [112] = "Rhydon", [113] = "Chansey", [114] = "Tangela",
  [115] = "Kangaskhan", [116] = "Horsea", [117] = "Seadra", [118] = "Goldeen",
  [119] = "Seaking", [120] = "Staryu", [121] = "Starmie", [122] = "Mr. Mime",
  [123] = "Scyther", [124] = "Jynx", [125] = "Electabuzz", [126] = "Magmar",
  [127] = "Pinsir", [128] = "Tauros", [129] = "Magikarp", [130] = "Gyarados",
  [131] = "Lapras", [132] = "Ditto", [133] = "Eevee", [134] = "Vaporeon",
  [135] = "Jolteon", [136] = "Flareon", [137] = "Porygon", [138] = "Omanyte",
  [139] = "Omastar", [140] = "Kabuto", [141] = "Kabutops", [142] = "Aerodactyl",
  [143] = "Snorlax", [144] = "Articuno", [145] = "Zapdos", [146] = "Moltres",
  [147] = "Dratini", [148] = "Dragonair", [149] = "Dragonite", [150] = "Mewtwo",
  [151] = "Mew",
  -- Gen 2 (Johto 152 - 251)
  [152] = "Chikorita", [153] = "Bayleef", [154] = "Meganium",
  [155] = "Cyndaquil", [156] = "Quilava", [157] = "Typhlosion",
  [158] = "Totodile", [159] = "Croconaw", [160] = "Feraligatr",
  [161] = "Sentret", [162] = "Furret", [163] = "Hoothoot", [164] = "Noctowl",
  [165] = "Ledyba", [166] = "Ledian", [167] = "Spinarak", [168] = "Ariados",
  [169] = "Crobat", [170] = "Chinchou", [171] = "Lanturn", [172] = "Pichu",
  [173] = "Cleffa", [174] = "Igglybuff", [175] = "Togepi", [176] = "Togetic",
  [177] = "Natu", [178] = "Xatu", [179] = "Mareep", [180] = "Flaaffy",
  [181] = "Ampharos", [182] = "Bellossom", [183] = "Marill", [184] = "Azumarill",
  [185] = "Sudowoodo", [186] = "Politoed", [187] = "Hoppip", [188] = "Skiploom",
  [189] = "Jumpluff", [190] = "Aipom", [191] = "Sunkern", [192] = "Sunflora",
  [193] = "Yanma", [194] = "Wooper", [195] = "Quagsire", [196] = "Espeon",
  [197] = "Umbreon", [198] = "Murkrow", [199] = "Slowking", [200] = "Misdreavus",
  [201] = "Unown", [202] = "Wobbuffet", [203] = "Girafarig", [204] = "Pineco",
  [205] = "Forretress", [206] = "Dunsparce", [207] = "Gligar", [208] = "Steelix",
  [209] = "Snubbull", [210] = "Granbull", [211] = "Qwilfish", [212] = "Scizor",
  [213] = "Shuckle", [214] = "Heracross", [215] = "Sneasel", [216] = "Teddiursa",
  [217] = "Ursaring", [218] = "Slugma", [219] = "Magcargo", [220] = "Swinub",
  [221] = "Piloswine", [222] = "Corsola", [223] = "Remoraid", [224] = "Octillery",
  [225] = "Delibird", [226] = "Mantine", [227] = "Skarmory", [228] = "Houndour",
  [229] = "Houndoom", [230] = "Kingdra", [231] = "Phanpy", [232] = "Donphan",
  [233] = "Porygon2", [234] = "Stantler", [235] = "Smeargle", [236] = "Tyrogue",
  [237] = "Hitmontop", [238] = "Smoochum", [239] = "Elekid", [240] = "Magby",
  [241] = "Miltank", [242] = "Blissey", [243] = "Raikou", [244] = "Entei",
  [245] = "Suicune", [246] = "Larvitar", [247] = "Pupitar", [248] = "Tyranitar",
  [249] = "Lugia", [250] = "Ho-Oh", [251] = "Celebi"
}

GbaShinyDex.NATURES = {
  [0] = "Hardy", [1] = "Lonely", [2] = "Brave", [3] = "Adamant", [4] = "Naughty",
  [5] = "Bold", [6] = "Docile", [7] = "Relaxed", [8] = "Impish", [9] = "Lax",
  [10] = "Timid", [11] = "Hasty", [12] = "Serious", [13] = "Jolly", [14] = "Naive",
  [15] = "Modest", [16] = "Mild", [17] = "Quiet", [18] = "Bashful", [19] = "Rash",
  [20] = "Calm", [21] = "Gentle", [22] = "Sassy", [23] = "Careful", [24] = "Quirky"
}

-- 24 Permutations of Substructures in Gen 3
local SUBSTRUCT_ORDERS = {
  [0]  = { 1, 2, 3, 4 }, [1]  = { 1, 2, 4, 3 }, [2]  = { 1, 3, 2, 4 }, [3]  = { 1, 3, 4, 2 },
  [4]  = { 1, 4, 2, 3 }, [5]  = { 1, 4, 3, 2 }, [6]  = { 2, 1, 3, 4 }, [7]  = { 2, 1, 4, 3 },
  [8]  = { 2, 3, 1, 4 }, [9]  = { 2, 3, 4, 1 }, [10] = { 2, 4, 1, 3 }, [11] = { 2, 4, 3, 1 },
  [12] = { 3, 1, 2, 4 }, [13] = { 3, 1, 4, 2 }, [14] = { 3, 2, 1, 4 }, [15] = { 3, 2, 4, 1 },
  [16] = { 3, 4, 1, 2 }, [17] = { 3, 4, 2, 1 }, [18] = { 4, 1, 2, 3 }, [19] = { 4, 1, 3, 2 },
  [20] = { 4, 2, 1, 3 }, [21] = { 4, 2, 3, 1 }, [22] = { 4, 3, 1, 2 }, [23] = { 4, 3, 2, 1 }
}

local function bxor(a, b)
  if bit and bit.bxor then return bit.bxor(a, b) end
  local p, c = 1, 0
  while a > 0 or b > 0 do
    local ra = a % 2
    local rb = b % 2
    if ra ~= rb then c = c + p end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    p = p * 2
  end
  return c
end

local function readUint16(data, offset)
  local b1 = string.byte(data, offset) or 0
  local b2 = string.byte(data, offset + 1) or 0
  return b1 + b2 * 256
end

local function readUint32(data, offset)
  local b1 = string.byte(data, offset) or 0
  local b2 = string.byte(data, offset + 1) or 0
  local b3 = string.byte(data, offset + 2) or 0
  local b4 = string.byte(data, offset + 3) or 0
  return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function decodeGen3Name(bytes)
  local GEN3_CHARS = {}
  for i = 0, 255 do GEN3_CHARS[i] = "" end
  local upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  for i = 1, #upper do GEN3_CHARS[0xBB + i - 1] = upper:sub(i, i) end
  local lower = "abcdefghijklmnopqrstuvwxyz"
  for i = 1, #lower do GEN3_CHARS[0xD5 + i - 1] = lower:sub(i, i) end
  local digits = "0123456789"
  for i = 1, #digits do GEN3_CHARS[0xA1 + i - 1] = digits:sub(i, i) end

  local str = ""
  for i = 1, #bytes do
    local b = string.byte(bytes, i)
    if b == 0xFF then break end
    str = str .. (GEN3_CHARS[b] or "")
  end
  return str:match("^%s*(.-)%s*$")
end

-- Parse a single 80-byte or 100-byte Pokemon block
function GbaShinyDex.parsePokemon(data, locationName)
  if not data or #data < 80 then return nil end

  local pid = readUint32(data, 1)
  local otid = readUint32(data, 5)

  if pid == 0 and otid == 0 then return nil end

  local tid = otid % 65536
  local sid = math.floor(otid / 65536) % 65536
  local pidLow = pid % 65536
  local pidHigh = math.floor(pid / 65536) % 65536

  -- Shiny calculation
  local shinyXor = bxor(bxor(tid, sid), bxor(pidLow, pidHigh))
  local isShiny = (shinyXor < 8)

  local rawNick = data:sub(9, 18)
  local nickname = decodeGen3Name(rawNick)

  -- Decrypt 48 bytes of substructures
  local key = bxor(pid, otid)
  local encData = data:sub(33, 80)
  if #encData < 48 then return nil end

  local decWords = {}
  for w = 0, 11 do
    local encWord = readUint32(encData, w * 4 + 1)
    decWords[w + 1] = bxor(encWord, key)
  end

  -- Determine order of Growth, Attacks, EVs, Misc
  local orderIndex = pid % 24
  local order = SUBSTRUCT_ORDERS[orderIndex] or { 1, 2, 3, 4 }

  -- Substructure 1 is Growth (starts with Species ID uint16)
  local growthBlockIdx = 1
  for i, blockType in ipairs(order) do
    if blockType == 1 then
      growthBlockIdx = i
      break
    end
  end

  local growthWord1 = decWords[(growthBlockIdx - 1) * 3 + 1] or 0
  local speciesId = growthWord1 % 65536

  if speciesId == 0 or speciesId > 412 then
    return nil
  end

  local speciesName = GbaShinyDex.SPECIES[speciesId] or ("Pokémon #" .. speciesId)
  local natureId = pid % 25
  local natureName = GbaShinyDex.NATURES[natureId] or "Hardy"

  local level = 1
  if #data >= 85 then
    level = string.byte(data, 85) or 1
  end

  return {
    pid = pid,
    otid = otid,
    speciesId = speciesId,
    speciesName = speciesName,
    nickname = (nickname ~= "" and nickname ~= speciesName) and nickname or speciesName,
    nature = natureName,
    level = level,
    isShiny = isShiny,
    location = locationName or "Box do PC"
  }
end

-- Scan save file for all Pokemon (Party & Boxes)
function GbaShinyDex.scanSave(filepath)
  local f = io.open(filepath, "rb")
  if not f then return { shinies = {}, totalPokemon = 0, totalShinies = 0 } end
  local content = f:read("*a")
  f:close()

  if #content < 0x10000 then
    return { shinies = {}, totalPokemon = 0, totalShinies = 0 }
  end

  local function scanSlot(baseOffset)
    local secMap = {}
    local maxIdx = -1
    for sec = 0, 13 do
      local offset = baseOffset + sec * 4096
      local footerOffset = offset + 0x0FF4 + 1
      if footerOffset + 11 <= #content then
        local secId = string.byte(content, footerOffset) + string.byte(content, footerOffset + 1) * 256
        local sig = string.byte(content, footerOffset + 4) + string.byte(content, footerOffset + 5) * 256
          + string.byte(content, footerOffset + 6) * 65536 + string.byte(content, footerOffset + 7) * 16777216
        local sIndex = string.byte(content, footerOffset + 8) + string.byte(content, footerOffset + 9) * 256
          + string.byte(content, footerOffset + 10) * 65536 + string.byte(content, footerOffset + 11) * 16777216

        if sig == 0x08012025 then
          secMap[secId] = offset
          if sIndex > maxIdx then maxIdx = sIndex end
        end
      end
    end
    return secMap, maxIdx
  end

  local mapA, idxA = scanSlot(0)
  local mapB, idxB = scanSlot(0xE000)
  local secMap = (idxB > idxA) and mapB or mapA

  local shinies = {}
  local totalMon = 0

  -- 1. Scan Party in Section 1 (Offset +0x0034 = count, +0x0038 = 6x 100-byte PartyMon)
  if secMap[1] then
    local partyCount = string.byte(content, secMap[1] + 0x0034 + 1) or 0
    if partyCount > 6 then partyCount = 6 end
    for p = 0, partyCount - 1 do
      local monOffset = secMap[1] + 0x0038 + p * 100 + 1
      local monData = content:sub(monOffset, monOffset + 99)
      local mon = GbaShinyDex.parsePokemon(monData, "Equipe Ativa (Slot " .. (p + 1) .. ")")
      if mon then
        totalMon = totalMon + 1
        if mon.isShiny then
          table.insert(shinies, mon)
        end
      end
    end
  end

  -- 2. Scan PC Boxes in Sections 5 to 13
  -- Box storage spans 14 boxes x 30 Pokemon = 420 Pokemon (80 bytes each)
  local boxBuffer = ""
  for sec = 5, 13 do
    if secMap[sec] then
      -- Section data is 3968 bytes
      local dataPart = content:sub(secMap[sec] + 1, secMap[sec] + 3968)
      boxBuffer = boxBuffer .. dataPart
    end
  end

  if #boxBuffer >= (14 * 30 * 80) then
    for b = 0, 13 do
      for slot = 0, 29 do
        local idx = (b * 30 + slot) * 80 + 1
        local monData = boxBuffer:sub(idx, idx + 79)
        local mon = GbaShinyDex.parsePokemon(monData, "PC Box " .. (b + 1))
        if mon then
          totalMon = totalMon + 1
          if mon.isShiny then
            table.insert(shinies, mon)
          end
        end
      end
    end
  end

  return {
    shinies = shinies,
    totalPokemon = totalMon,
    totalShinies = #shinies
  }
end

-- Shiny Rate Configurations for Launcher Patcher
GbaShinyDex.RATES = {
  { id = "default", label = "1 / 8.192 (Padrão Original)", val = 8, desc = "Chance original e autêntica de 0.012% por encontro." },
  { id = "charm", label = "1 / 512 (Shiny Charm)", val = 128, desc = "Taxa moderna dos jogos atuais da franquia (Gen 6+)." },
  { id = "frequent", label = "1 / 128 (Frequente)", val = 512, desc = "Encontre 1 a cada ~128 batalhas na jornada." },
  { id = "boosted", label = "1 / 32 (Alta Frequência)", val = 2048, desc = "Excelente para colecionadores rápidos." },
  { id = "always", label = "100% (Shiny Hunter Total)", val = 65535, desc = "TODOS os encontros selvagens são Shiny garantidos!" }
}

return GbaShinyDex
