-- libraries

-- ovaltutu bootstrap things
https = nil
local overlayStats = require("lib.overlayStats")
local runtimeLoader = require("runtime.loader")

-- json.lua
json = require("lib/json")

-- batteries
local class = require("lib/batteries/class")
local StateMachine = require("lib/batteries/state_machine")

-- librerías creadas para expoguía
local expo = require("lib/expoguia")
local uibuttons = require("lib/uibuttons")


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
  lx = 0, --lerped x
  ly = 0, --lerped y
  scale = 1,
  minZoom = 0,
  maxZoom = 6,
  allowdrag = false,
  starting_x = -40,
  starting_y = -40
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
local stand_expoguia_png = love.graphics.newImage("assets/images/stand-expoguia.png")
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
-- button textures
local recenter_1_png = love.graphics.newImage("assets/images/recenter-1.png")
local recenter_2_png = love.graphics.newImage("assets/images/recenter-2.png")

-- variables
local debug = true
local last_pinch_dist = nil
local safe = {x = 0, y = 0, w = 0, h = 0}
safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()
local floatingui = {
  x = 0,
  y = 64,
  lx = 0, -- lerped x
  ly = 64, -- lerped y
  timer = 0
}
local dialog = {
  y = safe.h,
  ly = safe.h,
  title = "",
  borderheight = 48
}
if debug then
  local debug_map_coord_x = 0
  local debug_map_coord_y = 0
end

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
  warn = 55, -- avisar que se va a volver al menú principal
  max = 60 -- seconds
}

-- stands.
local stands = {}
local stand_scale = 0.25

-- En love.load o antes de cargar stands:
local jsonFile
-- local download_url = "https://raw.githubusercontent.com/germe-deb/expogu-a-ovaltutu-bootstrap/refs/heads/main/game/assets/json/stands.json"
local download_url = "https://pastebin.com/raw/jvSE46GV"
local download_path = "download.json"

local function try_download_json()
  if not https then
    print("https library not loaded")
    return false
  end

  -- Intenta ambas variantes de retorno
  local code, body = https.request(download_url, nil, 5)
  if type(code) == "string" and tonumber(body) then
    -- Puede estar invertido
    code, body = tonumber(body), code
  end

  print("https.request code:", code)
  if body then print("https.request body (first 100 chars):", body:sub(1, 100)) end

  -- Verifica si la descarga fue exitosa
  if code == 200 and body and #body > 0 then
    -- Guardar el archivo descargado
    local ok = love.filesystem.write(download_path, body)
    if ok then
      print("Descarga exitosa de stands.json")
      return true
    else
      print("Error al guardar el archivo descargado")
    end
  else
    print("No se pudo descargar stands.json, usando archivo local.")
  end
  return false
end

-- @param stand table
-- @return love.Image
local function get_stand_texture(stand)
  if stand.especialidad == "E" then
    return stand_electro_png
  elseif stand.especialidad == "C" then
    return stand_construcciones_png
  elseif stand.especialidad == "IPP" then
    return stand_ipp_png
  elseif stand.especialidad == "ESC" then
    return stand_escape_png
  elseif stand.especialidad == "BH" then
    return stand_bath_hombres
  elseif stand.especialidad == "BM" then
    return stand_bath_mujeres
  elseif stand.especialidad == "expoguia" then
    return stand_expoguia_png
  else
    return stand_ciclo_basico_png -- textura por defecto
  end
end

-- estados
-- Crear la máquina de estados primero
local ui_state_machine = StateMachine({}, "menu")

-- Estado menú
ui_state_machine:add_state("menu", {
  enter = function(self, prev)
    print("entered menu")
    floatingui.y = 64
  end,
  exit = function(self)
    print("exited menu")
    -- iniciar un timer, usado para lerp de floatingui.ly
    floatingui.timer = 0
    floatingui.timer = love.timer.getTime()
  end,
  update = function(self, dt)
    expoguia_title.scale = expo.scale(safe.w, safe.h, expoguia_title.png:getWidth(), expoguia_title.png:getHeight(), 0.75)
    expoguia_title.x, expoguia_title.y = 0.5*safe.w, 0.5*safe.h
  end,
  draw = function(self)
    love.graphics.push()
    love.graphics.print("Menú principal", 10, 40)
    -- PNG del título
    love.graphics.draw(expoguia_title.png, expoguia_title.x, expoguia_title.y, 0, expoguia_title.scale, expoguia_title.scale, 0.5*expoguia_title.png:getWidth(), 0.5*expoguia_title.png:getHeight())
    text = "Toca la pantalla para empezar"
    font = font_reddit_regular_24
    love.graphics.setFont(font)
    love.graphics.print(text, safe.w/2, safe.h*0.82, 0, 1,1, font:getWidth(text)/2, font:getHeight()/2)
    love.graphics.pop()
  end
})

