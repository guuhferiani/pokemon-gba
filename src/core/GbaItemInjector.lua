local GbaItemInjector = {}

-- Gen 3 Item Database (with PT-BR names, descriptions, and categories)
GbaItemInjector.ITEMS = {
  -- Pokébolas (Pocket: balls)
  { id = 0x0001, name = "Master Ball", pocket = "balls", cat = "balls", desc = "Captura qualquer Pokémon selvagem sem falhar." },
  { id = 0x0002, name = "Ultra Ball", pocket = "balls", cat = "balls", desc = "Excelente taxa de sucesso de captura." },
  { id = 0x0003, name = "Great Ball", pocket = "balls", cat = "balls", desc = "Boa taxa de sucesso de captura." },
  { id = 0x0004, name = "Poké Ball", pocket = "balls", cat = "balls", desc = "A clássica esfera de captura de Pokémon." },
  { id = 0x0005, name = "Safari Ball", pocket = "balls", cat = "balls", desc = "Esfera especial usada na Zona Safari." },
  { id = 0x0006, name = "Net Ball", pocket = "balls", cat = "balls", desc = "Mais eficaz contra tipos Água e Inseto." },
  { id = 0x0007, name = "Dive Ball", pocket = "balls", cat = "balls", desc = "Mais eficaz em Pokémon encontrados na água." },
  { id = 0x0008, name = "Nest Ball", pocket = "balls", cat = "balls", desc = "Mais eficaz contra Pokémon de níveis mais baixos." },
  { id = 0x0009, name = "Repeat Ball", pocket = "balls", cat = "balls", desc = "Mais eficaz em espécies já capturadas na Pokédex." },
  { id = 0x000A, name = "Timer Ball", pocket = "balls", cat = "balls", desc = "Fica mais eficaz a cada turno de batalha." },
  { id = 0x000B, name = "Luxury Ball", pocket = "balls", cat = "balls", desc = "Aumenta a felicidade e afeição do Pokémon mais rápido." },
  { id = 0x000C, name = "Premier Ball", pocket = "balls", cat = "balls", desc = "Esfera comemorativa com visual branco especial." },

  -- Itens Raros & Cura (Pocket: items)
  { id = 0x0044, name = "Doce Raro (Rare Candy)", pocket = "items", cat = "rare", desc = "Aumenta instantaneamente o Pokémon em 1 nível." },
  { id = 0x0013, name = "Restaura Tudo (Full Restore)", pocket = "items", cat = "healing", desc = "Restaura todo o HP e cura todas as condições de status." },
  { id = 0x0014, name = "Poção Máxima (Max Potion)", pocket = "items", cat = "healing", desc = "Restaura todo o HP do Pokémon." },
  { id = 0x0015, name = "Hiper Poção (Hyper Potion)", pocket = "items", cat = "healing", desc = "Restaura 200 pontos de HP." },
  { id = 0x0019, name = "Reviver Máximo (Max Revive)", pocket = "items", cat = "healing", desc = "Revive um Pokémon desmaiado com 100% de HP." },
  { id = 0x0018, name = "Reviver (Revive)", pocket = "items", cat = "healing", desc = "Revive um Pokémon com metade do HP máximo." },
  { id = 0x0024, name = "Elixir Máximo (Max Elixir)", pocket = "items", cat = "healing", desc = "Restaura todos os PPs de todos os 4 golpes do Pokémon." },
  { id = 0x0047, name = "PP Máximo (PP Max)", pocket = "items", cat = "rare", desc = "Aumenta os pontos de PP de um golpe para o máximo possível." },
  { id = 0x0045, name = "PP Up", pocket = "items", cat = "rare", desc = "Aumenta ligeiramente a capacidade de PP de um golpe." },
  { id = 0x001E, name = "Cura Total (Full Heal)", pocket = "items", cat = "healing", desc = "Cura qualquer problema de status (veneno, sono, paralisia, etc.)." },
  { id = 0x0054, name = "Repelente Máximo (Max Repel)", pocket = "items", cat = "items", desc = "Evita encontros com Pokémon selvagens fracos por 250 passos." },
  { id = 0x0055, name = "Corda de Fuga (Escape Rope)", pocket = "items", cat = "items", desc = "Teleporta instantaneamente para fora de cavernas e masmorras." },

  -- Pedras de Evolução (Pocket: items)
  { id = 0x005E, name = "Pedra do Fogo (Fire Stone)", pocket = "items", cat = "stones", desc = "Evolui Vulpix, Growlithe, Eevee." },
  { id = 0x005F, name = "Pedra do Trovão (Thunder Stone)", pocket = "items", cat = "stones", desc = "Evolui Pikachu, Eevee." },
  { id = 0x0060, name = "Pedra da Água (Water Stone)", pocket = "items", cat = "stones", desc = "Evolui Poliwhirl, Shellder, Staryu, Eevee, Lombre." },
  { id = 0x0061, name = "Pedra da Folha (Leaf Stone)", pocket = "items", cat = "stones", desc = "Evolui Gloom, Weepinbell, Exeggcute, Nuzleaf." },
  { id = 0x005D, name = "Pedra da Lua (Moon Stone)", pocket = "items", cat = "stones", desc = "Evolui Nidorina, Nidorino, Clefairy, Jigglypuff, Skitty." },
  { id = 0x005C, name = "Pedra do Sol (Sun Stone)", pocket = "items", cat = "stones", desc = "Evolui Gloom -> Bellossom, Sunkern -> Sunflora." },

  -- Itens de Treino e Segurar (Pocket: items)
  { id = 0x00B6, name = "Divisor de XP (Exp. Share)", pocket = "items", cat = "hold", desc = "O Pokémon que segurar recebe 50% do XP de todas as batalhas." },
  { id = 0x00C3, name = "Ovo da Sorte (Lucky Egg)", pocket = "items", cat = "hold", desc = "O Pokémon que segurar ganha 150% de XP em todas as batalhas." },
  { id = 0x00C9, name = "Restos (Leftovers)", pocket = "items", cat = "hold", desc = "Restaura 1/16 do HP máximo do Pokémon a cada turno da batalha." },
  { id = 0x00D6, name = "Sino Conforto (Soothe Bell)", pocket = "items", cat = "hold", desc = "Aumenta a felicidade do Pokémon mais rapidamente." },
  { id = 0x00C5, name = "Faixa Foco (Focus Band)", pocket = "items", cat = "hold", desc = "Dá chance de sobreviver a um ataque fatal com 1 de HP." },
  { id = 0x00B5, name = "Moeda Amuleto (Amulet Coin)", pocket = "items", cat = "hold", desc = "Dobra todo o dinheiro ganho em batalhas contra treinadores." },
  { id = 0x00C0, name = "Pedra Dura (Hard Stone)", pocket = "items", cat = "hold", desc = "Aumenta o dano de ataques do tipo Pedra." },
  { id = 0x00BF, name = "Carvão (Charcoal)", pocket = "items", cat = "hold", desc = "Aumenta o dano de ataques do tipo Fogo." },
  { id = 0x00BE, name = "Água Mística (Mystic Water)", pocket = "items", cat = "hold", desc = "Aumenta o dano de ataques do tipo Água." },
  { id = 0x00C7, name = "Imã (Magnet)", pocket = "items", cat = "hold", desc = "Aumenta o dano de ataques do tipo Elétrico." },
  { id = 0x00D1, name = "Semente Milagrosa (Miracle Seed)", pocket = "items", cat = "hold", desc = "Aumenta o dano de ataques do tipo Planta." },
  { id = 0x00B7, name = "Garra Rápida (Quick Claw)", pocket = "items", cat = "hold", desc = "Dá chance ao Pokémon de atacar sempre primeiro no turno." },

  -- Vitaminas e Fortalecedores (Pocket: items)
  { id = 0x003F, name = "Proteína (Protein)", pocket = "items", cat = "rare", desc = "Aumenta os pontos de esforço (EVs) de Ataque." },
  { id = 0x0040, name = "Ferro (Iron)", pocket = "items", cat = "rare", desc = "Aumenta os pontos de esforço (EVs) de Defesa." },
  { id = 0x0041, name = "Carboidrato (Carbos)", pocket = "items", cat = "rare", desc = "Aumenta os pontos de esforço (EVs) de Velocidade." },
  { id = 0x0042, name = "Cálcio (Calcium)", pocket = "items", cat = "rare", desc = "Aumenta os pontos de esforço (EVs) de Ataque Especial." },
  { id = 0x0046, name = "Zinco (Zinc)", pocket = "items", cat = "rare", desc = "Aumenta os pontos de esforço (EVs) de Defesa Especial." },
  { id = 0x003E, name = "HP Up", pocket = "items", cat = "rare", desc = "Aumenta os pontos de esforço (EVs) de HP." }
}

