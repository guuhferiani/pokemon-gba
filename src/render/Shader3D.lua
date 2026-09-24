local Shader3D = {}

local GLSL_CODE = [[
#ifdef VERTEX
uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_proj;
uniform float u_time;
uniform int u_isWater;
uniform int u_isWind;

attribute vec3 VertexNormal;

varying vec3 v_normal;
varying vec3 v_worldPos;
varying vec2 v_texCoord;
varying vec4 v_color;
varying float v_fogDepth;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vec4 localPos = vertex_position;

    // Water wave displacement
    if (u_isWater == 1) {
        float wave = sin(localPos.x * 2.5 + u_time * 2.8) * cos(localPos.z * 2.5 + u_time * 2.4);
        localPos.y += wave * 0.08;
    }

    // Foliage wind sway
    if (u_isWind == 1 && localPos.y > 0.5) {
        float sway = sin(u_time * 2.2 + localPos.x * 1.5) * 0.06;
        localPos.x += sway;
        localPos.z += sway * 0.5;
    }

    vec4 worldPos = u_model * localPos;
    v_worldPos = worldPos.xyz;
    
    // Normal transform (using 3x3 normal matrix approximation)
    mat3 normMat = mat3(u_model);
    v_normal = normalize(normMat * VertexNormal);

    v_texCoord = VertexTexCoord.xy;
    v_color = VertexColor;

    vec4 viewPos = u_view * worldPos;
    v_fogDepth = -viewPos.z;

    return u_proj * viewPos;
}
#endif

#ifdef PIXEL
uniform vec3 u_lightDir;
uniform vec3 u_lightColor;
uniform vec3 u_ambientColor;
uniform vec3 u_fogColor;
uniform float u_fogNear;
uniform float u_fogFar;
uniform int u_unlit;

varying vec3 v_normal;
varying vec3 v_worldPos;
varying vec2 v_texCoord;
varying vec4 v_color;
varying float v_fogDepth;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 texColor = Texel(tex, v_texCoord) * v_color;

    // Discard transparent pixels (for sprites and cutouts)
    if (texColor.a < 0.1) {
        discard;
    }

    if (u_unlit == 1) {
        return texColor;
    }

    // Directional Sunlight (Lambertian diffuse)
    vec3 N = normalize(v_normal);
    vec3 L = normalize(-u_lightDir);
    float diff = max(dot(N, L), 0.0);
    vec3 lighting = u_ambientColor + u_lightColor * diff;

    vec3 finalRgb = texColor.rgb * lighting;

    // Atmospheric depth fog
    float fogFactor = clamp((v_fogDepth - u_fogNear) / (u_fogFar - u_fogNear), 0.0, 1.0);
    finalRgb = mix(finalRgb, u_fogColor, fogFactor);

    return vec4(finalRgb, texColor.a);
}
#endif
]]

function Shader3D.new()
  local shader = love.graphics.newShader(GLSL_CODE)
  local instance = { shader = shader }

  function instance:sendCommon(viewMat, projMat, lightDir, lightCol, ambientCol, fogCol, fogNear, fogFar, time)
    shader:send("u_view", viewMat)
    shader:send("u_proj", projMat)
    shader:send("u_lightDir", lightDir or { -0.5, -1.0, -0.6 })
    shader:send("u_lightColor", lightCol or { 1.0, 0.95, 0.85 })
    shader:send("u_ambientColor", ambientCol or { 0.35, 0.40, 0.50 })
    shader:send("u_fogColor", fogCol or { 0.52, 0.68, 0.88 })
    shader:send("u_fogNear", fogNear or 15.0)
    shader:send("u_fogFar", fogFar or 65.0)
    shader:send("u_time", time or 0.0)
  end

  function instance:setModel(modelMat)
    shader:send("u_model", modelMat)
  end

  function instance:setFlags(isWater, isWind, unlit)
    shader:send("u_isWater", isWater and 1 or 0)
    shader:send("u_isWind", isWind and 1 or 0)
    shader:send("u_unlit", unlit and 1 or 0)
  end

  return instance
end

return Shader3D
