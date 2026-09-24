function love.conf(t)
  t.identity = "pokemon-gba-studio"
  t.version = "11.5"
  t.console = false
  
  t.window.title = "Pokémon GBA Studio++ (Launcher, Save Editor & Mod Manager)"
  t.window.icon = nil
  t.window.width = 1040
  t.window.height = 700
  t.window.minwidth = 920
  t.window.minheight = 620
  t.window.borderless = false
  t.window.resizable = true
  t.window.vsync = 1
  t.window.msaa = 4
  t.window.highdpi = true

  t.modules.audio = true
  t.modules.data = true
  t.modules.event = true
  t.modules.font = true
  t.modules.graphics = true
  t.modules.image = true
  t.modules.joystick = true
  t.modules.keyboard = true
  t.modules.math = true
  t.modules.mouse = true
  t.modules.physics = false
  t.modules.sound = true
  t.modules.system = true
  t.modules.thread = true
  t.modules.timer = true
  t.modules.touch = true
  t.modules.video = false
  t.modules.window = true
end