-- Pockets configuration for FireRed (BPRE) in Section 1
local POCKET_OFFSETS = {
  items = { offset = 0x0310, max = 42 },
  balls = { offset = 0x0430, max = 13 },
  key_items = { offset = 0x03B8, max = 30 },
  tms = { offset = 0x0464, max = 58 },
  pc = { offset = 0x0298, max = 30 }
}

-- Section Data Sizes for Checksum calculation
local SECTION_SIZES = {
  [0] = 3884,
  [1] = 3968,
  [2] = 3968,
  [3] = 3968,
  [4] = 3848,
  [5] = 3968,
  [6] = 3968,
  [7] = 3968,
  [8] = 3968,
  [9] = 3968,
  [10] = 3968,
  [11] = 3968,
  [12] = 3968,
  [13] = 2000
}

local function readUint16(str, offset)
  local b1 = string.byte(str, offset)
  local b2 = string.byte(str, offset + 1)
  return b1 + b2 * 256
end

local function writeUint16(bytes, offset, val)
  bytes[offset] = val % 256
  bytes[offset + 1] = math.floor(val / 256) % 256
end

local function readUint32(str, offset)
  local b1 = string.byte(str, offset)
  local b2 = string.byte(str, offset + 1)
  local b3 = string.byte(str, offset + 2)
  local b4 = string.byte(str, offset + 3)
  return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function writeUint32(bytes, offset, val)
  bytes[offset] = val % 256
  bytes[offset + 1] = math.floor(val / 256) % 256
  bytes[offset + 2] = math.floor(val / 65536) % 256
  bytes[offset + 3] = math.floor(val / 16777216) % 256
