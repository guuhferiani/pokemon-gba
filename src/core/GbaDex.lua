local GbaDex = {}

-- ============================================================
-- GbaDex.lua — Pokédex Reader (FireRed Gen 3 Save Format)
-- Lê os bitmaps de Seen/Caught do save e organiza por região.
-- Compatível com FireRed BPRE vanilla e ROM hacks 32MB.
-- ============================================================

-- 251 Pokémon (Kanto + Johto) — números National Dex
-- Regiões: Kanto = 1-151, Johto = 152-251, National = 1-386
GbaDex.REGIONS = {
  { id = "kanto",    label = "Kanto Pokédex",    from = 1,   to = 151 },
  { id = "johto",    label = "Johto Pokédex",    from = 152, to = 251 },
  { id = "national", label = "National Pokédex", from = 1,   to = 386 },
}

-- Nomes dos 386 Pokémon (National Dex order)
GbaDex.SPECIES = {
  -- Gen 1 / Kanto (1-151)
  [1]="Bulbasaur",[2]="Ivysaur",[3]="Venusaur",
  [4]="Charmander",[5]="Charmeleon",[6]="Charizard",
  [7]="Squirtle",[8]="Wartortle",[9]="Blastoise",
  [10]="Caterpie",[11]="Metapod",[12]="Butterfree",
  [13]="Weedle",[14]="Kakuna",[15]="Beedrill",
  [16]="Pidgey",[17]="Pidgeotto",[18]="Pidgeot",
  [19]="Rattata",[20]="Raticate",[21]="Spearow",[22]="Fearow",
  [23]="Ekans",[24]="Arbok",[25]="Pikachu",[26]="Raichu",
  [27]="Sandshrew",[28]="Sandslash",[29]="Nidoran♀",[30]="Nidorina",
  [31]="Nidoqueen",[32]="Nidoran♂",[33]="Nidorino",[34]="Nidoking",
  [35]="Clefairy",[36]="Clefable",[37]="Vulpix",[38]="Ninetales",
  [39]="Jigglypuff",[40]="Wigglytuff",[41]="Zubat",[42]="Golbat",
  [43]="Oddish",[44]="Gloom",[45]="Vileplume",[46]="Paras",
  [47]="Parasect",[48]="Venonat",[49]="Venomoth",[50]="Diglett",
  [51]="Dugtrio",[52]="Meowth",[53]="Persian",[54]="Psyduck",
  [55]="Golduck",[56]="Mankey",[57]="Primeape",[58]="Growlithe",
  [59]="Arcanine",[60]="Poliwag",[61]="Poliwhirl",[62]="Poliwrath",
  [63]="Abra",[64]="Kadabra",[65]="Alakazam",[66]="Machop",
  [67]="Machoke",[68]="Machamp",[69]="Bellsprout",[70]="Weepinbell",
  [71]="Victreebel",[72]="Tentacool",[73]="Tentacruel",[74]="Geodude",
  [75]="Graveler",[76]="Golem",[77]="Ponyta",[78]="Rapidash",
  [79]="Slowpoke",[80]="Slowbro",[81]="Magnemite",[82]="Magneton",
  [83]="Farfetch'd",[84]="Doduo",[85]="Dodrio",[86]="Seel",
  [87]="Dewgong",[88]="Grimer",[89]="Muk",[90]="Shellder",
  [91]="Cloyster",[92]="Gastly",[93]="Haunter",[94]="Gengar",
  [95]="Onix",[96]="Drowzee",[97]="Hypno",[98]="Krabby",
  [99]="Kingler",[100]="Voltorb",[101]="Electrode",[102]="Exeggcute",
  [103]="Exeggutor",[104]="Cubone",[105]="Marowak",[106]="Hitmonlee",
  [107]="Hitmonchan",[108]="Lickitung",[109]="Koffing",[110]="Weezing",
  [111]="Rhyhorn",[112]="Rhydon",[113]="Chansey",[114]="Tangela",
  [115]="Kangaskhan",[116]="Horsea",[117]="Seadra",[118]="Goldeen",
  [119]="Seaking",[120]="Staryu",[121]="Starmie",[122]="Mr. Mime",
  [123]="Scyther",[124]="Jynx",[125]="Electabuzz",[126]="Magmar",
  [127]="Pinsir",[128]="Tauros",[129]="Magikarp",[130]="Gyarados",
  [131]="Lapras",[132]="Ditto",[133]="Eevee",[134]="Vaporeon",
  [135]="Jolteon",[136]="Flareon",[137]="Porygon",[138]="Omanyte",
  [139]="Omastar",[140]="Kabuto",[141]="Kabutops",[142]="Aerodactyl",
  [143]="Snorlax",[144]="Articuno",[145]="Zapdos",[146]="Moltres",
  [147]="Dratini",[148]="Dragonair",[149]="Dragonite",[150]="Mewtwo",
  [151]="Mew",
  -- Gen 2 / Johto (152-251)
  [152]="Chikorita",[153]="Bayleef",[154]="Meganium",
  [155]="Cyndaquil",[156]="Quilava",[157]="Typhlosion",
  [158]="Totodile",[159]="Croconaw",[160]="Feraligatr",
  [161]="Sentret",[162]="Furret",[163]="Hoothoot",[164]="Noctowl",
  [165]="Ledyba",[166]="Ledian",[167]="Spinarak",[168]="Ariados",
  [169]="Crobat",[170]="Chinchou",[171]="Lanturn",[172]="Pichu",
  [173]="Cleffa",[174]="Igglybuff",[175]="Togepi",[176]="Togetic",
  [177]="Natu",[178]="Xatu",[179]="Mareep",[180]="Flaaffy",
  [181]="Ampharos",[182]="Bellossom",[183]="Marill",[184]="Azumarill",
  [185]="Sudowoodo",[186]="Politoed",[187]="Hoppip",[188]="Skiploom",
  [189]="Jumpluff",[190]="Aipom",[191]="Sunkern",[192]="Sunflora",
  [193]="Yanma",[194]="Wooper",[195]="Quagsire",[196]="Espeon",
  [197]="Umbreon",[198]="Murkrow",[199]="Slowking",[200]="Misdreavus",
  [201]="Unown",[202]="Wobbuffet",[203]="Girafarig",[204]="Pineco",
  [205]="Forretress",[206]="Dunsparce",[207]="Gligar",[208]="Steelix",
  [209]="Snubbull",[210]="Granbull",[211]="Qwilfish",[212]="Scizor",
  [213]="Shuckle",[214]="Heracross",[215]="Sneasel",[216]="Teddiursa",
  [217]="Ursaring",[218]="Slugma",[219]="Magcargo",[220]="Swinub",
  [221]="Piloswine",[222]="Corsola",[223]="Remoraid",[224]="Octillery",
  [225]="Delibird",[226]="Mantine",[227]="Skarmory",[228]="Houndour",
  [229]="Houndoom",[230]="Kingdra",[231]="Phanpy",[232]="Donphan",
  [233]="Porygon2",[234]="Stantler",[235]="Smeargle",[236]="Tyrogue",
  [237]="Hitmontop",[238]="Smoochum",[239]="Elekid",[240]="Magby",
  [241]="Miltank",[242]="Blissey",[243]="Raikou",[244]="Entei",
  [245]="Suicune",[246]="Larvitar",[247]="Pupitar",[248]="Tyranitar",
  [249]="Lugia",[250]="Ho-Oh",[251]="Celebi",
  -- Gen 3 / Hoenn (252-386)
  [252]="Treecko",[253]="Grovyle",[254]="Sceptile",
  [255]="Torchic",[256]="Combusken",[257]="Blaziken",
  [258]="Mudkip",[259]="Marshtomp",[260]="Swampert",
  [261]="Poochyena",[262]="Mightyena",[263]="Zigzagoon",[264]="Linoone",
  [265]="Wurmple",[266]="Silcoon",[267]="Beautifly",[268]="Cascoon",
  [269]="Dustox",[270]="Lotad",[271]="Lombre",[272]="Ludicolo",
  [273]="Seedot",[274]="Nuzleaf",[275]="Shiftry",
  [276]="Taillow",[277]="Swellow",[278]="Wingull",[279]="Pelipper",
  [280]="Ralts",[281]="Kirlia",[282]="Gardevoir",
  [283]="Surskit",[284]="Masquerain",[285]="Shroomish",[286]="Breloom",
  [287]="Slakoth",[288]="Vigoroth",[289]="Slaking",
  [290]="Nincada",[291]="Ninjask",[292]="Shedinja",
  [293]="Whismur",[294]="Loudred",[295]="Exploud",
  [296]="Makuhita",[297]="Hariyama",
  [298]="Azurill",[299]="Nosepass",
  [300]="Skitty",[301]="Delcatty",
  [302]="Sableye",[303]="Mawile",
  [304]="Aron",[305]="Lairon",[306]="Aggron",
  [307]="Meditite",[308]="Medicham",
  [309]="Electrike",[310]="Manectric",
  [311]="Plusle",[312]="Minun",
  [313]="Volbeat",[314]="Illumise",
  [315]="Roselia",[316]="Gulpin",[317]="Swalot",
  [318]="Carvanha",[319]="Sharpedo",
  [320]="Wailmer",[321]="Wailord",
  [322]="Numel",[323]="Camerupt",
  [324]="Torkoal",[325]="Spoink",[326]="Grumpig",
  [327]="Spinda",[328]="Trapinch",[329]="Vibrava",[330]="Flygon",
  [331]="Cacnea",[332]="Cacturne",
  [333]="Swablu",[334]="Altaria",
  [335]="Zangoose",[336]="Seviper",
  [337]="Lunatone",[338]="Solrock",
  [339]="Barboach",[340]="Whiscash",
  [341]="Corphish",[342]="Crawdaunt",
  [343]="Baltoy",[344]="Claydol",
  [345]="Lileep",[346]="Cradily",
  [347]="Anorith",[348]="Armaldo",
  [349]="Feebas",[350]="Milotic",
  [351]="Castform",[352]="Kecleon",
  [353]="Shuppet",[354]="Banette",
  [355]="Duskull",[356]="Dusclops",
  [357]="Tropius",[358]="Chimecho",
  [359]="Absol",[360]="Wynaut",
  [361]="Snorunt",[362]="Glalie",
  [363]="Spheal",[364]="Sealeo",[365]="Walrein",
  [366]="Clamperl",[367]="Huntail",[368]="Gorebyss",
  [369]="Relicanth",[370]="Luvdisc",
  [371]="Bagon",[372]="Shelgon",[373]="Salamence",
  [374]="Beldum",[375]="Metang",[376]="Metagross",
  [377]="Regirock",[378]="Regice",[379]="Registeel",
  [380]="Latias",[381]="Latios",
  [382]="Kyogre",[383]="Groudon",[384]="Rayquaza",
  [385]="Jirachi",[386]="Deoxys",
}

