local TextureAtlas = {}

-- Atlas size: 512x512
-- Grid of 32x32 tiles (16 columns x 16 rows)
TextureAtlas.TILE_SIZE = 32
TextureAtlas.ATLAS_SIZE = 512

TextureAtlas.TILES = {
  GRASS        = { col = 0, row = 0 },
  TALL_GRASS   = { col = 1, row = 0 },
  PATH_DIRT    = { col = 2, row = 0 },
  PATH_STONE   = { col = 3, row = 0 },
  WATER        = { col = 4, row = 0 },
  CLIFF_TOP    = { col = 5, row = 0 },
  CLIFF_SIDE   = { col = 6, row = 0 },
  FOLIAGE      = { col = 7, row = 0 },
  FOLIAGE_TOP  = { col = 8, row = 0 },
  WOOD_BARK    = { col = 9, row = 0 },
  WALL_WHITE   = { col = 0, row = 1 },
  WALL_BRICK   = { col = 1, row = 1 },
  ROOF_RED     = { col = 2, row = 1 },
  ROOF_BLUE    = { col = 3, row = 1 },
  DOOR         = { col = 4, row = 1 },
  WINDOW       = { col = 5, row = 1 },
  FENCE_WHITE  = { col = 6, row = 1 },
  SIGN_WOOD    = { col = 7, row = 1 },
  FLOWER_RED   = { col = 8, row = 1 },
  FLOWER_YELLOW= { col = 9, row = 1 },
  CARPET_LAB   = { col = 0, row = 2 },
  COMPUTER_LAB = { col = 1, row = 2 },
  POKEBALL_DEC = { col = 2, row = 2 },
  SAND         = { col = 3, row = 2 },
  BRIDGE_WOOD  = { col = 4, row = 2 },
  SHADOW       = { col = 5, row = 2 },
}

-- Returns UV coordinates { u1, v1, u2, v2 } for a tile
function TextureAtlas.getUV(tileKey)
  local t = TextureAtlas.TILES[tileKey] or TextureAtlas.TILES.GRASS
  local ts = TextureAtlas.TILE_SIZE
  local as = TextureAtlas.ATLAS_SIZE
  local u1 = (t.col * ts) / as
  local v1 = (t.row * ts) / as
  local u2 = ((t.col + 1) * ts) / as
  local v2 = ((t.row + 1) * ts) / as
  return { u1, v1, u2, v2 }
end

