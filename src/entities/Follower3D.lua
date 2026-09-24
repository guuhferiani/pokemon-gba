local Vec3 = require("src.math3d.Vec3")
local Mat4 = require("src.math3d.Mat4")
local MeshBuilder = require("src.render.MeshBuilder")

local Follower3D = {}
Follower3D.__index = Follower3D

function Follower3D.new(player)
  local f = {
    species = "Pikachu",
    pos = Vec3.new(player.pos.x, 0, player.pos.z + 1.2),
    facing = 1,
    hopY = 0,
    hopTimer = 0,
    animFrame = 1,
    spriteCanvas = nil,
    mesh = nil
  }
  setmetatable(f, Follower3D)
  f:initSprite()
  f:buildMesh()
  return f
end

function Follower3D:initSprite()
  local s = 28
  local canvas = love.graphics.newCanvas(s * 4, s * 4)
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)

  local function drawPikachu(dir, frame, ox, oy)
    love.graphics.push()
    love.graphics.translate(ox, oy)

    local yellow = { 248/255, 216/255, 48/255 }
    local darkYellow = { 216/255, 176/255, 24/255 }
    local redCheeks = { 232/255, 48/255, 48/255 }
    local brownStripes = { 136/255, 80/255, 32/255 }
    local black = { 32/255, 28/255, 32/255 }

    local hop = (frame % 2 == 1) and 1 or 0

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", 14, 26, 6, 2)

    -- Ears
    love.graphics.setColor(yellow)
    love.graphics.polygon("fill", 8, 12 - hop, 5, 2 - hop, 10, 10 - hop)
    love.graphics.polygon("fill", 20, 12 - hop, 23, 2 - hop, 18, 10 - hop)
    love.graphics.setColor(black)
    love.graphics.polygon("fill", 6, 5 - hop, 5, 2 - hop, 8, 6 - hop)
    love.graphics.polygon("fill", 22, 5 - hop, 23, 2 - hop, 20, 6 - hop)

    -- Body & Head
    love.graphics.setColor(yellow)
    love.graphics.circle("fill", 14, 18 - hop, 7) -- body
    love.graphics.circle("fill", 14, 12 - hop, 6) -- head

    -- Tail (Lightning bolt)
    love.graphics.setColor(darkYellow)
    love.graphics.polygon("fill", 6, 20 - hop, 2, 14 - hop, 4, 14 - hop, 1, 9 - hop, 5, 12 - hop)

    -- Cheeks & Eyes
    if dir == 1 or dir == 3 or dir == 4 then
      love.graphics.setColor(redCheeks)
      love.graphics.circle("fill", 10, 14 - hop, 2)
      love.graphics.circle("fill", 18, 14 - hop, 2)

      love.graphics.setColor(black)
      love.graphics.points(11, 11 - hop, 17, 11 - hop)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.points(11, 11 - hop)
    elseif dir == 2 then
      -- Back stripes
      love.graphics.setColor(brownStripes)
      love.graphics.rectangle("fill", 10, 16 - hop, 8, 2)
      love.graphics.rectangle("fill", 11, 20 - hop, 6, 2)
    end

    love.graphics.pop()
  end

  for d = 1, 4 do
    for fr = 1, 4 do
      drawPikachu(d, fr, (fr - 1) * s, (d - 1) * s)
    end
  end

  love.graphics.setCanvas()
  love.graphics.pop()
  canvas:setFilter("nearest", "nearest")
  self.spriteCanvas = canvas
end

function Follower3D:buildMesh()
  local s = 1.0 / 4.0
  local u1, v1 = 0, 0
  local u2, v2 = s, s

  local w = 0.9
  local h = 0.9
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

function Follower3D:update(dt, player)
  -- Follow player breadcrumbs (trails behind ~12-16 frames)
  local target = nil
  if #player.breadcrumbs >= 12 then
    target = player.breadcrumbs[12]
  end

  if target then
    local tx, tz = target.x, target.z
    local dx = tx - self.pos.x
    local dz = tz - self.pos.z
    local dist = math.sqrt(dx * dx + dz * dz)

    if dist > 0.1 then
      local spd = math.min(12.0, dist * 6.0)
      self.pos.x = self.pos.x + (dx / dist) * spd * dt
      self.pos.z = self.pos.z + (dz / dist) * spd * dt
      self.facing = target.facing or 1

      self.hopTimer = self.hopTimer + dt * 10
      self.animFrame = (math.floor(self.hopTimer) % 4) + 1
      self.hopY = math.abs(math.sin(self.hopTimer * 2)) * 0.18
    else
      self.hopY = 0
      self.animFrame = 1
    end
  else
    self.hopY = 0
  end

  -- Update UVs in mesh
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

function Follower3D:draw(shaderInstance, camYaw)
  local modelMat = Mat4.translation(self.pos.x, self.pos.y + self.hopY, self.pos.z)
  if camYaw then
    modelMat = modelMat:multiply(Mat4.rotationY(camYaw))
  end

  shaderInstance:setModel(modelMat)
  shaderInstance:setFlags(false, false, true)
  love.graphics.draw(self.mesh)
  shaderInstance:setFlags(false, false, false)
end

return Follower3D
