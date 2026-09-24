local TextureAtlas = require("src.render.TextureAtlas")

local MeshBuilder = {}
MeshBuilder.__index = MeshBuilder

MeshBuilder.VERTEX_FORMAT = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
  { "VertexColor", "byte", 4 },
  { "VertexNormal", "float", 3 }
}

function MeshBuilder.new()
  local mb = {
    vertices = {}
  }
  setmetatable(mb, MeshBuilder)
  return mb
end

function MeshBuilder:clear()
  self.vertices = {}
end

-- Adds a single vertex to the list
function MeshBuilder:addVertex(x, y, z, u, v, nx, ny, nz, r, g, b, a)
  table.insert(self.vertices, {
    x, y, z,
    u, v,
    r or 255, g or 255, b or 255, a or 255,
    nx or 0, ny or 1, nz or 0
  })
end

-- Adds a 3D Quad (2 triangles, CCW winding order)
function MeshBuilder:addQuad(p1, p2, p3, p4, uv, norm, col)
  local u1, v1, u2, v2 = uv[1], uv[2], uv[3], uv[4]
  local nx, ny, nz = norm[1], norm[2], norm[3]
  local r, g, b, a = col and col[1] or 255, col and col[2] or 255, col and col[3] or 255, col and col[4] or 255

  -- Triangle 1: p1, p2, p3
  self:addVertex(p1[1], p1[2], p1[3], u1, v1, nx, ny, nz, r, g, b, a)
  self:addVertex(p2[1], p2[2], p2[3], u2, v1, nx, ny, nz, r, g, b, a)
  self:addVertex(p3[1], p3[2], p3[3], u2, v2, nx, ny, nz, r, g, b, a)

  -- Triangle 2: p1, p3, p4
  self:addVertex(p1[1], p1[2], p1[3], u1, v1, nx, ny, nz, r, g, b, a)
  self:addVertex(p3[1], p3[2], p3[3], u2, v2, nx, ny, nz, r, g, b, a)
  self:addVertex(p4[1], p4[2], p4[3], u1, v2, nx, ny, nz, r, g, b, a)
end

-- Adds a 3D Block / Cuboid (with independent top, side, and bottom UVs)
function MeshBuilder:addCube(x1, y1, z1, x2, y2, z2, uvTop, uvSide, uvBottom, col)
  uvTop = uvTop or TextureAtlas.getUV("GRASS")
  uvSide = uvSide or TextureAtlas.getUV("CLIFF_SIDE")
  uvBottom = uvBottom or uvTop

  -- Top face (+Y)
  self:addQuad(
    { x1, y2, z2 }, { x2, y2, z2 }, { x2, y2, z1 }, { x1, y2, z1 },
    uvTop, { 0, 1, 0 }, col
  )

  -- Bottom face (-Y)
  self:addQuad(
    { x1, y1, z1 }, { x2, y1, z1 }, { x2, y1, z2 }, { x1, y1, z2 },
    uvBottom, { 0, -1, 0 }, col
  )

  -- Front face (+Z)
  self:addQuad(
    { x1, y1, z2 }, { x2, y1, z2 }, { x2, y2, z2 }, { x1, y2, z2 },
    uvSide, { 0, 0, 1 }, col
  )

  -- Back face (-Z)
  self:addQuad(
    { x2, y1, z1 }, { x1, y1, z1 }, { x1, y2, z1 }, { x2, y2, z1 },
    uvSide, { 0, 0, -1 }, col
  )

  -- Left face (-X)
  self:addQuad(
    { x1, y1, z1 }, { x1, y1, z2 }, { x1, y2, z2 }, { x1, y2, z1 },
    uvSide, { -1, 0, 0 }, col
  )

  -- Right face (+X)
  self:addQuad(
    { x2, y1, z2 }, { x2, y1, z1 }, { x2, y2, z1 }, { x2, y2, z2 },
    uvSide, { 1, 0, 0 }, col
  )
end

-- Adds a sloped roof (Pitched / Gable roof)
function MeshBuilder:addGableRoof(x1, y1, z1, x2, y2, z2, uvRoof, uvGable, col)
  uvRoof = uvRoof or TextureAtlas.getUV("ROOF_RED")
  uvGable = uvGable or TextureAtlas.getUV("WALL_WHITE")
  local midX = (x1 + x2) / 2

  -- Left pitch (+X slant)
  local normLeft = { -0.707, 0.707, 0 }
  self:addQuad(
    { x1, y1, z2 }, { midX, y2, z2 }, { midX, y2, z1 }, { x1, y1, z1 },
    uvRoof, normLeft, col
  )

  -- Right pitch (-X slant)
  local normRight = { 0.707, 0.707, 0 }
  self:addQuad(
    { midX, y2, z2 }, { x2, y1, z2 }, { x2, y1, z1 }, { midX, y2, z1 },
    uvRoof, normRight, col
  )

  -- Front gable triangle (+Z)
  local r, g, b, a = col and col[1] or 255, col and col[2] or 255, col and col[3] or 255, 255
  local u1, v1, u2, v2 = uvGable[1], uvGable[2], uvGable[3], uvGable[4]
  local midU = (u1 + u2) / 2

  self:addVertex(x1, y1, z2, u1, v2, 0, 0, 1, r, g, b, a)
  self:addVertex(x2, y1, z2, u2, v2, 0, 0, 1, r, g, b, a)
  self:addVertex(midX, y2, z2, midU, v1, 0, 0, 1, r, g, b, a)

  -- Back gable triangle (-Z)
  self:addVertex(x2, y1, z1, u1, v2, 0, 0, -1, r, g, b, a)
  self:addVertex(x1, y1, z1, u2, v2, 0, 0, -1, r, g, b, a)
  self:addVertex(midX, y2, z1, midU, v1, 0, 0, -1, r, g, b, a)
end

-- Adds a vertical Billboard facing camera
function MeshBuilder:addBillboard(cx, cy, cz, w, h, uv, col)
  local halfW = w / 2
  local p1 = { cx - halfW, cy, cz }
  local p2 = { cx + halfW, cy, cz }
  local p3 = { cx + halfW, cy + h, cz }
  local p4 = { cx - halfW, cy + h, cz }
  self:addQuad(p1, p2, p3, p4, uv, { 0, 0, 1 }, col)
end

-- Builds and compiles the Mesh in GPU memory
function MeshBuilder:buildMesh()
  if #self.vertices == 0 then return nil end
  local mesh = love.graphics.newMesh(MeshBuilder.VERTEX_FORMAT, self.vertices, "triangles", "static")
  mesh:setTexture(TextureAtlas.getCanvas())
  return mesh
end

return MeshBuilder