function TextureAtlas.generate()
  local as = TextureAtlas.ATLAS_SIZE
  local ts = TextureAtlas.TILE_SIZE
  local canvas = love.graphics.newCanvas(as, as)

  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)

  local function drawTile(tileKey, drawFunc)
    local t = TextureAtlas.TILES[tileKey]
    if not t then return end
    local x = t.col * ts
    local y = t.row * ts
    love.graphics.push()
    love.graphics.translate(x, y)
    drawFunc(ts)
    love.graphics.pop()
  end

  -- 1. Grass (Authentic Kanto Emerald green)
  drawTile("GRASS", function(s)
    love.graphics.setColor(88/255, 184/255, 72/255, 1) -- base grass
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(112/255, 208/255, 88/255, 1) -- light spots
    love.graphics.points(4, 4, 18, 6, 8, 22, 26, 20, 14, 14, 28, 8)
    love.graphics.setColor(64/255, 152/255, 56/255, 1) -- dark shadow dots
    love.graphics.points(5, 5, 19, 7, 9, 23, 27, 21)
  end)

  -- 2. Tall Grass (Wild Pokémon Encounter Grass)
  drawTile("TALL_GRASS", function(s)
    love.graphics.setColor(64/255, 152/255, 56/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(120/255, 224/255, 80/255, 1)
    for i = 4, s - 4, 6 do
      love.graphics.polygon("fill", i, s - 2, i + 3, 6, i + 6, s - 2)
    end
    love.graphics.setColor(40/255, 120/255, 40/255, 1)
    for i = 7, s - 3, 6 do
      love.graphics.polygon("fill", i, s, i + 2, 10, i + 4, s)
    end
  end)

  -- 3. Path Dirt (Warm Kanto pathway)
  drawTile("PATH_DIRT", function(s)
    love.graphics.setColor(224/255, 200/255, 136/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(240/255, 224/255, 168/255, 1)
    love.graphics.points(6, 6, 22, 10, 12, 24, 26, 26, 8, 16)
    love.graphics.setColor(192/255, 160/255, 96/255, 1)
    love.graphics.points(7, 7, 23, 11, 13, 25, 27, 27)
  end)

  -- 4. Path Stone / Cobblestone
  drawTile("PATH_STONE", function(s)
    love.graphics.setColor(168/255, 176/255, 184/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(128/255, 136/255, 144/255, 1)
    love.graphics.rectangle("line", 2, 2, 12, 12)
    love.graphics.rectangle("line", 16, 2, 14, 12)
    love.graphics.rectangle("line", 2, 16, 14, 14)
    love.graphics.rectangle("line", 18, 16, 12, 14)
  end)

  -- 5. Water (Cyan Blue with wave crests)
  drawTile("WATER", function(s)
    love.graphics.setColor(48/255, 128/255, 224/255, 0.92)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(96/255, 184/255, 255/255, 0.95)
    love.graphics.line(4, 8, 14, 8)
    love.graphics.line(18, 16, 28, 16)
    love.graphics.line(6, 24, 16, 24)
    love.graphics.setColor(200/255, 240/255, 255/255, 0.8)
    love.graphics.points(6, 7, 20, 15, 8, 23)
  end)

  -- 6. Cliff Top
  drawTile("CLIFF_TOP", function(s)
    love.graphics.setColor(184/255, 136/255, 88/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(104/255, 192/255, 80/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, 6) -- grass ridge on top
    love.graphics.setColor(144/255, 96/255, 48/255, 1)
    love.graphics.line(0, 6, s, 6)
  end)

  -- 7. Cliff Side / Wall
  drawTile("CLIFF_SIDE", function(s)
    love.graphics.setColor(160/255, 112/255, 64/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(128/255, 80/255, 40/255, 1)
    for x = 0, s, 8 do
      love.graphics.line(x, 0, x, s)
    end
  end)

  -- 8. Foliage (Tree canopy)
  drawTile("FOLIAGE", function(s)
    love.graphics.setColor(48/255, 144/255, 56/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(80/255, 192/255, 80/255, 1)
    love.graphics.circle("fill", 10, 10, 8)
    love.graphics.circle("fill", 22, 10, 8)
    love.graphics.circle("fill", 16, 20, 9)
    love.graphics.setColor(32/255, 104/255, 40/255, 1)
    love.graphics.circle("line", 10, 10, 8)
    love.graphics.circle("line", 22, 10, 8)
    love.graphics.circle("line", 16, 20, 9)
  end)

  -- 9. Foliage Top (Tree dome highlight)
  drawTile("FOLIAGE_TOP", function(s)
    love.graphics.setColor(80/255, 192/255, 80/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(120/255, 232/255, 112/255, 1)
    love.graphics.circle("fill", s / 2, s / 2, 12)
    love.graphics.setColor(48/255, 144/255, 56/255, 1)
    love.graphics.circle("line", s / 2, s / 2, 12)
  end)

  -- 10. Wood Bark (Tree Trunk)
  drawTile("WOOD_BARK", function(s)
    love.graphics.setColor(120/255, 80/255, 40/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(80/255, 48/255, 24/255, 1)
    love.graphics.line(6, 0, 6, s)
    love.graphics.line(16, 0, 16, s)
    love.graphics.line(26, 0, 26, s)
  end)

  -- 11. Wall White (House siding)
  drawTile("WALL_WHITE", function(s)
    love.graphics.setColor(232/255, 236/255, 240/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(200/255, 208/255, 216/255, 1)
    for y = 0, s, 8 do
      love.graphics.line(0, y, s, y)
    end
    love.graphics.setColor(136/255, 88/255, 56/255, 1)
    love.graphics.rectangle("fill", 0, s - 6, s, 6) -- bottom baseboard
  end)

  -- 12. Wall Brick (Lab / Gym exterior)
  drawTile("WALL_BRICK", function(s)
    love.graphics.setColor(184/255, 80/255, 64/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(220/255, 210/255, 200/255, 1)
    for y = 0, s, 6 do love.graphics.line(0, y, s, y) end
    for y = 0, s, 12 do
      for x = 0, s, 12 do love.graphics.line(x, y, x, y + 6) end
    end
    for y = 6, s, 12 do
      for x = 6, s, 12 do love.graphics.line(x, y, x, y + 6) end
    end
  end)

  -- 13. Roof Red (Ash's House Roof)
  drawTile("ROOF_RED", function(s)
    love.graphics.setColor(216/255, 56/255, 48/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(248/255, 112/255, 96/255, 1)
    for y = 0, s, 6 do
      love.graphics.line(0, y, s, y)
    end
    love.graphics.setColor(144/255, 32/255, 24/255, 1)
    for y = 5, s, 6 do
      love.graphics.line(0, y, s, y)
    end
  end)

  -- 14. Roof Blue (Rival Gary's House Roof)
  drawTile("ROOF_BLUE", function(s)
    love.graphics.setColor(48/255, 96/255, 192/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(96/255, 160/255, 240/255, 1)
    for y = 0, s, 6 do love.graphics.line(0, y, s, y) end
    love.graphics.setColor(24/255, 48/255, 120/255, 1)
    for y = 5, s, 6 do love.graphics.line(0, y, s, y) end
  end)

  -- 15. Door
  drawTile("DOOR", function(s)
    love.graphics.setColor(136/255, 88/255, 56/255, 1)
    love.graphics.rectangle("fill", 4, 2, s - 8, s - 2)
    love.graphics.setColor(88/255, 48/255, 24/255, 1)
    love.graphics.rectangle("line", 4, 2, s - 8, s - 2)
    love.graphics.rectangle("line", 8, 6, s - 16, s - 12)
    love.graphics.setColor(240/255, 200/255, 48/255, 1)
    love.graphics.circle("fill", s - 10, s / 2, 2) -- golden doorknob
  end)

  -- 16. Window
  drawTile("WINDOW", function(s)
    love.graphics.setColor(232/255, 236/255, 240/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(112/255, 184/255, 240/255, 1)
    love.graphics.rectangle("fill", 4, 4, s - 8, s - 8)
    love.graphics.setColor(255/255, 255/255, 255/255, 0.7)
    love.graphics.line(6, 6, 14, 14) -- glass sheen
    love.graphics.setColor(80/255, 48/255, 24/255, 1)
    love.graphics.rectangle("line", 4, 4, s - 8, s - 8)
    love.graphics.line(s / 2, 4, s / 2, s - 4)
    love.graphics.line(4, s / 2, s - 4, s / 2)
  end)

  -- 17. Fence White
  drawTile("FENCE_WHITE", function(s)
    love.graphics.setColor(248/255, 248/255, 252/255, 1)
    for x = 2, s - 6, 8 do
      love.graphics.polygon("fill", x + 3, 2, x + 6, 6, x + 6, s, x, s, x, 6)
    end
    love.graphics.rectangle("fill", 0, 10, s, 4)
    love.graphics.rectangle("fill", 0, 22, s, 4)
    love.graphics.setColor(184/255, 192/255, 204/255, 1)
    love.graphics.line(0, 14, s, 14)
    love.graphics.line(0, 26, s, 26)
  end)

  -- 18. Sign Wood
  drawTile("SIGN_WOOD", function(s)
    love.graphics.setColor(184/255, 128/255, 72/255, 1)
    love.graphics.rectangle("fill", 2, 4, s - 4, 18)
    love.graphics.setColor(120/255, 72/255, 32/255, 1)
    love.graphics.rectangle("line", 2, 4, s - 4, 18)
    love.graphics.rectangle("fill", s / 2 - 2, 22, 4, 10) -- wooden post
  end)

  -- 19. Red Flowers
  drawTile("FLOWER_RED", function(s)
    love.graphics.setColor(88/255, 184/255, 72/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(232/255, 48/255, 48/255, 1)
    love.graphics.circle("fill", 8, 8, 4)
    love.graphics.circle("fill", 24, 14, 4)
    love.graphics.circle("fill", 12, 24, 4)
    love.graphics.setColor(248/255, 224/255, 48/255, 1)
    love.graphics.points(8, 8, 24, 14, 12, 24)
  end)

  -- 20. Yellow Flowers
  drawTile("FLOWER_YELLOW", function(s)
    love.graphics.setColor(88/255, 184/255, 72/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(248/255, 216/255, 32/255, 1)
    love.graphics.circle("fill", 14, 8, 4)
    love.graphics.circle("fill", 8, 20, 4)
    love.graphics.circle("fill", 24, 22, 4)
    love.graphics.setColor(216/255, 96/255, 24/255, 1)
    love.graphics.points(14, 8, 8, 20, 24, 22)
  end)

  -- 21. Sand
  drawTile("SAND", function(s)
    love.graphics.setColor(236/255, 216/255, 156/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(216/255, 188/255, 128/255, 1)
    love.graphics.points(4, 10, 16, 4, 22, 18, 10, 26)
  end)

  -- 22. Wooden Bridge
  drawTile("BRIDGE_WOOD", function(s)
    love.graphics.setColor(160/255, 104/255, 56/255, 1)
    love.graphics.rectangle("fill", 0, 0, s, s)
    love.graphics.setColor(112/255, 64/255, 32/255, 1)
    for y = 0, s, 6 do love.graphics.line(0, y, s, y) end
  end)

  -- 23. Shadow (radial soft black)
  drawTile("SHADOW", function(s)
    for r = s / 2, 2, -2 do
      local alpha = (1 - (r / (s / 2))) * 0.45
      love.graphics.setColor(0, 0, 0, alpha)
      love.graphics.circle("fill", s / 2, s / 2, r)
    end
  end)

  love.graphics.setCanvas()
  love.graphics.pop()

  -- Crisp pixel-art filtering
  canvas:setFilter("nearest", "nearest")
  TextureAtlas.canvas = canvas
  return canvas
end

function TextureAtlas.getCanvas()
  if not TextureAtlas.canvas then
    TextureAtlas.generate()
  end
  return TextureAtlas.canvas
end

return TextureAtlas