-- Estado mapa
ui_state_machine:add_state("map", {
  enter = function(self, prev)
    print("entered map")
    -- setear las posiciones por defecto
    expoguia_map.x, expoguia_map.y = 0.5*safe.w, 0.5*safe.h
    expoguia_map.scale = expo.scale(safe.w, safe.h, expoguia_map.png:getWidth(), expoguia_map.png:getHeight(), 1.1)
    -- traer la ui flotante a la vista
    floatingui.y = 0
  end,
  exit = function(self)
    print("exited map")
    if autolock.enabled then autolock.timer = 0 end
    floatingui.timer = 0
    floatingui.timer = love.timer.getTime()
  end,
  update = function(self, dt)
    -- actualizar autolock
    if autolock.enabled and not (love.mouse.isDown(1) or love.mouse.isDown(2))then
      autolock.timer = autolock.timer + dt
      if autolock.timer >= autolock.max then
        print("autolock: returning to menu")
        ui_state_machine:set_state("menu")
        autolock.timer = 0
      end
    end
  end,
  draw = function(self)
    -- Dibujar el mapa
    love.graphics.print("map view", 10, 40)
    love.graphics.draw(expoguia_map.png, expoguia_map.x, expoguia_map.y, 0, expoguia_map.scale, expoguia_map.scale, 0.5*expoguia_map.png:getWidth(), 0.5*expoguia_map.png:getHeight())

    -- Renderizar stands
    for _, stand in ipairs(stands) do
      local tex = get_stand_texture(stand)
      -- Convertir coordenadas lógicas a pantalla
      -- Suponiendo que stand.x y stand.y están en el sistema lógico (-1000 a 1000)
      local map = expoguia_map
      local map_w, map_h = map.png:getWidth(), map.png:getHeight()
      local sx = map.x + ((stand.x + 1000) / 2000) * map_w * map.scale - map_w * map.scale / 2
      local sy = map.y + ((stand.y + 1000) / 2000) * map_h * map.scale - map_h * map.scale / 2

      -- Dibujar la textura centrada
      -- love.graphics.draw( drawable, x, y, r, sx, sy, ox, oy, kx, ky )
      love.graphics.draw(tex, sx, sy, 0, stand_scale, stand_scale, tex:getWidth() / 2, tex:getHeight())
    end

    -- cartel de aviso del autolock
    if autolock.timer >= autolock.warn then
      expo.pillbutton(14, 14, "Volviendo automáticamente al menú.", font_reddit_regular_16, color.background, color.text, 20, 0,0)
    end
  end
})

-- maquina de estados para los dialogos
local dialog_state_machine = StateMachine({}, "idle")

-- Estado idle
dialog_state_machine:add_state("ilde", {
  enter = function(self, prev)
    dialog.y = safe.h
  end,
  exit = function(self)
  end,
  update = function(self, dt)
  end,
  draw = function(self)
  end
})

-- about
dialog_state_machine:add_state("about", {
  enter = function(self, prev)
    dialog.y = safe.h*0.4
  end,
  exit = function(self)
  end,
  update = function(self, dt)
  end,
  draw = function(self)
  end
})
-- filtros
dialog_state_machine:add_state("filter", {
  enter = function(self, prev)
    dialog.y = safe.h*0.15
  end,
  exit = function(self)
  end,
  update = function(self, dt)
  end,
  draw = function(self)
  end
})
-- stand ("selección")
dialog_state_machine:add_state("stand", {
  enter = function(self, prev)
    dialog.y = safe.h*0.4
  end,
  exit = function(self)
  end,
  update = function(self, dt)
  end,
  draw = function(self)
  end
})