end

-- Calculate Gen 3 Section Checksum
local function calculateChecksum(bytes, secOffset, secId)
  local size = SECTION_SIZES[secId] or 3968
  local wordsCount = math.floor(size / 4)
  local sum = 0

  for w = 0, wordsCount - 1 do
    local off = secOffset + w * 4 + 1
    local b1 = bytes[off] or 0
    local b2 = bytes[off + 1] or 0
    local b3 = bytes[off + 2] or 0
    local b4 = bytes[off + 3] or 0
    local word = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
    sum = (sum + word) % 4294967296
  end

  local lower16 = sum % 65536
  local upper16 = math.floor(sum / 65536) % 65536
  local chk = (lower16 + upper16) % 65536
  return chk
end

function GbaItemInjector.getItemById(itemId)
  for _, it in ipairs(GbaItemInjector.ITEMS) do
    if it.id == itemId then return it end
  end
  return nil
end

-- Backup save before writing
local function backupSave(filepath)
  local f = io.open(filepath, "rb")
  if not f then return false end
  local content = f:read("*a")
  f:close()

  local backupDir = "saves/backups"
  if love.filesystem then
    love.filesystem.createDirectory(backupDir)
  else
    os.execute('mkdir "' .. backupDir:gsub('/', '\\') .. '" 2>nul')
  end

  local filename = filepath:match("([^/\\]+)$") or "save.sav"
  local timeStr = os.date("%Y%m%d_%H%M%S")
  local backupPath = backupDir .. "/" .. filename:gsub("%.sav$", "") .. "_" .. timeStr .. ".sav"

  local bf = io.open(backupPath, "wb")
  if bf then
    bf:write(content)
    bf:close()
  end
  return true
end

-- Find the active Slot (A: 0x0000..0xDFFF or B: 0xE000..0x1BFFF) with highest save index
local function findActiveSections(dataStr)
  local bestSlotBase = 0
  local highestSaveIndex = -1
  local slotASaveIndex = -1
  local slotBSaveIndex = -1

  local function scanSlot(baseOffset)
    local secMap = {}
    local maxIdx = -1
    for sec = 0, 13 do
      local offset = baseOffset + sec * 4096
      local footerOffset = offset + 0x0FF4 + 1
      if footerOffset + 11 <= #dataStr then
        local secId = string.byte(dataStr, footerOffset) + string.byte(dataStr, footerOffset + 1) * 256
        local sig = string.byte(dataStr, footerOffset + 4) + string.byte(dataStr, footerOffset + 5) * 256
          + string.byte(dataStr, footerOffset + 6) * 65536 + string.byte(dataStr, footerOffset + 7) * 16777216
        local sIndex = string.byte(dataStr, footerOffset + 8) + string.byte(dataStr, footerOffset + 9) * 256
          + string.byte(dataStr, footerOffset + 10) * 65536 + string.byte(dataStr, footerOffset + 11) * 16777216

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

  if idxB > idxA then
    return mapB, 0xE000, idxB
  else
    return mapA, 0, idxA
  end