-- ============================================================
-- Lê um bit do bitmap (array de bytes Lua, 1-indexed)
-- pokemonNumber: 1..412  → bit index 0..(pokemonNumber-1)
-- ============================================================
local function readDexBit(data, baseOffset, pokemonNumber)
  local bitIndex = pokemonNumber - 1
  local byteIndex = math.floor(bitIndex / 8)
  local bitPos = bitIndex % 8
  local byteVal = string.byte(data, baseOffset + byteIndex + 1) or 0
  return math.floor(byteVal / (2 ^ bitPos)) % 2 == 1
end

-- ============================================================
-- Localiza o setor 0 mais recente nos dois slots do save
-- Retorna: offset (em bytes, 0-based) do início do setor 0
-- ============================================================
local function findBestSector0(data)
  local bestOffset = nil
  local bestIndex = -1

  local function check(sectorOffset)
    -- Footer está nos últimos 12 bytes do setor (offset 0xFF4 dentro do setor)
    local footerBase = sectorOffset + 0x0FF4 + 1
    if footerBase + 11 > #data then return end
    local secId = string.byte(data, footerBase) + string.byte(data, footerBase+1)*256
    local sig   = string.byte(data, footerBase+4)
              + string.byte(data, footerBase+5)*256
              + string.byte(data, footerBase+6)*65536
              + string.byte(data, footerBase+7)*16777216
    local sIdx  = string.byte(data, footerBase+8)
              + string.byte(data, footerBase+9)*256
              + string.byte(data, footerBase+10)*65536
              + string.byte(data, footerBase+11)*16777216
    if sig == 0x08012025 and secId == 0 and sIdx > bestIndex then
      bestIndex = sIdx
      bestOffset = sectorOffset
    end
  end

  -- Slot A: setores 0-13 em 0x0000
  for i = 0, 13 do check(i * 4096) end
  -- Slot B: setores 0-13 em 0xE000
  for i = 0, 13 do check(0xE000 + i * 4096) end

  return bestOffset
