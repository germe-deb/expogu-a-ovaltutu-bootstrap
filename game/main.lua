
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
  scale = 1
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

-- automatic lock for kiosk mode
local autolock = {
  enabled = false,
  state = false,
  timer = 0,
  max = 60 -- seconds
}

-- estados
local ui_state = {}

ui_state.menu = {
  enter = function(self, prev)
    print("entered menu")
    expoguia_title.scale = expo.scale(safe.w, safe.h, expoguia_title.png:getWidth(), expoguia_title.png:getHeight(), 0.75)
    expoguia_title.x, expoguia_title.y = expo.centered(safe.w, safe.h, expoguia_title.png:getWidth()*expoguia_title.scale, expoguia_title.png:getHeight()*expoguia_title.scale)
  end,
  exit = function(self)
    print("exited menu")
  end,
  update = function(self, dt)
    -- Lógica del menú
  end,
  draw = function(self)
    love.graphics.print("Menú principal", 10, 40)
    love.graphics.draw(expoguia_title.png, expoguia_title.x, expoguia_title.y, 0, expoguia_title.scale, expoguia_title.scale)
  end
}

ui_state.map = {
  enter = function(self, prev)
    print("entered map")
  end,
  exit = function(self)
    print("exited map")
  end,
  update = function(self, dt)
    -- autolock:
    --[[
    if autolock.state == false then
      autolock.state = true
    elseif ui.state == 1 then
      autolock.state = false
      autolock.timer = 0
    end
    ]]
  end,
  draw = function(self)
    love.graphics.print("map view", 10, 70)

  end
}

-- Crear la máquina de estados
local ui_state_machine = StateMachine(ui_state, "menu")


function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here
  overlayStats.load() -- Should always be called last

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
  safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()

  ui_state_machine:update(dt)
  -- Your game update here
  overlayStats.update(dt) -- Should always be called last
end

function love.draw()
  -- Your game draw here

  -- Ajustar la posición vertical según el teclado
  love.graphics.push()
  love.graphics.setFont(font_reddit_regular_16) -- setear la fuente por defecto
  love.graphics.setBackgroundColor(0, 0, 0) -- setear el background a negro
  love.graphics.setColor(1, 1, 1, 1) -- setear el color a blanco

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


local function handlepressed(id, x, y, button)
  if debug then
    print("pressed: " .. id .. " x,y: " .. x .. "," .. y .. " button: " .. button)
  end
end
local function handlemoved(id, x, y, dx, dy)
  if debug then
    print("moved: " .. id .. " x,y: " .. x .. "," .. y .. " dx,dy: " .. dx .. "," .. dy)
  end
end

-- input handling
-- estas funciones específicas activan funciones más generales
function love.mousepressed(x, y, button, istouch, presses)
  handlepressed(1, x, y, button)
end
function love.touchpressed(id, x, y, dx, dy, pressure)
  handlepressed(id, x, y, 1)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end
function love.mousemoved(x, y, dx, dy, istouch)
  handlemoved(1, x, y, dx, dy)
end
function love.touchmoved(id, x, y, dx, dy, pressure)
  handlemoved(id, x, y, dx, dy)
end
function love.mousereleased(x, y, button, istouch, presses)
end
function love.touchreleased(id, x, y, dx, dy, pressure)
end
