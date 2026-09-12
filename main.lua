function love.errorhandler(msg)
  local err = tostring(msg) .. "\n" .. debug.traceback()
  local f = io.open("error.log", "w")
  if f then f:write(err) f:close() end
  local f2 = io.open("gba/error.log", "w")
  if f2 then f2:write(err) f2:close() end
  print("LÖVE ERROR:\n" .. err)
  os.exit(1)
end

local Theme = require("src.ui.Theme")
local LauncherView = require("src.ui.LauncherView")

function love.load(args)
  Theme.initFonts()
  LauncherView.init()
  for _, a in ipairs(args or {}) do
    if a == "--test" then
      print("[TEST] Running automated UI tests...")
      LauncherView.update(0.016)
      LauncherView.draw()
      print("[TEST] Game panel rendered OK.")
      LauncherView.mainView = "mods"
      LauncherView.update(0.016)
      LauncherView.draw()
      print("[TEST] Mods panel rendered OK.")
      local GbaMods = require("src.core.GbaMods")
      local mods = GbaMods.list()
      if #mods > 0 then
        print("[TEST] Found " .. #mods .. " mods. Toggling " .. mods[1].id .. "...")
        GbaMods.toggle(mods[1].id)
        GbaMods.toggle(mods[1].id)
      end
      LauncherView.mainView = "game"
      LauncherView.update(0.016)
      LauncherView.draw()
      print("[TEST] All GBA launcher views & rendering tests passed!")
      love.event.quit(0)
      return
    end
  end
end

function love.update(dt)
  LauncherView.update(dt)
end

function love.draw()
  LauncherView.draw()
end

function love.mousepressed(x, y, button)
  LauncherView.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
  LauncherView.mousereleased(x, y, button)
end

function love.textinput(t)
  LauncherView.textinput(t)
end

function love.keypressed(key)
  LauncherView.keypressed(key)
end
