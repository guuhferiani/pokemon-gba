local Vec3 = require("src.math3d.Vec3")
local Mat4 = require("src.math3d.Mat4")
local MeshBuilder = require("src.render.MeshBuilder")

local Player3D = {}
Player3D.__index = Player3D

Player3D.FACING = {
  DOWN  = 1,
  UP    = 2,
  LEFT  = 3,
  RIGHT = 4
}

function Player3D.new(startX, startZ)
  local p = {
    pos = Vec3.new(startX or 7.5, 0.0, startZ or 11.5),
    targetPos = Vec3.new(startX or 7.5, 0.0, startZ or 11.5),
    facing = Player3D.FACING.DOWN,
    walkSpeed = 4.2,
    runSpeed = 7.5,
    isRunning = false,
    isMoving = false,
    animTimer = 0.0,
    animFrame = 1,
    hopY = 0.0,
    breadcrumbs = {},
    mesh = nil,
    spriteCanvas = nil
  }
  setmetatable(p, Player3D)
  p:initSprite()
  p:buildMesh()
  return p
end

-- Generates 4-directional pixel art sprites for Red
function Player3D:initSprite()
  local s = 32
  local canvas = love.graphics.newCanvas(s * 4, s * 4) -- 4 directions x 4 animation frames
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)

  local function drawRedFrame(dir, frame, ox, oy)
    love.graphics.push()
    love.graphics.translate(ox, oy)

    local redHat = { 224/255, 48/255, 48/255 }
    local whiteVisor = { 248/255, 248/255, 252/255 }
    local blackHair = { 36/255, 28/255, 32/255 }
    local skin = { 248/255, 200/255, 160/255 }
    local redJacket = { 216/255, 40/255, 40/255 }
    local blueJeans = { 48/255, 80/255, 160/255 }
    local whiteShoes = { 240/255, 240/255, 240/255 }
    local blackBackpack = { 56/255, 72/255, 88/255 }

    local bobY = (frame % 2 == 1) and 1 or 0
    local legOffset = (frame == 2) and 2 or ((frame == 4) and -2 or 0)

    -- Shadow under feet
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", 16, 30, 8, 3)

    if dir == Player3D.FACING.DOWN then
      -- Facing Front (Down)
      -- Legs & Shoes
      love.graphics.setColor(blueJeans)
      love.graphics.rectangle("fill", 11 - legOffset, 22, 4, 6)
      love.graphics.rectangle("fill", 17 + legOffset, 22, 4, 6)
      love.graphics.setColor(whiteShoes)
      love.graphics.rectangle("fill", 10 - legOffset, 27, 5, 3)
      love.graphics.rectangle("fill", 17 + legOffset, 27, 5, 3)
      -- Jacket / Torso
      love.graphics.setColor(redJacket)
      love.graphics.rectangle("fill", 10, 14 + bobY, 12, 9, 2, 2)
      love.graphics.setColor(whiteVisor)
      love.graphics.rectangle("fill", 13, 15 + bobY, 6, 8) -- white undershirt
      -- Head & Face
      love.graphics.setColor(skin)
      love.graphics.rectangle("fill", 11, 7 + bobY, 10, 8, 2, 2)
      -- Eyes
      love.graphics.setColor(blackHair)
      love.graphics.points(13, 11 + bobY, 18, 11 + bobY)
      -- Red Cap
      love.graphics.setColor(redHat)
      love.graphics.rectangle("fill", 10, 4 + bobY, 12, 5, 2, 2)
      love.graphics.setColor(whiteVisor)
      love.graphics.rectangle("fill", 12, 3 + bobY, 8, 3) -- front patch
      love.graphics.rectangle("fill", 9, 8 + bobY, 14, 2) -- visor
    elseif dir == Player3D.FACING.UP then
      -- Facing Back (Up)
      love.graphics.setColor(blueJeans)
      love.graphics.rectangle("fill", 11 - legOffset, 22, 4, 6)
      love.graphics.rectangle("fill", 17 + legOffset, 22, 4, 6)
      love.graphics.setColor(whiteShoes)
      love.graphics.rectangle("fill", 11 - legOffset, 27, 4, 3)
      love.graphics.rectangle("fill", 17 + legOffset, 27, 4, 3)
      -- Backpack & Jacket
      love.graphics.setColor(blackBackpack)
      love.graphics.rectangle("fill", 10, 14 + bobY, 12, 9, 2, 2)
      love.graphics.setColor(240/255, 200/255, 48/255)
      love.graphics.rectangle("fill", 12, 17 + bobY, 8, 3)
      -- Hair & Cap back
      love.graphics.setColor(blackHair)
      love.graphics.rectangle("fill", 10, 9 + bobY, 12, 5)
      love.graphics.setColor(redHat)
      love.graphics.rectangle("fill", 10, 4 + bobY, 12, 6, 2, 2)
    else
      -- Facing Left or Right
      local isLeft = (dir == Player3D.FACING.LEFT)
      local flip = isLeft and -1 or 1
      love.graphics.scale(flip, 1)
      if isLeft then love.graphics.translate(-32, 0) end

      -- Legs
      love.graphics.setColor(blueJeans)
      love.graphics.rectangle("fill", 13 + legOffset, 22, 5, 6)
      love.graphics.setColor(whiteShoes)
      love.graphics.rectangle("fill", 14 + legOffset, 27, 6, 3)
      -- Jacket
      love.graphics.setColor(redJacket)
      love.graphics.rectangle("fill", 11, 14 + bobY, 10, 9, 2, 2)
      love.graphics.setColor(blackBackpack)
      love.graphics.rectangle("fill", 8, 15 + bobY, 4, 7)
      -- Face & Profile
      love.graphics.setColor(skin)
      love.graphics.rectangle("fill", 12, 7 + bobY, 8, 8)
      love.graphics.setColor(blackHair)
      love.graphics.points(17, 11 + bobY)
      -- Cap & Visor
      love.graphics.setColor(redHat)
      love.graphics.rectangle("fill", 10, 4 + bobY, 10, 5, 2, 2)
      love.graphics.setColor(whiteVisor)
      love.graphics.rectangle("fill", 17, 7 + bobY, 5, 2) -- visor jutting out
    end

    love.graphics.pop()
  end

  for d = 1, 4 do
    for f = 1, 4 do
      drawRedFrame(d, f, (f - 1) * s, (d - 1) * s)
    end
  end

  love.graphics.setCanvas()
  love.graphics.pop()
  canvas:setFilter("nearest", "nearest")
  self.spriteCanvas = canvas