end

-- ============================================================
-- API principal — lê o Pokédex completo do save
-- ============================================================
-- Offsets relativos ao início do setor 0 (FireRed BPRE):
--   0x0028 = caught bitmap  (52 bytes = 412 Pokémon em bits)
--   0x005C = seen bitmap    (52 bytes)
-- Nota: algumas ROM hacks movem esses offsets.
-- Tentamos 3 variantes para robustez.

local CANDIDATES = {
  { seen = 0x005C, caught = 0x0028 },  -- FireRed vanilla / maioria das hacks
  { seen = 0x0088, caught = 0x0054 },  -- Algumas hacks 251+
  { seen = 0x0028, caught = 0x005C },  -- Invertido (raro)
}

function GbaDex.readDex(filepath)
  local empty = {
    seen={}, caught={},
    seenKanto=0, seenJohto=0, seenNational=0,
    caughtKanto=0, caughtJohto=0, caughtNational=0,
    valid=false, error="Arquivo não encontrado"
  }

  if not filepath then return empty end
  local f = io.open(filepath, "rb")
  if not f then return empty end
  local data = f:read("*a")
  f:close()

  if #data < 0x10000 then
    empty.error = "Save muito pequeno (" .. #data .. " bytes)"
    return empty
  end

  local sec0Offset = findBestSector0(data)
  if not sec0Offset then
    empty.error = "Setor 0 não encontrado (save inválido ou corrompido)"
    return empty
  end

  -- Testa cada candidato de offset — usa o que tiver mais bits definidos
  local bestSeen, bestCaught, bestTotal = nil, nil, -1

  for _, cand in ipairs(CANDIDATES) do
    local seenOff   = sec0Offset + cand.seen
    local caughtOff = sec0Offset + cand.caught

    -- Verificação de bounds (52 bytes cada)
    if seenOff + 52 <= #data and caughtOff + 52 <= #data then
      local count = 0
      for n = 1, 251 do
        if readDexBit(data, seenOff, n) then count = count + 1 end
        if readDexBit(data, caughtOff, n) then count = count + 1 end
      end
      if count > bestTotal then
        bestTotal   = count
        bestSeen    = seenOff
        bestCaught  = caughtOff
      end
    end
  end

  if not bestSeen then
    empty.error = "Offsets do Pokédex fora dos limites do save"
    return empty
  end

  -- Extrai os bitmaps
  local seen   = {}
  local caught = {}
  local seenKanto, seenJohto, seenNational = 0, 0, 0
  local caughtKanto, caughtJohto, caughtNational = 0, 0, 0

  for n = 1, 386 do
    local s = readDexBit(data, bestSeen, n)
    local c = readDexBit(data, bestCaught, n)
    seen[n]   = s
    caught[n] = c

    if s then
      seenNational = seenNational + 1
      if n <= 151 then seenKanto = seenKanto + 1
      elseif n <= 251 then seenJohto = seenJohto + 1 end
    end
    if c then
      caughtNational = caughtNational + 1
      if n <= 151 then caughtKanto = caughtKanto + 1
      elseif n <= 251 then caughtJohto = caughtJohto + 1 end
    end
  end

  return {
    seen   = seen,
    caught = caught,
    seenKanto      = seenKanto,
    seenJohto      = seenJohto,
    seenNational   = seenNational,
    caughtKanto    = caughtKanto,
    caughtJohto    = caughtJohto,
    caughtNational = caughtNational,
    valid = true,
    error = nil,
    -- Metadados de debug
    _sec0Offset  = sec0Offset,
    _seenOffset  = bestSeen,
    _caughtOffset = bestCaught,
  }
end

return GbaDex
