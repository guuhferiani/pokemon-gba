local Vec3 = require("src.math3d.Vec3")

local Mat4 = {}
Mat4.__index = Mat4

-- Creates a new 4x4 matrix (column-major order: 1..16)
function Mat4.new(elements)
  local m = elements or {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  }
  setmetatable(m, Mat4)
  return m
end

function Mat4.identity()
  return Mat4.new({
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  })
end

function Mat4:clone()
  local t = {}
  for i = 1, 16 do t[i] = self[i] end
  return Mat4.new(t)
end

function Mat4:multiply(b)
  local a = self
  local r = {}
  for row = 0, 3 do
    for col = 0, 3 do
      local sum = 0
      for k = 0, 3 do
        sum = sum + a[k * 4 + row + 1] * b[col * 4 + k + 1]
      end
      r[col * 4 + row + 1] = sum
    end
  end
  return Mat4.new(r)
end

function Mat4.translation(tx, ty, tz)
  return Mat4.new({
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    tx, ty, tz, 1
  })
end

function Mat4:translate(tx, ty, tz)
  return self:multiply(Mat4.translation(tx, ty, tz))
end

function Mat4.scaling(sx, sy, sz)
  return Mat4.new({
    sx, 0, 0, 0,
    0, sy, 0, 0,
    0, 0, sz, 0,
    0, 0, 0, 1
  })
end

function Mat4:scale(sx, sy, sz)
  return self:multiply(Mat4.scaling(sx, sy, sz))
end

function Mat4.rotationX(rad)
  local c, s = math.cos(rad), math.sin(rad)
  return Mat4.new({
    1, 0, 0, 0,
    0, c, s, 0,
    0, -s, c, 0,
    0, 0, 0, 1
  })
end

function Mat4.rotationY(rad)
  local c, s = math.cos(rad), math.sin(rad)
  return Mat4.new({
    c, 0, -s, 0,
    0, 1, 0, 0,
    s, 0, c, 0,
    0, 0, 0, 1
  })
end

function Mat4.rotationZ(rad)
  local c, s = math.cos(rad), math.sin(rad)
  return Mat4.new({
    c, s, 0, 0,
    -s, c, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  })
end

-- Perspective projection matrix
-- fov in radians, aspect = width / height, near / far planes
function Mat4.perspective(fov, aspect, near, far)
  local f = 1.0 / math.tan(fov / 2.0)
  local nf = 1.0 / (near - far)
  return Mat4.new({
    f / aspect, 0, 0, 0,
    0, f, 0, 0,
    0, 0, (far + near) * nf, -1,
    0, 0, (2.0 * far * near) * nf, 0
  })
end

-- Orthographic projection (for classic 2.5D / isometric view)
function Mat4.ortho(left, right, bottom, top, near, far)
  local lr = 1.0 / (left - right)
  local bt = 1.0 / (bottom - top)
  local nf = 1.0 / (near - far)
  return Mat4.new({
    -2.0 * lr, 0, 0, 0,
    0, -2.0 * bt, 0, 0,
    0, 0, 2.0 * nf, 0,
    (left + right) * lr, (top + bottom) * bt, (far + near) * nf, 1
  })
end

-- LookAt View matrix (eye, target, up vectors)
function Mat4.lookAt(eye, target, up)
  local zAxis = eye:sub(target):normalize()
  local xAxis = up:cross(zAxis):normalize()
  local yAxis = zAxis:cross(xAxis):normalize()

  local rot = Mat4.new({
    xAxis.x, yAxis.x, zAxis.x, 0,
    xAxis.y, yAxis.y, zAxis.y, 0,
    xAxis.z, yAxis.z, zAxis.z, 0,
    0, 0, 0, 1
  })

  local trans = Mat4.translation(-eye.x, -eye.y, -eye.z)
  return rot:multiply(trans)
end

return Mat4
