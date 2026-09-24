local Vec3 = require("src.math3d.Vec3")

local Environment = {}
Environment.__index = Environment

function Environment.new()
  local env = {
    timeOfDay = 12.0,      -- 0.0 to 24.0 (12.0 = noon)
    timeSpeed = 0.25,      -- 1 game hour every 4 real seconds (adjustable)
    isPaused = false,
    sunDir = { -0.4, -1.0, -0.5 },
    sunColor = { 1.0, 0.95, 0.85 },
    ambientColor = { 0.40, 0.45, 0.55 },
    skyColor = { 0.45, 0.65, 0.92 },
    fogColor = { 0.50, 0.70, 0.90 },
    fogNear = 18.0,
    fogFar = 70.0,
    particles = {},
    maxParticles = 60
  }
  setmetatable(env, Environment)
  env:initParticles()
  return env
end

function Environment:initParticles()
  self.particles = {}
  for i = 1, self.maxParticles do
    table.insert(self.particles, {
      x = (math.random() - 0.5) * 40,
      y = math.random() * 8 + 0.5,
      z = (math.random() - 0.5) * 40,
      vy = -0.4 - math.random() * 0.4,
      vx = (math.random() - 0.5) * 0.3,
      vz = (math.random() - 0.5) * 0.3,
      size = math.random() * 3 + 2,
      phase = math.random() * 6.28,
      kind = (math.random() > 0.5) and "leaf" or "mote"
    })
  end
end

function Environment:setTime(hour)
  self.timeOfDay = (hour % 24.0)
end

function Environment:update(dt, playerPos)
  if not self.isPaused then
    self.timeOfDay = (self.timeOfDay + dt * self.timeSpeed) % 24.0
  end

  local t = self.timeOfDay

  -- Sun rotation across the sky (sunrise at 6:00, noon at 12:00, sunset at 18:00)
  local sunAngle = ((t - 6.0) / 12.0) * math.pi
  local sunY = -math.sin(sunAngle)
  local sunX = -math.cos(sunAngle) * 0.7
  local sunZ = -0.5
  self.sunDir = { sunX, math.min(-0.25, sunY), sunZ }

  -- Color Palettes by Time of Day
  if t >= 6.0 and t < 8.5 then
    -- Sunrise / Dawn
    local f = (t - 6.0) / 2.5
    self.sunColor = { 1.0, 0.75 + f * 0.20, 0.50 + f * 0.35 }
    self.ambientColor = { 0.35 + f * 0.10, 0.32 + f * 0.12, 0.40 + f * 0.15 }
    self.skyColor = { 0.85 - f * 0.35, 0.55 + f * 0.15, 0.45 + f * 0.45 }
    self.fogColor = { 0.85 - f * 0.35, 0.58 + f * 0.12, 0.55 + f * 0.35 }
  elseif t >= 8.5 and t < 16.5 then
    -- Midday / Full Sun
    self.sunColor = { 1.0, 0.98, 0.90 }
    self.ambientColor = { 0.45, 0.48, 0.55 }
    self.skyColor = { 0.42, 0.68, 0.95 }
    self.fogColor = { 0.52, 0.72, 0.92 }
  elseif t >= 16.5 and t < 19.5 then
    -- Golden Hour & Sunset
    local f = (t - 16.5) / 3.0
    self.sunColor = { 1.0, 0.90 - f * 0.45, 0.80 - f * 0.60 }
    self.ambientColor = { 0.45 - f * 0.18, 0.40 - f * 0.16, 0.48 - f * 0.12 }
    self.skyColor = { 0.42 + f * 0.45, 0.68 - f * 0.30, 0.95 - f * 0.60 }
    self.fogColor = { 0.55 + f * 0.30, 0.65 - f * 0.25, 0.85 - f * 0.50 }
  else
    -- Night / Moonlit
    self.sunColor = { 0.25, 0.35, 0.65 }     -- cool moonlight
    self.ambientColor = { 0.18, 0.22, 0.35 }
    self.skyColor = { 0.08, 0.10, 0.18 }
    self.fogColor = { 0.10, 0.12, 0.22 }
  end

  -- Update ambient particles around player
  local px = playerPos and playerPos.x or 0
  local pz = playerPos and playerPos.z or 0

  for _, p in ipairs(self.particles) do
    p.y = p.y + p.vy * dt
    p.x = p.x + p.vx * dt + math.sin(p.phase + love.timer.getTime() * 2) * 0.015
    p.z = p.z + p.vz * dt

    -- Respawn when touching ground or too far from player
    if p.y <= 0.1 or math.abs(p.x - px) > 25 or math.abs(p.z - pz) > 25 then
      p.x = px + (math.random() - 0.5) * 45
      p.y = math.random() * 8 + 3.0
      p.z = pz + (math.random() - 0.5) * 45
    end
  end
end

function Environment:drawSky(ww, wh)
  -- Gradient horizon sky
  local topCol = { self.skyColor[1] * 0.7, self.skyColor[2] * 0.7, self.skyColor[3] * 0.8 }
  local botCol = self.fogColor

  for y = 0, wh, 8 do
    local f = y / wh
    local r = topCol[1] * (1 - f) + botCol[1] * f
    local g = topCol[2] * (1 - f) + botCol[2] * f
    local b = topCol[3] * (1 - f) + botCol[3] * f
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", 0, y, ww, 8)
  end
end

function Environment:drawParticles()
  local isNight = (self.timeOfDay >= 19.5 or self.timeOfDay < 6.0)
  for _, p in ipairs(self.particles) do
    if isNight then
      -- Fireflies glowing at night
      local glow = (math.sin(p.phase + love.timer.getTime() * 4) + 1) * 0.5
      love.graphics.setColor(1.0, 0.95, 0.4, glow * 0.85)
      love.graphics.circle("fill", p.x, p.y, p.size * 0.8)
    else
      -- Fluttering green/amber leaves
      love.graphics.setColor(110/255, 195/255, 65/255, 0.75)
      love.graphics.circle("fill", p.x, p.y, p.size)
    end
  end
end

function Environment:getTimeString()
  local totalMinutes = math.floor(self.timeOfDay * 60)
  local hours = math.floor(totalMinutes / 60) % 24
  local mins = totalMinutes % 60
  local period = (hours >= 6 and hours < 18) and "☀️ DIA" or "🌙 NOITE"
  if hours >= 17 and hours < 19 then period = "🌅 ENTARDECER" end
  return string.format("%02d:%02d (%s)", hours, mins, period)
end

return Environment