end

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

-- Inject item into save file
function GbaItemInjector.injectItem(filepath, itemId, quantity, pocketKey)
  quantity = math.max(1, math.min(quantity or 99, 999))
  pocketKey = pocketKey or "items"

  local itemDef = GbaItemInjector.getItemById(itemId)
  if itemDef and itemDef.pocket then
    pocketKey = itemDef.pocket
  end

  local pConfig = POCKET_OFFSETS[pocketKey] or POCKET_OFFSETS.items

  local f = io.open(filepath, "rb")
  if not f then
    return false, "Não foi possível abrir o arquivo de save: " .. tostring(filepath)
  end
  local content = f:read("*a")
  f:close()

  if #content < 0x10000 then
    return false, "Arquivo de save muito pequeno ou inválido."
  end

  backupSave(filepath)

  -- Convert string to mutable byte array (1-indexed)
  local bytes = {}
  for i = 1, #content do
    bytes[i] = string.byte(content, i)
  end

  local secMap, slotBase, saveIndex = findActiveSections(content)
  local sec0Offset = secMap[0]
  local sec1Offset = secMap[1]

  if not sec1Offset then
    return false, "Seção de Itens (Section 1) não encontrada no save."
  end

  -- In FireRed, item quantities in the Bag pockets are XORed with Section 0 security key (+0x0AF8)
  local secKey = 0
  if sec0Offset then
    local keyPos = sec0Offset + 0x0AF8 + 1
    secKey = (bytes[keyPos] or 0) + (bytes[keyPos + 1] or 0) * 256
      + (bytes[keyPos + 2] or 0) * 65536 + (bytes[keyPos + 3] or 0) * 16777216
  end
  local secKey16 = secKey % 65536

  -- Search for existing item in pocket to increase quantity, or find first empty slot
  local pocketStart = sec1Offset + pConfig.offset
  local targetSlotIndex = nil
  local existingSlotIndex = nil

  for s = 0, pConfig.max - 1 do
    local itemPos = pocketStart + s * 4 + 1
    local curId = bytes[itemPos] + bytes[itemPos + 1] * 256

    if curId == itemId then
      existingSlotIndex = s
      break
    elseif curId == 0 and not targetSlotIndex then
      targetSlotIndex = s
    end
  end

  local finalSlot = existingSlotIndex or targetSlotIndex
  if not finalSlot then
    return false, "O bolso da mochila (" .. pocketKey .. ") está cheio!"
  end

  -- Encode quantity with security key for bag items (PC items are not encrypted)
  local encQuantity = (pocketKey == "pc") and quantity or bxor(quantity, secKey16)

  local finalPos = pocketStart + finalSlot * 4 + 1
  writeUint16(bytes, finalPos, itemId)
  writeUint16(bytes, finalPos + 2, encQuantity)

  -- Also inject a duplicate copy into PC Storage (Pocket 0x0298) as backup
  local pcStart = sec1Offset + POCKET_OFFSETS.pc.offset
  for ps = 0, POCKET_OFFSETS.pc.max - 1 do
    local pcPos = pcStart + ps * 4 + 1
    local curPcId = bytes[pcPos] + bytes[pcPos + 1] * 256
    if curPcId == itemId or curPcId == 0 then
      writeUint16(bytes, pcPos, itemId)
      writeUint16(bytes, pcPos + 2, quantity)
      break
    end
  end

  -- Recalculate Section 1 Checksum
  local newChecksum = calculateChecksum(bytes, sec1Offset, 1)
  local chkPos = sec1Offset + 0x0FF6 + 1
  writeUint16(bytes, chkPos, newChecksum)

  -- Write back to save file
  local outStr = {}
  for i = 1, #bytes do
    outStr[i] = string.char(bytes[i])
  end

  local wf = io.open(filepath, "wb")
  if not wf then
    return false, "Não foi possível gravar as alterações no save."
  end
  wf:write(table.concat(outStr))
  wf:close()

  local itemName = itemDef and itemDef.name or ("Item #" .. itemId)
  return true, string.format("%dx %s adicionado(s) com sucesso à sua Mochila!", quantity, itemName)
end