end

function Player3D:buildMesh()
  local s = 1.0 / 4.0
  local u1 = (self.animFrame - 1) * s
  local v1 = (self.facing - 1) * s
  local u2 = u1 + s
  local v2 = v1 + s

  local w = 1.2
  local h = 1.5
  local halfW = w / 2

  local vertices = {
    { -halfW, 0, 0,  u1, v2,  255, 255, 255, 255,  0, 0, 1 },
    {  halfW, 0, 0,  u2, v2,  255, 255, 255, 255,  0, 0, 1 },
    {  halfW, h, 0,  u2, v1,  255, 255, 255, 255,  0, 0, 1 },

    { -halfW, 0, 0,  u1, v2,  255, 255, 255, 255,  0, 0, 1 },
    {  halfW, h, 0,  u2, v1,  255, 255, 255, 255,  0, 0, 1 },
    { -halfW, h, 0,  u1, v1,  255, 255, 255, 255,  0, 0, 1 }
  }

  local mesh = love.graphics.newMesh(MeshBuilder.VERTEX_FORMAT, vertices, "triangles", "dynamic")
  mesh:setTexture(self.spriteCanvas)
  self.mesh = mesh
end

function Player3D:update(dt, map)
  local dx, dz = 0, 0

  if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
    dz = dz - 1
    self.facing = Player3D.FACING.UP
  elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
    dz = dz + 1
    self.facing = Player3D.FACING.DOWN
  end

  if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
    dx = dx - 1
    self.facing = Player3D.FACING.LEFT
  elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
    dx = dx + 1
    self.facing = Player3D.FACING.RIGHT
  end

  self.isRunning = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") or love.keyboard.isDown("b")
  local speed = self.isRunning and self.runSpeed or self.walkSpeed

  self.isMoving = (dx ~= 0 or dz ~= 0)

  if self.isMoving then
    -- Normalize diagonal movement
    local len = math.sqrt(dx * dx + dz * dz)
    dx = (dx / len) * speed * dt
    dz = (dz / len) * speed * dt

    local nextX = self.pos.x + dx
    local nextZ = self.pos.z + dz

    -- Collision checks (with radius box)
    local r = 0.35
    local canMoveX = not map:isSolid(nextX - r, self.pos.z) and not map:isSolid(nextX + r, self.pos.z)
      and not map:isWater(nextX, self.pos.z)
    local canMoveZ = not map:isSolid(self.pos.x, nextZ - r) and not map:isSolid(self.pos.x, nextZ + r)
      and not map:isWater(self.pos.x, nextZ)

    if canMoveX then self.pos.x = nextX end
    if canMoveZ then self.pos.z = nextZ end

    -- Record breadcrumbs for Follower Pokémon
    table.insert(self.breadcrumbs, 1, { x = self.pos.x, z = self.pos.z, facing = self.facing })
    if #self.breadcrumbs > 35 then
      table.remove(self.breadcrumbs)
    end

    -- Animation frames cycle
    self.animTimer = self.animTimer + dt * (self.isRunning and 14.0 or 9.0)
    self.animFrame = (math.floor(self.animTimer) % 4) + 1
  else
    self.animFrame = 1
    self.animTimer = 0.0
  end

  -- Update UV coordinates in mesh
  local s = 1.0 / 4.0
  local u1 = (self.animFrame - 1) * s
  local v1 = (self.facing - 1) * s
  local u2 = u1 + s
  local v2 = v1 + s

  self.mesh:setVertexAttribute(1, 2, u1, v2)
  self.mesh:setVertexAttribute(2, 2, u2, v2)
  self.mesh:setVertexAttribute(3, 2, u2, v1)
  self.mesh:setVertexAttribute(4, 2, u1, v2)
  self.mesh:setVertexAttribute(5, 2, u2, v1)
  self.mesh:setVertexAttribute(6, 2, u1, v1)
end

function Player3D:draw(shaderInstance, camYaw)
  local modelMat = Mat4.translation(self.pos.x, self.pos.y, self.pos.z)
  -- Face billboard towards camera yaw
  if camYaw then
    modelMat = modelMat:multiply(Mat4.rotationY(camYaw))
  end

  shaderInstance:setModel(modelMat)
  shaderInstance:setFlags(false, false, true) -- unlit for crisp vibrant pixel art
  love.graphics.draw(self.mesh)
  shaderInstance:setFlags(false, false, false)
end

return Player3D
