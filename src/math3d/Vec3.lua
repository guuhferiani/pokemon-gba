local Vec3 = {}
Vec3.__index = Vec3

function Vec3.new(x, y, z)
  local v = { x = x or 0, y = y or 0, z = z or 0 }
  setmetatable(v, Vec3)
  return v
end

function Vec3:set(x, y, z)
  self.x = x or 0
  self.y = y or 0
  self.z = z or 0
  return self
end

function Vec3:clone()
  return Vec3.new(self.x, self.y, self.z)
end

function Vec3:add(o)
  return Vec3.new(self.x + o.x, self.y + o.y, self.z + o.z)
end

function Vec3:sub(o)
  return Vec3.new(self.x - o.x, self.y - o.y, self.z - o.z)
end

function Vec3:mul(s)
  if type(s) == "number" then
    return Vec3.new(self.x * s, self.y * s, self.z * s)
  else
    return Vec3.new(self.x * s.x, self.y * s.y, self.z * s.z)
  end
end

function Vec3:div(s)
  return Vec3.new(self.x / s, self.y / s, self.z / s)
end

function Vec3:dot(o)
  return self.x * o.x + self.y * o.y + self.z * o.z
end

function Vec3:cross(o)
  return Vec3.new(
    self.y * o.z - self.z * o.y,
    self.z * o.x - self.x * o.z,
    self.x * o.y - self.y * o.x
  )
end

function Vec3:lengthSq()
  return self.x * self.x + self.y * self.y + self.z * self.z
end

function Vec3:length()
  return math.sqrt(self:lengthSq())
end

function Vec3:normalize()
  local len = self:length()
  if len > 0.00001 then
    return Vec3.new(self.x / len, self.y / len, self.z / len)
  end
  return Vec3.new(0, 0, 0)
end

function Vec3:lerp(target, t)
  return Vec3.new(
    self.x + (target.x - self.x) * t,
    self.y + (target.y - self.y) * t,
    self.z + (target.z - self.z) * t
  )
end

return Vec3