-- Inject Money into save file
function GbaItemInjector.injectMoney(filepath, amount)
  amount = math.max(0, math.min(amount or 999999, 999999))

  local f = io.open(filepath, "rb")
  if not f then return false, "Não foi possível abrir o save." end
  local content = f:read("*a")
  f:close()

  if #content < 0x10000 then return false, "Save inválido." end

  backupSave(filepath)

  local bytes = {}
  for i = 1, #content do bytes[i] = string.byte(content, i) end

  local secMap = findActiveSections(content)
  local sec0Offset = secMap[0]
  local sec1Offset = secMap[1]

  if not sec0Offset or not sec1Offset then
    return false, "Estrutura do save não identificada."
  end

  -- Read Security Key from Section 0 at +0x0AF8
  local keyPos = sec0Offset + 0x0AF8 + 1
  local secKey = bytes[keyPos] + bytes[keyPos + 1] * 256 + bytes[keyPos + 2] * 65536 + bytes[keyPos + 3] * 16777216

  -- In FireRed, Money is stored at Section 1 +0x0290, XORed with security key
  local moneyVal = bit and bit.bxor and bit.bxor(amount, secKey) or (amount)
  local moneyPos = sec1Offset + 0x0290 + 1
  writeUint32(bytes, moneyPos, moneyVal)

  -- Recalculate Section 1 Checksum
  local newChecksum = calculateChecksum(bytes, sec1Offset, 1)
  writeUint16(bytes, sec1Offset + 0x0FF6 + 1, newChecksum)

  local outStr = {}
  for i = 1, #bytes do outStr[i] = string.char(bytes[i]) end

  local wf = io.open(filepath, "wb")
  if not wf then return false, "Erro ao gravar save." end
  wf:write(table.concat(outStr))
  wf:close()

  return true, string.format("Dinheiro atualizado para $%d PokéDollars!", amount)
end