--- Realiza un zoom logarítmico en el mapa, manteniendo el punto (px, py) fijo en pantalla
-- @param factor number: factor de multiplicación (>1 para acercar, <1 para alejar)
-- @param px, py: punto de referencia en coordenadas de pantalla (por defecto centro)
local function zoom_map(factor, px, py)
  local map = expoguia_map
  local old_scale = map.scale
  local new_scale = math.max(map.minZoom, math.min(map.maxZoom, old_scale * factor))
  if new_scale == old_scale then return end

  -- Si no se pasa un punto, usar el centro de la pantalla
  px = px or safe.w / 2
  py = py or safe.h / 2

  -- Ajustar la posición para que el punto bajo el cursor quede fijo
  -- (px - map.x) / old_scale = (px - new_x) / new_scale
  -- => new_x = px - (px - map.x) * (new_scale / old_scale)
  map.x = px - (px - map.x) * (new_scale / old_scale)
  map.y = py - (py - map.y) * (new_scale / old_scale)
  map.scale = new_scale
end

function love.load()
  https = runtimeLoader.loadHTTPS()

  local ok = try_download_json()
  if ok then
    jsonFile = love.filesystem.read(download_path)
  else
    -- usando archivo local
    jsonFile = love.filesystem.read("assets/json/stands.json")
  end

  if jsonFile then
    stands = json.decode(jsonFile)
    stands = expo.automate_stand_id(stands)
  end

  -- Your game load here

  -- safearea
  safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()

  -- zoom mínimo y máximo del mapa
  expoguia_map.minZoom = expo.scale(safe.w, safe.h, expoguia_map.png:getWidth(), expoguia_map.png:getHeight(), 0.9)
  expoguia_map.maxZoom = expo.scale(safe.w, safe.h, expoguia_map.png:getWidth(), expoguia_map.png:getHeight(), 20)


  -- activate autolock for kiosk devices (pc)
  if love.system.getOS() == "iOS" or love.system.getOS() == "Android" then
    autolock.enabled = false
  else
    autolock.enabled = true
  end

  -- button creation
  -- En love.load, registra el botón así:
  uibuttons.register{
    get_rect = function()
      local texto = "Filtrar"
      local radius = 20 -- Usa el radio que quieras
      local text_w = font_reddit_regular_16:getWidth(texto)
      local total_w = text_w + 2 * radius
      local total_h = 2 * radius
      -- Tu fórmula original para el centro del botón:
      local cx = safe.w - 14 - (24*2) - 14 + floatingui.lx
      local cy = safe.h - 14 + floatingui.ly
      -- El área de toque debe ser el rectángulo que contiene el píldora, alineado a la esquina inferior derecha
      local x = cx - total_w
      local y = cy - total_h
      return x, y, total_w, total_h, texto, radius, cx, cy
    end,
    draw = function(self)
      local x, y, w, h, texto, radius, cx, cy = self.get_rect()
      -- Fondo del botón
      local bcolor = color.button_idle
      if self.pressed then
        bcolor = color.button_pressed
      else
        bcolor = color.button_idle
      end
      -- Dibuja el botón igual que antes, usando ox=1, oy=1
      expo.pillbutton(cx, cy, texto, font_reddit_regular_16, bcolor, color.text, radius, 1, 1)
    end,
    onpress = function(self)
      print("Botón Filtrar presionado")
      -- Aquí puedes abrir el diálogo de filtros, etc.
    end
  }
  uibuttons.register{
  get_rect = function()
    local cx = safe.w - 38 + floatingui.lx
    local cy = safe.h - 38 + floatingui.ly
    local radius = 24
    -- Área de toque: rectángulo circunscrito al círculo
    local x = cx - radius
    local y = cy - radius
    local w = radius * 2
    local h = radius * 2
    return x, y, w, h, cx, cy, radius
  end,
  draw = function(self)
    local x, y, w, h, cx, cy, radius = self.get_rect()
    -- Fondo del botón
    if self.pressed then
      r, g, b, a = expo.hexcolorfromstring(color.button_pressed)
    else
      r, g, b, a = expo.hexcolorfromstring(color.button_idle)
    end
    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", cx, cy, radius)
    -- Ícono (color.text)
    r, g, b, a = expo.hexcolorfromstring(color.text)
    love.graphics.setColor(r, g, b, a)
    local scale = 0.18
    local centered = true
    if not centered then
      love.graphics.draw(recenter_1_png, cx, cy, 0, scale, scale, 0.5*recenter_1_png:getWidth(), 0.5*recenter_1_png:getHeight())
    else
      love.graphics.draw(recenter_2_png, cx, cy, 0, scale, scale, 0.5*recenter_2_png:getWidth(), 0.5*recenter_2_png:getHeight())
    end
  end,
  onpress = function(self)
    print("Botón de recentrado presionado")
    -- Aquí pon la lógica de recentrado real si quieres
    -- floatingui.lx = 0; floatingui.ly = 0
  end
}


  overlayStats.load() -- Should always be called last
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

