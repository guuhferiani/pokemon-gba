local MeshBuilder = require("src.render.MeshBuilder")
local TextureAtlas = require("src.render.TextureAtlas")
local Mat4 = require("src.math3d.Mat4")

local Map3D = {}
Map3D.__index = Map3D

function Map3D.new()
  local map = {
    name = "Pallet Town & Rota 1",
    subtitle = "O início da sua jornada inesquecível",
    width = 32,
    height = 36,
    collision = {},      -- 2D grid: 0 = passable, 1 = solid, 2 = ledge jump south, 3 = grass
    elevation = {},      -- 2D grid: height Y (0, 1, 2)
    terrainMesh = nil,
    buildingsMesh = nil,
    foliageMesh = nil,
    waterMesh = nil,
    propsMesh = nil,
    modelMatrix = Mat4.identity()
  }
  setmetatable(map, Map3D)
  map:generatePalletTown()
  map:buildMeshes()
  return map
end

function Map3D:getTile(grid, x, z)
  local row = grid[z]
  if not row then return nil end
  return row[x]
end

function Map3D:setTile(grid, x, z, val)
  if not grid[z] then grid[z] = {} end
  grid[z][x] = val
end

function Map3D:isSolid(wx, wz)
  local tx = math.floor(wx + 0.5)
  local tz = math.floor(wz + 0.5)
  if tx < 0 or tx >= self.width or tz < 0 or tz >= self.height then
    return true
  end
  local col = self:getTile(self.collision, tx, tz) or 0
  return (col == 1)
end

function Map3D:isGrass(wx, wz)
  local tx = math.floor(wx + 0.5)
  local tz = math.floor(wz + 0.5)
  local col = self:getTile(self.collision, tx, tz) or 0
  return (col == 3)
end

function Map3D:isWater(wx, wz)
  local tx = math.floor(wx + 0.5)
  local tz = math.floor(wz + 0.5)
  local col = self:getTile(self.collision, tx, tz) or 0
  return (col == 4)
end

function Map3D:getElevation(wx, wz)
  local tx = math.floor(wx + 0.5)
  local tz = math.floor(wz + 0.5)
  return self:getTile(self.elevation, tx, tz) or 0
end

function Map3D:generatePalletTown()
  -- Initialize grids
  for z = 0, self.height - 1 do
    for x = 0, self.width - 1 do
      self:setTile(self.collision, x, z, 0)
      self:setTile(self.elevation, x, z, 0)
    end
  end

  -- Border Tree Walls (Solid)
  for x = 0, self.width - 1 do
    self:setTile(self.collision, x, 0, 1)
    self:setTile(self.collision, x, self.height - 1, 1)
  end
  for z = 0, self.height - 1 do
    self:setTile(self.collision, 0, z, 1)
    self:setTile(self.collision, 1, z, 1)
    self:setTile(self.collision, self.width - 2, z, 1)
    self:setTile(self.collision, self.width - 1, z, 1)
  end

  -- Ash's House (x: 5..10, z: 6..10)
  for z = 6, 10 do
    for x = 5, 10 do
      self:setTile(self.collision, x, z, 1)
    end
  end
  self:setTile(self.collision, 7, 10, 0) -- Door entrance

  -- Gary's House (x: 18..23, z: 6..10)
  for z = 6, 10 do
    for x = 18, 23 do
      self:setTile(self.collision, x, z, 1)
    end
  end
  self:setTile(self.collision, 20, 10, 0) -- Door entrance

  -- Prof. Oak's Lab (x: 15..25, z: 16..22)
  for z = 16, 22 do
    for x = 15, 25 do
      self:setTile(self.collision, x, z, 1)
    end
  end
  self:setTile(self.collision, 18, 22, 0) -- Lab Door entrance

  -- Water Lake (x: 3..11, z: 24..33)
  for z = 24, 33 do
    for x = 3, 11 do
      self:setTile(self.collision, x, z, 4) -- 4 = water
    end
  end

  -- Route 1 Tall Grass patches (z: 1..5, x: 8..12 and 16..20)
  for z = 1, 4 do
    for x = 6, 10 do
      self:setTile(self.collision, x, z, 3) -- 3 = tall grass
    end
    for x = 18, 22 do
      self:setTile(self.collision, x, z, 3)
    end
  end

  -- Picket Fences
  for x = 4, 11 do self:setTile(self.collision, x, 12, 1) end
  self:setTile(self.collision, 7, 12, 0) -- Fence Gate Ash
  for x = 17, 24 do self:setTile(self.collision, x, 12, 1) end
  self:setTile(self.collision, 20, 12, 0) -- Fence Gate Gary
end