-- Unlock National Pokedex mode in Save (enables National Dex UI, preserves real capture data)
function GbaItemInjector.unlockNationalDex(filepath)
  local f = io.open(filepath, "rb")
  if not f then return false, "Não foi possível abrir o save." end
  local content = f:read("*a")
  f:close()

  if #content < 0x10000 then return false, "Save inválido." end

  backupSave(filepath)

  local bytes = {}
  for i = 1, #content do bytes[i] = string.byte(content, i) end

  local secMap = findActiveSections(content)
  local sec0Offset = secMap[0]
  local sec1Offset = secMap[1]
  local sec2Offset = secMap[2]

  if not sec0Offset or not sec1Offset or not sec2Offset then
    return false, "Estrutura do save não encontrada."
  end

  -- 1. Enable National Dex mode in Section 0 (SaveBlock2)
  -- In this PT-BR BPRE build, nationalMagic is at SaveBlock2+0x1B (not +0x1A).
  -- Confirmed by disassembly: LDRB R0,[R0,#0x1B] / CMP R0,#0xB9 in IsNationalPokedexEnabled.
  bytes[sec0Offset + 0x0018 + 1] = 0x01 -- pokedex.order
  bytes[sec0Offset + 0x0019 + 1] = 0x01 -- pokedex.mode (has Pokedex)
  bytes[sec0Offset + 0x0019 + 1] = 0x01 -- Has Pokédex
  bytes[sec0Offset + 0x001A + 1] = 0x01 -- dex mode flag
  bytes[sec0Offset + 0x001B + 1] = 0xB9 -- nationalMagic = 0xB9 (CORRECT offset for this ROM)
  -- NOTE: Owned/Seen bitmaps (0x28, 0x5C, 0x90, 0xC4) are intentionally NOT modified.
  -- The player's real captured Pokémon data from gameplay is preserved exactly as-is.

  -- 2. Set National Dex Flags in Section 1 (Offset +0x0EE0 & Offset +0x0E5C)
  local binaryFlagByte = sec1Offset + 0x0E5C + 1
  if binaryFlagByte <= #bytes then
    local cur = bytes[binaryFlagByte] or 0
    bytes[binaryFlagByte] = cur % 2 < 1 and (cur + 1) or cur
  end

  -- FLAG_SYS_NATIONAL_DEX (0x829)
  local natFlagByte = sec1Offset + 0x0EE0 + math.floor(0x829 / 8) + 1
  if natFlagByte <= #bytes then
    local cur = bytes[natFlagByte] or 0
    bytes[natFlagByte] = cur % 4 < 2 and (cur + 2) or cur -- set bit 1 (0x02)
  end

  -- FLAG_SYS_POKEDEX_GET (0x82A)
  local pokFlagByte = sec1Offset + 0x0EE0 + math.floor(0x82A / 8) + 1
  if pokFlagByte <= #bytes then
    local cur = bytes[pokFlagByte] or 0
    bytes[pokFlagByte] = cur % 8 < 4 and (cur + 4) or cur -- set bit 2 (0x04)
  end

  -- 3. Set VAR_NATIONAL_DEX (0x404E) = 0x6258 in Section 1 (+0x0F10) & Section 2 (+0x009C)
  writeUint16(bytes, sec1Offset + 0x0F10 + 1, 0x6258)
  local varOffset = sec2Offset + (0x404E - 0x4000) * 2
  writeUint16(bytes, varOffset + 1, 0x6258)

  -- Recalculate Section 0, 1 and 2 Checksums
  local chk0 = calculateChecksum(bytes, sec0Offset, 0)
  writeUint16(bytes, sec0Offset + 0x0FF6 + 1, chk0)

  local chk1 = calculateChecksum(bytes, sec1Offset, 1)
  writeUint16(bytes, sec1Offset + 0x0FF6 + 1, chk1)

  local chk2 = calculateChecksum(bytes, sec2Offset, 2)
  writeUint16(bytes, sec2Offset + 0x0FF6 + 1, chk2)

  local outStr = {}
  for i = 1, #bytes do outStr[i] = string.char(bytes[i]) end

  local wf = io.open(filepath, "wb")
  if not wf then return false, "Erro ao gravar save." end
  wf:write(table.concat(outStr))
  wf:close()

  return true, "Pokédex Nacional desbloqueada! Seus Pokémon capturados foram preservados."
end

-- Fast-Forward Test Tool: Unlocks Kanto Champion, 8 Badges, S.S. Ticket and Johto access
function GbaItemInjector.unlockKantoChampAndJohto(filepath)
  local f = io.open(filepath, "rb")
  if not f then return false, "Não foi possível abrir o save." end
  local content = f:read("*a")
  f:close()

  if #content < 0x10000 then return false, "Save inválido." end

  backupSave(filepath)

  local bytes = {}
  for i = 1, #content do bytes[i] = string.byte(content, i) end

  local secMap = findActiveSections(content)
  local sec0Offset = secMap[0]
  local sec1Offset = secMap[1]
  local sec2Offset = secMap[2]

  if not sec0Offset or not sec1Offset or not sec2Offset then
    return false, "Estrutura do save não encontrada."
  end

  -- 1. All 8 Kanto Badges (0x820..0x827)
  local badgeByte = sec1Offset + 0x0EE0 + math.floor(0x820 / 8) + 1
  bytes[badgeByte] = 0xFF -- All 8 badges acquired!

  -- 2. Hall of Fame Clear flag (0x82C) & National Dex Flag (0x829)
  local clearByte = sec1Offset + 0x0EE0 + math.floor(0x82C / 8) + 1
  bytes[clearByte] = (bytes[clearByte] or 0) % 32 < 16 and (bytes[clearByte] + 0x10) or bytes[clearByte]

  -- 3. Enable Ferry & Sevii/Johto Access Flags (0x844, 0x845, 0x846)
  local ferryByte = sec1Offset + 0x0EE0 + math.floor(0x844 / 8) + 1
  bytes[ferryByte] = 0xFF

  -- Recalculate Checksums
  local chk0 = calculateChecksum(bytes, sec0Offset, 0)
  writeUint16(bytes, sec0Offset + 0x0FF6 + 1, chk0)

  local chk1 = calculateChecksum(bytes, sec1Offset, 1)
  writeUint16(bytes, sec1Offset + 0x0FF6 + 1, chk1)

  local chk2 = calculateChecksum(bytes, sec2Offset, 2)
  writeUint16(bytes, sec2Offset + 0x0FF6 + 1, chk2)

  local outStr = {}
  for i = 1, #bytes do outStr[i] = string.char(bytes[i]) end

  local wf = io.open(filepath, "wb")
  if not wf then return false, "Erro ao gravar save." end
  wf:write(table.concat(outStr))
  wf:close()

  -- Also inject National Dex & Rare Candies
  GbaItemInjector.unlockNationalDex(filepath)
  GbaItemInjector.injectItem(filepath, 0x0044, 99, "items") -- Rare Candies
  GbaItemInjector.injectItem(filepath, 0x0001, 99, "balls") -- Master Balls
  GbaItemInjector.injectMoney(filepath, 999999)

  return true, "Status de Campeão de Kanto (8 Insígnias, Hall da Fama e Acesso a Johto) ativado com sucesso!"
end

return GbaItemInjector
