-- libraries

-- ovaltutu bootstrap things
https = nil
local overlayStats = require("lib.overlayStats")
local runtimeLoader = require("runtime.loader")

-- dkjson
local json = require "lib/dkjson"

-- batteries
local class = require("lib/batteries/class")
local StateMachine = require("lib/batteries/state_machine")

-- librería de expoguía
local expo = require("lib/expoguia")

-- assets
local expoguia_title = {
  png = love.graphics.newImage("assets/images/expoguia-title.png"),
  x = 0,
  y = 0,
  scale = 1
}
local expoguia_map = {
  png = love.graphics.newImage("assets/images/mapa.png"),
  x = 0,
  y = 0,
  scale = 1,
  allowdrag = false
}
local font_reddit_regular_16 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 16)
local font_reddit_regular_24 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 24)
local font_reddit_regular_32 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 32)
-- stands y no stands
local stand_electro_png = love.graphics.newImage("assets/images/stand-electro.png")
local stand_construcciones_png = love.graphics.newImage("assets/images/stand-construcciones.png")
local stand_ipp_png = love.graphics.newImage("assets/images/stand-ipp.png")
local stand_ciclo_basico_png = love.graphics.newImage("assets/images/stand-ciclo-basico.png")
local stand_escape_png = love.graphics.newImage("assets/images/stand-escape.png")
local stand_bath_hombres = love.graphics.newImage("assets/images/stand-bath-hombres.png")
local stand_bath_mujeres = love.graphics.newImage("assets/images/stand-bath-mujeres.png")
-- groups
local group_2_png = love.graphics.newImage("assets/images/group-2.png")
local group_3_png = love.graphics.newImage("assets/images/group-3.png")
local group_4_png = love.graphics.newImage("assets/images/group-4.png")
local group_5_png = love.graphics.newImage("assets/images/group-5.png")
local group_6_png = love.graphics.newImage("assets/images/group-6.png")
local group_7_png = love.graphics.newImage("assets/images/group-7.png")
local group_8_png = love.graphics.newImage("assets/images/group-8.png")
local group_9_png = love.graphics.newImage("assets/images/group-9.png")
local group_99_png = love.graphics.newImage("assets/images/group-99.png")

-- variables
local debug = false
local safe = {x = 0, y = 0, w = 0, h = 0}
safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()

-- colores
local color = {
  background = "#212121ff",
  text = "#ffffffff",
  foreground_light = "#2e2e2eff",
  button_idle = "#404040ff",
  button_pressed = "#202020ff"
}

-- automatic lock for kiosk mode
local autolock = {
  enabled = false,
  timer = 0,
  max = 5 -- seconds
}

-- estados
-- Crear la máquina de estados primero
local ui_state_machine = StateMachine({}, "menu")

-- Estado menú
ui_state_machine:add_state("menu", {
  enter = function(self, prev)
    print("entered menu")
  end,
  exit = function(self)
    print("exited menu")
  end,
  update = function(self, dt)
    expoguia_title.scale = expo.scale(safe.w, safe.h, expoguia_title.png:getWidth(), expoguia_title.png:getHeight(), 0.75)
    expoguia_title.x, expoguia_title.y = 0.5*safe.w, 0.5*safe.h
  end,
  draw = function(self)
    love.graphics.print("Menú principal", 10, 40)
    love.graphics.draw(expoguia_title.png, expoguia_title.x, expoguia_title.y, 0, expoguia_title.scale, expoguia_title.scale, 0.5*expoguia_title.png:getWidth(), 0.5*expoguia_title.png:getHeight())
  end
})

-- Estado mapa
ui_state_machine:add_state("map", {
  enter = function(self, prev)
    print("entered map")
    expoguia_map.x, expoguia_map.y = 0.5*safe.w, 0.5*safe.h
    expoguia_map.scale = expo.scale(safe.w, safe.h, expoguia_map.png:getWidth(), expoguia_map.png:getHeight(), 1.1)
  end,
  exit = function(self)
    print("exited map")
    if autolock.enabled then autolock.timer = 0 end
  end,
  update = function(self, dt)
    if autolock.enabled then
      autolock.timer = autolock.timer + dt
      if autolock.timer >= autolock.max then
        print("autolock: returning to menu")
        ui_state_machine:set_state("menu")
        autolock.timer = 0
      end
    end
  end,
  draw = function(self)
    love.graphics.print("map view", 10, 40)
    love.graphics.draw(expoguia_map.png, expoguia_map.x, expoguia_map.y, 0, expoguia_map.scale, expoguia_map.scale, 0.5*expoguia_map.png:getWidth(), 0.5*expoguia_map.png:getHeight())
  end
})