function Map3D:buildMeshes()
  local mbTerrain = MeshBuilder.new()
  local mbBuildings = MeshBuilder.new()
  local mbFoliage = MeshBuilder.new()
  local mbWater = MeshBuilder.new()
  local mbProps = MeshBuilder.new()

  local uvGrass = TextureAtlas.getUV("GRASS")
  local uvTallGrass = TextureAtlas.getUV("TALL_GRASS")
  local uvPath = TextureAtlas.getUV("PATH_DIRT")
  local uvStonePath = TextureAtlas.getUV("PATH_STONE")
  local uvWater = TextureAtlas.getUV("WATER")
  local uvFoliage = TextureAtlas.getUV("FOLIAGE")
  local uvFoliageTop = TextureAtlas.getUV("FOLIAGE_TOP")
  local uvWood = TextureAtlas.getUV("WOOD_BARK")
  local uvWallWhite = TextureAtlas.getUV("WALL_WHITE")
  local uvWallBrick = TextureAtlas.getUV("WALL_BRICK")
  local uvRoofRed = TextureAtlas.getUV("ROOF_RED")
  local uvRoofBlue = TextureAtlas.getUV("ROOF_BLUE")
  local uvDoor = TextureAtlas.getUV("DOOR")
  local uvWindow = TextureAtlas.getUV("WINDOW")
  local uvFence = TextureAtlas.getUV("FENCE_WHITE")
  local uvSign = TextureAtlas.getUV("SIGN_WOOD")
  local uvFlowerRed = TextureAtlas.getUV("FLOWER_RED")
  local uvFlowerYel = TextureAtlas.getUV("FLOWER_YELLOW")
  local uvSand = TextureAtlas.getUV("SAND")
  local uvBridge = TextureAtlas.getUV("BRIDGE_WOOD")

  -- 1. BUILD TERRAIN (Ground, Paths, Shore, Flowers)
  for z = 0, self.height - 1 do
    for x = 0, self.width - 1 do
      local col = self:getTile(self.collision, x, z) or 0
      local x1, x2 = x, x + 1
      local z1, z2 = z, z + 1
      local y0 = 0.0

      if col == 4 then
        -- Water Lake
        mbWater:addQuad(
          { x1, -0.15, z2 }, { x2, -0.15, z2 }, { x2, -0.15, z1 }, { x1, -0.15, z1 },
          uvWater, { 0, 1, 0 }
        )
        -- Sand shore around water
        if x == 11 or z == 24 then
          mbTerrain:addQuad(
            { x1, y0, z2 }, { x2, y0, z2 }, { x2, y0, z1 }, { x1, y0, z1 },
            uvSand, { 0, 1, 0 }
          )
        end
      else
        -- Determine ground texture
        local uv = uvGrass
        -- Main paths connecting houses and exits
        local isMainPath = (x >= 12 and x <= 15 and z >= 4 and z <= 24)
          or (z >= 10 and z <= 12 and x >= 6 and x <= 22)
          or (x >= 16 and x <= 20 and z >= 21 and z <= 24)

        if isMainPath then
          uv = uvPath
        elseif col == 3 then
          uv = uvTallGrass
        elseif (x == 4 or x == 11) and (z == 7 or z == 9) then
          uv = uvFlowerRed
        elseif (x == 17 or x == 24) and (z == 7 or z == 9) then
          uv = uvFlowerYel
        end

        mbTerrain:addQuad(
          { x1, y0, z2 }, { x2, y0, z2 }, { x2, y0, z1 }, { x1, y0, z1 },
          uv, { 0, 1, 0 }
        )
      end
    end
  end

  -- 2. BUILD HOUSES (Ash's House, Gary's House, Oak's Lab)
  -- Helper to build standard house
  local function buildHouse(x, z, w, d, h, roofH, uvWall, uvRoof, title)
    -- Walls
    mbBuildings:addCube(x, 0, z, x + w, h, z + d, uvWall, uvWall, uvWall)
    -- Roof
    mbBuildings:addGableRoof(x - 0.4, h, z - 0.4, x + w + 0.4, h + roofH, z + d + 0.4, uvRoof, uvWall)
    -- Front Door
    local doorW = 1.2
    local doorX = x + (w - doorW) / 2
    mbBuildings:addCube(doorX, 0, z + d - 0.05, doorX + doorW, 1.8, z + d + 0.08, uvDoor, uvDoor, uvDoor)
    -- Windows
    mbBuildings:addCube(x + 0.8, 1.2, z + d + 0.02, x + 1.8, 2.2, z + d + 0.05, uvWindow, uvWindow, uvWindow)
    if w >= 6 then
      mbBuildings:addCube(x + w - 1.8, 1.2, z + d + 0.02, x + w - 0.8, 2.2, z + d + 0.05, uvWindow, uvWindow, uvWindow)
    end
    -- Brick Chimney
    local chimX = x + 0.8
    local chimZ = z + 0.8
    mbBuildings:addCube(chimX, h + roofH * 0.4, chimZ, chimX + 0.8, h + roofH + 0.6, chimZ + 0.8, uvWallBrick, uvWallBrick, uvWallBrick)
  end

  -- Ash's House (Casa do Red)
  buildHouse(5, 6, 5, 4, 2.4, 1.6, uvWallWhite, uvRoofRed, "Red's House")
  -- Gary's House (Casa do Gary)
  buildHouse(18, 6, 5, 4, 2.4, 1.6, uvWallWhite, uvRoofBlue, "Blue's House")
  -- Prof. Oak's Lab (Laboratório Pokémon)
  buildHouse(15, 16, 9, 6, 3.2, 1.8, uvWallBrick, uvRoofRed, "Oak's Pokémon Lab")
  -- Lab Entrance Sign
  mbProps:addCube(17.5, 0, 22.8, 18.5, 1.2, 23.0, uvSign, uvSign, uvSign)

  -- 3. BUILD TREES (Border Walls & Town Decor)
  local function buildTree(cx, cz)
    -- Trunk
    mbFoliage:addCube(cx + 0.35, 0, cz + 0.35, cx + 0.65, 1.2, cz + 0.65, uvWood, uvWood, uvWood)
    -- Lower Canopy Block
    mbFoliage:addCube(cx, 1.0, cz, cx + 1.0, 2.4, cz + 1.0, uvFoliageTop, uvFoliage, uvFoliage)
    -- Upper Canopy Dome
    mbFoliage:addCube(cx + 0.15, 2.3, cz + 0.15, cx + 0.85, 3.2, cz + 0.85, uvFoliageTop, uvFoliage, uvFoliage)
  end

  -- Dense Forest Perimeter
  for z = 0, self.height - 1 do
    buildTree(0, z)
    buildTree(1, z)
    buildTree(self.width - 2, z)
    buildTree(self.width - 1, z)
  end
  for x = 2, self.width - 3 do
    if not (x >= 12 and x <= 15) then -- Gap for Route 1 north exit
      buildTree(x, 0)
    end
    buildTree(x, self.height - 1)
  end

  -- Standalone town trees
  local townTrees = {
    { 3, 4 }, { 11, 4 }, { 16, 4 }, { 24, 4 },
    { 3, 14 }, { 12, 14 }, { 26, 14 },
    { 12, 20 }, { 26, 20 }, { 13, 27 }, { 14, 30 }
  }
  for _, pt in ipairs(townTrees) do
    buildTree(pt[1], pt[2])
  end

  -- 4. BUILD FENCES & SIGNS
  for x = 4, 11 do
    if x ~= 7 then
      mbProps:addCube(x, 0, 11.9, x + 1, 0.7, 12.1, uvFence, uvFence, uvFence)
    end
  end
  for x = 17, 24 do
    if x ~= 20 then
      mbProps:addCube(x, 0, 11.9, x + 1, 0.7, 12.1, uvFence, uvFence, uvFence)
    end
  end
  -- Pallet Town Signpost
  mbProps:addCube(10, 0, 14.8, 10.8, 1.0, 15.0, uvSign, uvSign, uvSign)

  -- Wooden Pier at lake
  for z = 24, 28 do
    mbProps:addCube(7.5, 0, z, 9.5, 0.15, z + 1, uvBridge, uvWood, uvBridge)
  end

  -- Compile GPU Meshes
  self.terrainMesh = mbTerrain:buildMesh()
  self.buildingsMesh = mbBuildings:buildMesh()
  self.foliageMesh = mbFoliage:buildMesh()
  self.waterMesh = mbWater:buildMesh()
  self.propsMesh = mbProps:buildMesh()
end

function Map3D:draw(shaderInstance)
  shaderInstance:setModel(self.modelMatrix)

  -- 1. Draw Terrain & Roads
  shaderInstance:setFlags(false, false, false)
  if self.terrainMesh then love.graphics.draw(self.terrainMesh) end

  -- 2. Draw Props (Fences, Signs)
  if self.propsMesh then love.graphics.draw(self.propsMesh) end

  -- 3. Draw Buildings (Houses, Lab)
  if self.buildingsMesh then love.graphics.draw(self.buildingsMesh) end

  -- 4. Draw Trees & Foliage (with wind sway animation in vertex shader!)
  shaderInstance:setFlags(false, true, false)
  if self.foliageMesh then love.graphics.draw(self.foliageMesh) end

  -- 5. Draw Water Lake (with animated waves in vertex shader!)
  shaderInstance:setFlags(true, false, false)
  if self.waterMesh then love.graphics.draw(self.waterMesh) end

  shaderInstance:setFlags(false, false, false)
end

return Map3D
