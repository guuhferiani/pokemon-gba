function love.errorhandler(msg)
  local err = tostring(msg) .. "\n" .. debug.traceback()
  local f = io.open("error.log", "w")
  if f then f:write(err) f:close() end
  print("LÖVE ERROR:\n" .. err)
  os.exit(1)
end

local Theme = require("src.ui.Theme")
local LauncherView = require("src.ui.LauncherView")

function love.load(args)
  Theme.initFonts()
  LauncherView.init()

  for _, a in ipairs(args or {}) do
    if a == "--ci" or a == "--headless" then
      print("[CI] Running automated launcher test pass...")
      LauncherView.update(0.016)
      LauncherView.draw()
      love.event.quit(0)
      return
    elseif a == "--test" or a == "--test-all" then
      print("[TEST] Running automated UI tests on all panels...")
      local games = { "firered", "leafgreen", "emerald", "ruby", "sapphire" }
      for _, gid in ipairs(games) do
        LauncherView.activeGameId = gid
        LauncherView.mainView = "game"
        LauncherView.update(0.016)
        LauncherView.draw()
        print("[TEST] Game panel (" .. gid .. ") rendered OK.")
      end

      LauncherView.mainView = "mods"
      LauncherView.update(0.016)
      LauncherView.draw()
      print("[TEST] Mods panel rendered OK.")

      LauncherView.mainView = "items"
      local cats = { "all", "balls", "rare", "healing", "stones", "hold" }
      for _, c in ipairs(cats) do
        LauncherView.itemsCategory = c
        LauncherView.update(0.016)
        LauncherView.draw()
      end
      print("[TEST] Mochila & Itens panel (all categories) rendered OK.")

      LauncherView.mainView = "shiny"
      LauncherView.refreshShinies()
      LauncherView.update(0.016)
      LauncherView.draw()
      print("[TEST] ShinyDex panel rendered OK.")

      LauncherView.activeGameId = "firered"
      LauncherView.mainView = "game"
      LauncherView.update(0.016)
      LauncherView.draw()
      print("[TEST] All GBA Studio launcher panels validated 100% cleanly!")
      print("[INFO] Abrindo a interface gráfica agora...")
      -- Kept open so the user can use the launcher!
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

function love.focus(focused)
  if LauncherView.onFocus then
    LauncherView.onFocus(focused)
  end
end