function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here
  overlayStats.load() -- Should always be called last

  -- safearea
  safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()

  -- activate autolock for kiosk devices (pc)
  if love.system.getOS() == "iOS" or love.system.getOS() == "Android" then
    autolock.enabled = false
  else
    autolock.enabled = true
  end
end

function love.update(dt)
  -- si dt es demasiado alto, limitarlo a 0.07.
	if dt > 0.07 then
		dt = 0.07
	end

  -- safearea
  -- safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()

  ui_state_machine:update(dt)
  -- Your game update here
  overlayStats.update(dt) -- Should always be called last
end

function love.draw()
  -- Your game draw here
  love.graphics.push()
  love.graphics.setColor(1, 1, 1, 1) -- setear el color a blanco

  love.graphics.setFont(font_reddit_regular_16) -- setear la fuente por defecto
  local r, g, b, a = expo.hexcolorfromstring(color.background)
  love.graphics.setBackgroundColor(r, g, b, a) -- setear el background a negro

  love.graphics.translate(safe.x, safe.y) -- translatear a safe_x y safe_y

	love.graphics.print("I have to rewrite my entire app, because it is spaghetti.", 10, 10)

  ui_state_machine:draw()

  love.graphics.pop()

  overlayStats.draw() -- Should always be called last
end


-- keyboard input handling
function love.keypressed(key)
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
    overlayStats.handleKeyboard(key) -- Should always be called last
  end

  if key == "1" then
    ui_state_machine:set_state("map")
  elseif key == "2" then
    ui_state_machine:set_state("menu")
  end
end


local function handlepressed(id, x, y, button, istouch)
  if debug then
    print("pressed: " .. id .. " x,y: " .. x .. "," .. y .. " button: " .. button)
  end
  if ui_state_machine:in_state("menu") then
    if expo.inrange(x, 0*safe.w, 0.1*safe.w) and
       expo.inrange(y, 0*safe.h, 0.1*safe.h) then
      print("about dialog")
    else
      ui_state_machine:set_state("map")
    end
  end

  if ui_state_machine:in_state("map") then
    if expo.inrange(x, 0*safe.w, 0.1*safe.w) and
       expo.inrange(y, 0*safe.h, 0.1*safe.h) then
      print("back to menu")
      ui_state_machine:set_state("menu")
    elseif not istouch then
      expoguia_map.allowdrag = true
    end
  end

end
local function handlemoved(id, x, y, dx, dy, istouch)
  if debug then
    print("moved: " .. id .. " x,y: " .. x .. "," .. y .. " dx,dy: " .. dx .. "," .. dy)
  end

  if ui_state_machine:in_state("map") and expoguia_map.allowdrag then
    if istouch then multiplier = 0.5 else multiplier = 1 end
    expoguia_map.x = expoguia_map.x + dx*multiplier
    expoguia_map.y = expoguia_map.y + dy*multiplier
  end
end
local function handlereleased(id, x, y, button, istouch)
  if debug then
    print("released: " .. id .. " x,y: " .. x .. "," .. y .. " button: " .. button)
  end
  if ui_state_machine:in_state("map") then
    if not istouch then
      expoguia_map.allowdrag = false
    end
  end
end

-- input handling
-- estas funciones específicas activan funciones más generales
function love.mousepressed(x, y, button, istouch, presses)
  handlepressed(1, x, y, button, false)
  autolock.timer = 0
end
function love.touchpressed(id, x, y, dx, dy, pressure)
  handlepressed(id, x, y, 1, true)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end
function love.mousemoved(x, y, dx, dy, istouch)
  handlemoved(1, x, y, dx, dy, false)
end
function love.touchmoved(id, x, y, dx, dy, pressure)
  handlemoved(id, x, y, dx, dy, true)
  autolock.timer = 0
end
function love.mousereleased(x, y, button, istouch, presses)
  handlereleased(1, x, y, button, false)
  autolock.timer = 0
end
function love.touchreleased(id, x, y, dx, dy, pressure)
  handlereleased(id, x, y, 1, true)
end

-- window resizing
function love.resize(w, h)
  safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()
end
