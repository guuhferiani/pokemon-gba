local Vec3 = require("src.math3d.Vec3")
local Mat4 = require("src.math3d.Mat4")

local Camera3D = {}
Camera3D.__index = Camera3D

Camera3D.MODES = {
  ISOMETRIC    = "isometric",    -- 45° tilt modern perspective
  THIRD_PERSON = "third_person", -- Over the shoulder action RPG
  TOP_DOWN     = "top_down",     -- Classic GBA nostalgia with 3D depth
  FREE_ORBIT   = "free_orbit"    -- Full 360° mouse control
}

function Camera3D.new()
  local cam = {
    target = Vec3.new(0, 0, 0),
    currentPos = Vec3.new(0, 10, 15),
    mode = Camera3D.MODES.ISOMETRIC,
    yaw = 0.0,            -- in radians
    pitch = -0.68,        -- ~39 degrees down
    distance = 15.0,
    minDistance = 4.0,
    maxDistance = 40.0,
    fov = math.rad(50),
    aspect = 16 / 9,
    nearPlane = 0.1,
    farPlane = 120.0,
    smoothSpeed = 8.0,
    isDragging = false,
    lastMouseX = 0,
    lastMouseY = 0
  }
  setmetatable(cam, Camera3D)
  return cam
end

function Camera3D:setMode(mode)
  self.mode = mode
  if mode == Camera3D.MODES.ISOMETRIC then
    self.pitch = -0.65
    self.yaw = 0.0
    self.distance = 15.0
    self.fov = math.rad(48)
  elseif mode == Camera3D.MODES.THIRD_PERSON then
    self.pitch = -0.28
    self.distance = 7.5
    self.fov = math.rad(60)
  elseif mode == Camera3D.MODES.TOP_DOWN then
    self.pitch = -1.25 -- ~72 degrees down
    self.yaw = 0.0
    self.distance = 18.0
    self.fov = math.rad(40)
  elseif mode == Camera3D.MODES.FREE_ORBIT then
    self.fov = math.rad(55)
  end
end

function Camera3D:cycleMode()
  if self.mode == Camera3D.MODES.ISOMETRIC then
    self:setMode(Camera3D.MODES.THIRD_PERSON)
  elseif self.mode == Camera3D.MODES.THIRD_PERSON then
    self:setMode(Camera3D.MODES.TOP_DOWN)
  elseif self.mode == Camera3D.MODES.TOP_DOWN then
    self:setMode(Camera3D.MODES.FREE_ORBIT)
  else
    self:setMode(Camera3D.MODES.ISOMETRIC)
  end
  return self.mode
end

function Camera3D:update(dt, targetPos)
  -- Smoothly track target
  if targetPos then
    self.target = self.target:lerp(targetPos, math.min(1.0, dt * self.smoothSpeed))
  end

  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()
  self.aspect = ww / math.max(1, wh)

  -- Handle mouse dragging for free camera or orbit
  local mx, my = love.mouse.getPosition()
  if love.mouse.isDown(2) then -- Right mouse button
    if not self.isDragging then
      self.isDragging = true
      self.lastMouseX = mx
      self.lastMouseY = my
    else
      local dx = mx - self.lastMouseX
      local dy = my - self.lastMouseY
      self.yaw = self.yaw + dx * 0.008
      self.pitch = math.max(-1.45, math.min(-0.05, self.pitch - dy * 0.008))
      self.lastMouseX = mx
      self.lastMouseY = my
    end
  else
    self.isDragging = false
  end

  -- Calculate eye position from spherical coordinates
  local cy = math.cos(self.pitch)
  local sy = math.sin(self.pitch)
  local cx = math.sin(self.yaw)
  local cz = math.cos(self.yaw)

  local offsetX = cx * cy * self.distance
  local offsetY = -sy * self.distance
  local offsetZ = cz * cy * self.distance

  local desiredEye = Vec3.new(
    self.target.x + offsetX,
    self.target.y + offsetY,
    self.target.z + offsetZ
  )

  self.currentPos = self.currentPos:lerp(desiredEye, math.min(1.0, dt * 10.0))
end

function Camera3D:wheelmoved(x, y)
  self.distance = math.max(self.minDistance, math.min(self.maxDistance, self.distance - y * 1.5))
end

function Camera3D:getViewMatrix()
  local up = Vec3.new(0, 1, 0)
  return Mat4.lookAt(self.currentPos, self.target, up)
end

function Camera3D:getProjMatrix()
  return Mat4.perspective(self.fov, self.aspect, self.nearPlane, self.farPlane)
end

return Camera3D