local function draw_always_shown_content()
  -- timer para la animación
  local elapsed = 0
  if floatingui.timer then
    elapsed = (love.timer.getTime() - floatingui.timer)*2
    if elapsed >= 1 then elapsed = 1 end
  end
  floatingui.ly = expo.lerpinout(floatingui.ly, floatingui.y, elapsed)


  -- dibujar el botón de recentrado
  local r, g, b, a = expo.hexcolorfromstring(color.button_idle)
  love.graphics.setColor(r, g, b, a)
  love.graphics.circle("fill", safe.w-38+floatingui.lx, safe.h-38+floatingui.ly, 24)
  -- ícono
  local r, g, b, a = expo.hexcolorfromstring(color.text)
  love.graphics.setColor(r, g, b, a)
  local scale = 0.18
  local centered = true -- temporal hasta que logre dar con el clavo xd
  if not centered then
    love.graphics.draw(recenter_1_png, safe.w-38+floatingui.lx, safe.h-38+floatingui.ly, 0, scale, scale, 0.5*recenter_1_png:getWidth(), 0.5*recenter_1_png:getHeight())
  else
    love.graphics.draw(recenter_2_png, safe.w-38+floatingui.lx, safe.h-38+floatingui.ly, 0, scale, scale, 0.5*recenter_2_png:getWidth(), 0.5*recenter_2_png:getHeight())
  end

  uibuttons.draw()
  -- botón de Filtros

  --[[
      local r, g, b, a = expo.hexcolorfromstring(color.button_idle)
      love.graphics.setColor(r, g, b, a)
      -- dibujar un botón estilo píldora.
      -- vendría siendo un rectángulo con bordes redondeados.
      -- necesito hacer una función en expoguia.lua porque voy a usar un montón.
      love.graphics.circle("fill", safe.w-96+floatingui.lx, safe.h-34+floatingui.ly, 20)
      local texto = "Filtrar"
      love.graphics.circle("fill", safe.w-96-font_reddit_regular_16:getWidth(texto)+floatingui.lx, safe.h-34+floatingui.ly, 20)
      love.graphics.rectangle("fill", safe.w-96-font_reddit_regular_16:getWidth(texto)+floatingui.lx, safe.h-34-20+floatingui.ly, font_reddit_regular_16:getWidth(texto), 40)
      love.graphics.setColor(1,1,1,1)
      love.graphics.print(texto, safe.w-96-font_reddit_regular_16:getWidth(texto)+floatingui.lx, safe.h-34-font_reddit_regular_16:getHeight()/2+floatingui.ly)

    local texto = "Filtrar"
    expo.pillbutton(safe.w-14-(24*2)-14+floatingui.lx, safe.h-14+floatingui.ly, texto, font_reddit_regular_16, color.button_idle, color.text, 20, 1, 1)
    ]]
  -- debug coords

  if debug and debug_map_coord_x then

    local text = "x: " .. debug_map_coord_x .. " y: " .. debug_map_coord_y
    r, g, b, a = expo.hexcolorfromstring(color.button_idle)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", 10, 100, font_reddit_regular_16:getWidth(text), font_reddit_regular_16:getHeight())

    local r, g, b, a = expo.hexcolorfromstring(color.text)
    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, 10, 100)
  end
end

function love.draw()
  -- Your game draw here
  love.graphics.push()
  love.graphics.setColor(1, 1, 1, 1) -- setear el color a blanco

  love.graphics.setFont(font_reddit_regular_16) -- setear la fuente por defecto
  local r, g, b, a = expo.hexcolorfromstring(color.background)
  love.graphics.setBackgroundColor(r, g, b, a) -- setear el background a negro
  love.graphics.translate(safe.x, safe.y) -- translatear a safe_x y safe_y
  ui_state_machine:draw()

  draw_always_shown_content()

  love.graphics.pop()
  if debug then
    -- print("expoguia_map.scale: " .. expoguia_map.scale)
  end
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
    -- if love.system.getOS() == "Linux" then
    --   print("pressed: " .. tostring(id) .. " x,y: " .. x .. "," .. y .. " button: " .. button)
    -- end

    -- cuentas para sacar las coordenadas en el mapa. suponer que las coordenadas van desde -1000 a 1000, tanto en X como en Y.
    -- guardar estos valores en debug_map_coord_x y debug_map_coord_y

    -- 1. Ajustar por el offset del mapa
    local mx = (x - expoguia_map.x) / expoguia_map.scale
    local my = (y - expoguia_map.y) / expoguia_map.scale

    -- 2. Ajustar por el origen centrado de la imagen
    local map_w = expoguia_map.png:getWidth()
    local map_h = expoguia_map.png:getHeight()
    mx = mx + map_w / 2
    my = my + map_h / 2

    -- 3. Convertir a sistema lógico (-1000 a 1000)
    debug_map_coord_x = math.floor((mx / map_w) * 2000 - 1000)
    debug_map_coord_y = math.floor((my / map_h) * 2000 - 1000)

    print("debug_map_coord_x:", debug_map_coord_x, "debug_map_coord_y:", debug_map_coord_y)
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
    else
      -- Solo permitir drag si NO se tocó un botón
      local pressed_button = uibuttons.handle_press(x - safe.x, y - safe.y)
      if not pressed_button and not istouch then
        expoguia_map.allowdrag = true
      end
      return -- Importante: no llamar dos veces a handle_press
    end
  end

  -- Si no es estado "map", igual chequea botones
  uibuttons.handle_press(x - safe.x, y - safe.y)
end

local function handlemoved(id, x, y, dx, dy, istouch)
  if debug then
    -- print("moved: " .. id .. " x,y: " .. x .. "," .. y .. " dx,dy: " .. dx .. "," .. dy)
  end
  local multiplier = 0
  if ui_state_machine:in_state("map") and expoguia_map.allowdrag then
    -- por alguna razón en touch el movimiento por defecto es grande y con esto lo intento contrarrestar
    if istouch then multiplier = 0.18 else multiplier = 1 end
    expoguia_map.x = expoguia_map.x + dx*multiplier
    expoguia_map.y = expoguia_map.y + dy*multiplier
  end
end
local function handlereleased(id, x, y, button, istouch)
  if debug then
    -- print("released: " .. id .. " x,y: " .. x .. "," .. y .. " button: " .. button)
  end
  if ui_state_machine:in_state("map") then
    if not istouch then
      expoguia_map.allowdrag = false
    end
  end
  uibuttons.handle_release(x - safe.x, y - safe.y)
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
  -- Pinch zoom
  local touches = love.touch.getTouches()
  if #touches == 2 then
    local x1, y1 = love.touch.getPosition(touches[1])
    local x2, y2 = love.touch.getPosition(touches[2])
    local dist = math.sqrt((x2-x1)^2 + (y2-y1)^2)
    if last_pinch_dist then
      local factor = dist / last_pinch_dist
      -- Centro del pinch
      local px = (x1 + x2) / 2 - safe.x
      local py = (y1 + y2) / 2 - safe.y
      zoom_map(factor, px, py)
    end
    last_pinch_dist = dist
  else
    last_pinch_dist = nil
  end
  autolock.timer = 0
end
function love.mousereleased(x, y, button, istouch, presses)
  handlereleased(1, x, y, button, false)
  autolock.timer = 0
end
function love.touchreleased(id, x, y, dx, dy, pressure)
  handlereleased(id, x, y, 1, true)
end

function love.wheelmoved(x, y)
  if ui_state_machine:in_state("map") then
    -- k controla la sensibilidad del zoom (ajusta a gusto)
    local k = 0.15
    local factor = math.exp(k * y)
    local mx, my = love.mouse.getPosition()
    zoom_map(factor, mx - safe.x, my - safe.y)
  end
  autolock.timer = 0
end

-- window resizing
function love.resize(w, h)
  safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()
end
