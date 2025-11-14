-- SPDX-FileCopyrightText: 2025 germe-deb <dpkg.luci@protonmail.com>
--
-- SPDX-License-Identifier: GPL-3.0-or-later

-- libraries

-- ovaltutu bootstrap things
https = nil
local ffi = require("ffi")
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
local Color = require "lib/colors"

-- agregar un headerbar (un area arrastrable a la ventana)
-- Gracias EngineerSmith!!!
local ffi = require("ffi")


-- default filtering
love.graphics.setDefaultFilter("linear", "linear", 16)

-- assets
local expoguia_title = {
  png = love.graphics.newImage("assets/images/expoguia-title.png",
        {mipmaps = true}),
  x = 0,
  y = 0,
  scale = 1
}
local expoguia_map = {
  png = love.graphics.newImage("assets/images/mapa.png"),
        {mipmaps = true},
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

-- fonts
local font_reddit_regular_13 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 13)
local font_reddit_regular_16 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 16)
local font_reddit_regular_24 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 24)
local font_reddit_regular_32 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 32)
-- stand display fonts
local font_reddit_stand_small = love.graphics.newFont("assets/fonts/RedditSans-SemiBold.ttf", 36)
local font_reddit_stand_curso = love.graphics.newFont("assets/fonts/RedditSans-SemiBold.ttf", 52)
local font_reddit_stand_title = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 74)
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
-- tarjetas
local stand_info_top_fg_png = love.graphics.newImage("assets/images/stand-info-top-fg.png")
local stand_info_top_bg_png = love.graphics.newImage("assets/images/stand-info-top-bg.png")
local stand_info_bottom_fg_png = love.graphics.newImage("assets/images/stand-info-bottom-fg.png")
local stand_info_bottom_bg_png = love.graphics.newImage("assets/images/stand-info-bottom-bg.png")
-- button textures
local back_png = love.graphics.newImage("assets/images/back.png")
local reload_png = love.graphics.newImage("assets/images/reload.png")
-- variables
local copyright = "Copyright © 2025 Lucia Gianluca"
local debug = true
local offlinemode = false
local experimentalheader = false
local last_pinch_dist = nil
local jsondltimer = 0
local touchmultiplier = 0.035
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
  borderheight = 48,
  dragging = false,
  is_pressed = false,  -- Rastrear si el botón del mouse/touch está presionado
  scroll_started = false,  -- Rastrear si el scroll ya comenzó
  min_y = safe.h*0.1,
  max_y = safe.h*0.7,
  scroll_y = 0,
  buttons = {},
  canvas = nil,
  -- Dimensiones dinámicas del contenido
  content_width = 0,
  content_x = 0,
  content_y = 0,
  content_height = 0,
  content_top = 0
}
Filtros = {
  exclude = false,
  cursos = {},
  especialidades = {}
}

local drag_start_x = 0
local drag_start_y = 0
local did_drag = false
local pressed_filter_button = nil  -- Rastrear qué botón de filtro fue presionado
local pressed_dialog_button = nil  -- Rastrear qué botón del diálogo fue presionado
local filter_mode = "include"  -- Modo de filtrado: "include" o "exclude"
if debug then
  local debug_map_coord_x = 0
  local debug_map_coord_y = 0
end
local errorOffline = false

-- set the icon
local icon = love.image.newImageData("assets/images/app_icon.png")
-- local width, height = icon:getDimensions()
local success = love.window.setIcon( icon )

-- print("icon applied: " .. tostring(success))
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
local selected_stand = nil

-- En love.load o antes de cargar stands:
local jsonFile = 0
local download_url = "https://pastebin.com/raw/jvSE46GV"
local download_path = "download.json"

-- json de las categorias / filtros
local filters_json = love.filesystem.read("assets/json/filters.json")
local filters_data = nil
local filters_ui = {
  categories = {}
}

-- ========================================
-- FUNCIÓN: try_download_json
-- ========================================
-- Intenta descargar el archivo JSON de stands desde internet.
-- Esta función es llamada al iniciar la app si no está en modo offline.
--
-- Funcionamiento:
--   1. Verifica si la librería https está cargada
--   2. Realiza una petición HTTP GET a la URL configurada (con timeout de 5 segundos)
--   3. Maneja ambos formatos de retorno posibles (code, body o body, code)
--   4. Si la respuesta es exitosa (código 200), guarda el archivo descargado
--   5. Imprime logs de debug para diagnosticar problemas
--
-- Retorna: boolean - true si la descarga y guardado fue exitoso, false en caso contrario
local function try_download_json()
  if not https then
    print("https library not loaded")
    return false
  end

  -- Intenta realizar la petición HTTP a la URL configurada
  -- Timeout de 5 segundos para evitar que se cuelgue la app
  local code, body = https.request(download_url, nil, 5)
  if type(code) == "string" and tonumber(body) then
    -- Puede estar invertido (algunas versiones de https retornan en orden inverso)
    code, body = tonumber(body), code
  end

  print("https.request code:", code)
  if body then print("https.request body (first 100 chars):", body:sub(1, 100)) end

  -- Verifica si la descarga fue exitosa (código HTTP 200 OK)
  if code == 200 and body and #body > 0 then
    -- Guardar el archivo descargado al path especificado
    local ok = love.filesystem.write(download_path, body)
    if ok then
      print("Descarga exitosa de stands.json")
      return true
    else
      print("Error al guardar el archivo descargado")
    end
  end
  return false
end

-- stand table
-- ========================================
-- FUNCIÓN: get_stand_texture
-- ========================================
-- Retorna la textura (imagen) correspondiente a un stand según su especialidad.
-- Esta función mapea los códigos de especialidad a sus imágenes específicas.
--
-- Parámetros:
--   stand (table): objeto del stand que contiene al menos:
--     - especialidad (string): código de especialidad (ej: "E", "C", "IPP", etc.)
--
-- Funcionamiento:
--   1. Evalúa el código de especialidad del stand
--   2. Retorna la textura PNG correspondiente a esa especialidad
--   3. Si la especialidad no es reconocida, usa la textura por defecto
--
-- Retorna: love.Image - la textura PNG del stand
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

-- ========================================
-- FUNCIÓN: get_stand_at_point
-- ========================================
-- Detecta si se tocó un stand en coordenadas de pantalla específicas.
-- Usa detección de colisión circular para determinar qué stand fue tocado.
--
-- Parámetros:
--   px (number): posición X en coordenadas de pantalla
--   py (number): posición Y en coordenadas de pantalla
--
-- Funcionamiento:
--   1. Recorre todos los stands en la tabla de stands
--   2. Para cada stand, calcula su posición en pantalla (convertido desde coordenadas lógicas)
--   3. Calcula la distancia al cuadrado entre el punto tocado y el centro del stand
--   4. Verifica si la distancia es menor al radio del stand (considerado como círculo)
--   5. Mantiene track del stand más cercano (en caso de solapamientos)
--   6. Retorna el stand más cercano al punto, o nil si no hay colisión
--
-- Retorna: table - el objeto del stand tocado, o nil si no se tocó ninguno
local function get_stand_at_point(px, py)
  local closest_stand = nil
  local min_dist_sq = math.huge
  -- Iterar sobre todos los stands para encontrar el más cercano al punto tocado
  for _, stand in ipairs(stands) do
    local tex = get_stand_texture(stand)
    local map = expoguia_map
    local map_w, map_h = map.png:getWidth(), map.png:getHeight()
    -- Convertir coordenadas lógicas del stand (-1000 a 1000) a coordenadas de pantalla
    local sx = map.x + ((stand.x + 1000) / 2000) * map_w * map.scale - map_w * map.scale / 2
    local sy = map.y + ((stand.y + 1000) / 2000) * map_h * map.scale - map_h * map.scale / 2
    -- Radio de colisión del stand (círculo)
    local r = tex:getWidth() * stand_scale * 0.9
    -- Calcular la distancia al cuadrado (evita usar sqrt que es más lento)
    local dist_sq = (px - sx)^2 + (py - sy)^2
    -- Si el punto está dentro del radio Y es el más cercano encontrado hasta ahora
    if dist_sq <= r^2 and dist_sq < min_dist_sq then
      min_dist_sq = dist_sq
      closest_stand = stand
    end
  end
  -- Retornar el stand más cercano al punto, o nil si no hay colisión
  return closest_stand
end


-- ========================================
-- FUNCIÓN: isStandFiltered
-- ========================================
-- Determina si un stand debe mostrarse con opacidad normal o reducida
-- según los filtros actuales y el modo de filtrado.
--
-- Parámetros:
--   standId (string|number): ID del stand a verificar (ej: "403E", "101")
--
-- Funcionamiento:
--   1. Recorre todas las categorías de filtros
--   2. Verifica si el stand está seleccionado en alguna categoría
--   3. Según filter_mode:
--      - "include": muestra SOLO los stands seleccionados
--      - "exclude": muestra TODOS EXCEPTO los stands seleccionados
--   4. Si no hay stands seleccionados, muestra todos
--
-- Retorna: boolean - true si el stand debe mostrarse normal, false si debe atenuarse
local function isStandFiltered(standId)
  -- Crear una tabla para guardar qué stands están seleccionados
  local selectedStands = {}

  -- Recorrer todas las categorías para saber qué stands están seleccionados
  for _, cat in pairs(filters_ui.categories) do
    for stand, isSelected in pairs(cat.stands) do
      if isSelected then
        selectedStands[stand] = true
      end
    end
  end

  -- Si no hay stands seleccionados, mostrar todos con opacidad normal
  if next(selectedStands) == nil then
    return true
  end

  -- Convertir standId a string para comparar
  standId = tostring(standId)

  -- Verificar si el stand está en la tabla de seleccionados
  local isSelected = selectedStands[standId] == true

  -- Aplicar lógica según el modo de filtrado
  if filter_mode == "include" then
    -- Modo "include": mostrar SOLO los stands seleccionados
    return isSelected
  else
    -- Modo "exclude": mostrar TODOS EXCEPTO los stands seleccionados
    return not isSelected
  end
end

-- ========================================
-- FUNCIÓN 1: toggleCategory
-- ========================================
-- Alterna (activa/desactiva) una categoría COMPLETA y todos sus stands.
-- Esta función es útil para seleccionar/deseleccionar rápidamente grupos de stands.
--
-- Parámetros:
--   cat (table): tabla de categoría que contiene:
--     - selected (boolean): estado actual de la categoría
--     - stands (table): tabla de stands donde las claves son IDs y valores son booleans
--
-- Funcionamiento:
--   1. Invierte el estado actual de la categoría (true -> false, false -> true)
--   2. Aplica ese nuevo estado a TODOS los stands dentro de la categoría
function toggleCategory(cat)
  -- Invertir el estado actual de la categoría
  -- Si estaba seleccionada (true), pasa a no seleccionada (false) y viceversa
  local newState = not cat.selected
  cat.selected = newState

  -- Actualizar TODOS los stands dentro de esta categoría
  -- al mismo estado que la categoría
  for stand, _ in pairs(cat.stands) do
    cat.stands[stand] = newState
  end
end

-- ========================================
-- FUNCIÓN 2: toggleStand
-- ========================================
-- Alterna (activa/desactiva) UN STAND específico dentro de una categoría
-- y automáticamente actualiza el estado de la categoría según todos sus stands.
--
-- Parámetros:
--   cat (table): tabla de la categoría que contiene los stands
--   stand (string): ID o clave del stand a alternar
--
-- Funcionamiento:
--   1. Invierte el estado del stand individual (true -> false, false -> true)
--   2. Recorre TODOS los stands de la categoría para verificar si están seleccionados
--   3. Si TODOS los stands están seleccionados, marca la categoría como seleccionada
--   4. Si AL MENOS UNO está sin seleccionar, marca la categoría como no seleccionada
--   5. Esto mantiene sincronizado el estado de la categoría con sus stands
function toggleStand(cat, stand)
    -- Invertir el estado del stand individual
    -- Si estaba seleccionado, lo deselecciona y viceversa
    cat.stands[stand] = not cat.stands[stand]

    -- Después de cambiar el stand, necesitamos verificar
    -- si TODOS los stands de la categoría están seleccionados
    local all = true
    for _, selected in pairs(cat.stands) do
        -- Si encontramos UN stand que NO está seleccionado...
        if not selected then
            -- ...entonces no todos están seleccionados
            all = false
            break  -- Salir del bucle, ya encontramos uno sin seleccionar
        end
    end
    -- Actualizar el estado de la categoría según si todos sus stands están seleccionados
    cat.selected = all
end

-- ========================================
-- FUNCIÓN 3: applyFilters
-- ========================================
-- Filtra la lista de stands según qué está seleccionado en el UI.
-- Esta función es útil cuando necesitas obtener una lista filtrada de stands
-- para operar sobre ella (por ejemplo, contar cuántos stands coinciden).
--
-- Parámetros:
--   allStands (table): tabla de TODOS los stands en el juego
--   UI (table): tabla del UI con categorías (no se usa actualmente)
--   mode (string): modo de filtrado - "incluir" o "excluir"
--
-- Funcionamiento del modo "incluir":
--   1. Recorre todas las categorías del UI
--   2. Crea una tabla con los IDs de stands seleccionados
--   3. Si no hay stands seleccionados, devuelve TODOS los stands (sin filtrar)
--   4. Si hay seleccionados, devuelve SOLO los que están en la tabla seleccionada
--
-- Funcionamiento del modo "excluir":
--   1. Recorre todas las categorías del UI
--   2. Crea una tabla con los IDs de stands seleccionados
--   3. Devuelve todos los stands EXCEPTO los que están seleccionados
--
-- Retorna: table - lista de stands filtrada según el modo
function applyFilters(allStands, UI, mode)
    -- Crear una tabla vacía para guardar los IDs de stands seleccionados
    local selected = {}

    -- Recorrer TODAS las categorías del UI
    for _, cat in pairs(filters_ui.categories) do
        -- Recorrer TODOS los stands dentro de cada categoría
        for stand, isSelected in pairs(cat.stands) do
            -- Si el stand está seleccionado, agregarlo a la tabla "selected"
            if isSelected then
                selected[stand] = true
            end
        end
    end

    -- Verificar si hay al menos 1 stand seleccionado
    -- "next(selected) == nil" significa que la tabla está vacía
    if next(selected) == nil then
        -- Si no hay nada seleccionado, devolver TODOS los stands sin filtrar
        return allStands
    end

    -- Crear una tabla vacía para guardar los stands que pasarán el filtro
    local filtered = {}

    -- Recorrer TODOS los stands de la lista original
    for _, standObj in ipairs(allStands) do
        -- Obtener el ID del stand (ej: "403E")
        local id = standObj.id

        -- Verificar si este stand está en la tabla de seleccionados
        local included = selected[id] == true

        -- Aplicar el filtro según el modo:
        if mode == "incluir" and included then
            -- Modo "incluir": agregar solo los stands que están seleccionados
            table.insert(filtered, standObj)
        elseif mode == "excluir" and not included then
            -- Modo "excluir": agregar solo los stands que NO están seleccionados
            table.insert(filtered, standObj)
        end
    end

    -- Devolver la lista filtrada
    return filtered
end

-- ========================================
-- FUNCIÓN: resetFilters
-- ========================================
-- Desactiva todos los filtros (stands y categorías).
-- Recorre todas las categorías y establece todos los stands en false.
--
-- Funcionamiento:
--   1. Recorre todas las categorías en filters_ui
--   2. Para cada categoría, establece selected en false
--   3. Para cada stand en la categoría, establece su estado en false
--
-- Retorna: void
local function resetFilters()
  for _, cat in pairs(filters_ui.categories) do
    cat.selected = false
    for stand, _ in pairs(cat.stands) do
      cat.stands[stand] = false
    end
  end
end

-- ========================================
-- FUNCIÓN: toggleFilterMode
-- ========================================
-- Alterna el modo de filtrado entre "include" (incluir) y "exclude" (excluir).
--
-- Funcionamiento:
--   1. Invierte el modo actual
--   2. Si era "include", cambia a "exclude"
--   3. Si era "exclude", cambia a "include"
--
-- Retorna: void
local function toggleFilterMode()
  if filter_mode == "include" then
    filter_mode = "exclude"
  else
    filter_mode = "include"
  end
end


-- header bar (just for linux, windows and macos)
local headerbar = {
	png = love.graphics.newImage("assets/images/headerbar.png"),
	-- close_png = love.graphics.newImage("assets/images/headerbar-close.png"),
	-- back_png = love.graphics.newImage("assets/images/headerbar-back.png"),
	x = 0,
	y = 0,
	w = 1000,
	h = 38,
	padding = 6
}
if love.system.getOS() == "Linux" and experimentalheader == true then
	ffi.cdef[[
	  typedef struct SDL_Window SDL_Window; // https://wiki.libsdl.org/SDL2/SDL_Window

	  typedef enum {
	    SDL_HITTEST_NORMAL,
	    SDL_HITTEST_DRAGGABLE,
	    SDL_HITTEST_RESIZE_TOPLEFT,
	    SDL_HITTEST_RESIZE_TOP,
	    SDL_HITTEST_RESIZE_TOPRIGHT,
	    SDL_HITTEST_RESIZE_RIGHT,
	    SDL_HITTEST_RESIZE_BOTTOMRIGHT,
	    SDL_HITTEST_RESIZE_BOTTOM,
	    SDL_HITTEST_RESIZE_BOTTOMLEFT,
	    SDL_HITTEST_RESIZE_LEFT
	  } SDL_HitTestResult; // https://wiki.libsdl.org/SDL2/SDL_HitTestResult

	  typedef struct SDL_Point {
	    int x;
	    int y;
	  } SDL_Point; // https://wiki.libsdl.org/SDL2/SDL_

	  typedef SDL_HitTestResult (__cdecl *SDL_HitTest)(
	    SDL_Window *win,
	    const SDL_Point *area,
	    void* data); // https://wiki.libsdl.org/SDL2/SDL_HitTest

	  int SDL_SetWindowHitTest(SDL_Window *win, SDL_HitTest callback, void *callback_data); // https://wiki.libsdl.org/SDL2/SDL_SetWindowHitTest

	  SDL_Window* SDL_GL_GetCurrentWindow(void); // https://wiki.libsdl.org/SDL2/SDL_GL_GetCurrentWindow
	]]

	local sdl2 = ffi.load("SDL2")
	local win = sdl2.SDL_GL_GetCurrentWindow();

	local result = sdl2.SDL_SetWindowHitTest(win, function(win, area, data)
	  -- Note, this function will be called for EVERY mouse hit, keep it simple.
	  --  You may want to implement DPI scaling, unless it's a personal project that doesn't need it.
	  if expo.inrange(area.y, headerbar.y, headerbar.y+headerbar.h) and expo.inrange(area.x, headerbar.x, headerbar.x+headerbar.w) then
	    return sdl2.SDL_HITTEST_DRAGGABLE
	  end
	  return sdl2.SDL_HITTEST_NORMAL
	end, nil)

	if result ~= 0 then
	  -- fall back
	  local w, h, mode = love.window.getMode()
	  mode.borderless = true
	  love.window.setMode(w, h, mode)
	end
end

-- estados
-- Crear la máquina de estados primero
local ui_state_machine = StateMachine({}, "menu")

-- ========================================
-- ESTADO: menu
-- ========================================
-- Estado inicial de la aplicación.
-- Muestra la pantalla de inicio con el título de ExpoGuía y un mensaje para comenzar.
-- También maneja la descarga y carga del archivo JSON de stands y filtros.
--
-- Funciones del estado:
--   - enter: Inicializa variables cuando se entra al estado
--   - exit: Limpia y prepara transición cuando se sale del estado
--   - update: Lógica de actualización cada frame (descarga JSON, carga datos)
--   - draw: Renderiza la pantalla del menú
--   - handle_*: Métodos para procesar input (no usados en este estado)
--
-- Transiciones:
--   - A "map" cuando el usuario toca la pantalla (si JSON está cargado)
ui_state_machine:add_state("menu", {
  enter = function(self, prev)
    print("entered menu")
    -- Posicionar la UI flotante abajo de la pantalla
    floatingui.y = 64

    -- Posicionar la headerbar en la parte superior
		headerbar.x = 0
		headerbar.y = 0
    headerbar.h = 26
  end,
  exit = function(self)
    print("exited menu")
    -- Iniciar un timer para la animación de interpolación de floatingui
    floatingui.timer = 0
    floatingui.timer = love.timer.getTime()
  end,
  update = function(self, dt)
    -- Calcular escala del título para que se ajuste a la pantalla
    -- 0.75 significa que ocupará el 75% del espacio disponible
    expoguia_title.scale = expo.scale(safe.w, safe.h, expoguia_title.png:getWidth(), expoguia_title.png:getHeight(), 0.75)
    -- Centrar el título en la pantalla
    expoguia_title.x, expoguia_title.y = 0.5*safe.w, 0.5*safe.h

    -- Ajustar ancho de la headerbar al ancho de la pantalla
    headerbar.w = safe.w

    -- ========================================
    -- LÓGICA DE CARGA DE JSON
    -- ========================================
    -- jsondltimer es un contador que espera 3 frames antes de intentar descargar
    -- Esto evita que la descarga interfiera con la inicialización de otros sistemas
    if jsonFile == 0 and jsondltimer == 3 then
      if not offlinemode and not errorOffline then
        if debug then
          print("starting to download the json")
        end
        -- Intentar descargar el JSON desde internet
        local ok = try_download_json()
        if ok then
          -- Si la descarga fue exitosa, leer el archivo guardado
          jsonFile = love.filesystem.read(download_path)
        else
          -- Si falla, marcar error y mostrar mensaje al usuario
          errorOffline = true
        end
      elseif offlinemode then
        -- En modo offline, usar archivo local
        jsonFile = love.filesystem.read("assets/json/offline.json")
      end

	    -- Si tenemos el JSON y no hay error, decodificarlo
	    if jsonFile and not errorOffline then
	      -- Convertir string JSON a tabla Lua
	      stands = json.decode(jsonFile)
	      -- Automatizar los IDs de los stands (asignar números secuenciales)
	      stands = expo.automate_stand_id(stands)
	    end

      -- Cargar el JSON de categorías de filtros
      filters_data = json.decode(filters_json)

      -- Construir la estructura de UI de filtros a partir del JSON
      -- Cada categoría tendrá sus propios stands seleccionables
      for _, cat in ipairs(filters_data) do
        -- Crear entrada para esta categoría en filters_ui
        filters_ui.categories[cat.id] = {
            name = cat.category,              -- Nombre mostrable (ej: "Electromecánica")
            icons = cat.icons,                -- Iconos de la categoría
            settings = cat.settings or {},    -- Configuraciones especiales
            categoryStands = cat.category_stands or {},  -- IDs de especialidades
            stands = {},                      -- Tabla de stands seleccionables
            selected = false,                 -- ¿Está seleccionada la categoría?
            expanded = true                   -- ¿Está desplegada en el UI?
        }

        -- Inicializar todos los stands de esta categoría como no seleccionados
        for _, stand in ipairs(cat.stands or {}) do
            filters_ui.categories[cat.id].stands[stand] = false
        end
      end

    elseif jsondltimer < 3 and not errorOffline then
      -- Incrementar el contador de espera
      jsondltimer = jsondltimer + 1
    end

  end,
  draw = function(self)
    love.graphics.push()
    -- Dibujar el PNG del título escalado
    love.graphics.draw(expoguia_title.png, expoguia_title.x, expoguia_title.y, 0, expoguia_title.scale, expoguia_title.scale, 0.5*expoguia_title.png:getWidth(), 0.5*expoguia_title.png:getHeight())

    -- Determinar el mensaje a mostrar según el estado de la descarga
    local font, text
    if errorOffline then
      -- Error: no hay conexión a internet
      font = font_reddit_regular_16
      text = "Conéctese a internet y reinicie la app."
    elseif jsonFile == 0 then
      -- En progreso: descargando JSON
      font = font_reddit_regular_16
      text = "Por favor espere. Descargando stands..."
    else
      -- Completado: listo para comenzar
      font = font_reddit_regular_24
      text = "Toca la pantalla para empezar"
    end

    -- Dibujar el mensaje centrado
    love.graphics.setFont(font)
    love.graphics.print(text, safe.w/2, safe.h*0.82, 0, 1,1, font:getWidth(text)/2, font:getHeight()/2)

    -- Dibujar el copyright en la parte inferior
    font = font_reddit_regular_13
    love.graphics.setFont(font)
    love.graphics.print(copyright, safe.w/2, safe.h-5, 0, 1,1, font:getWidth(copyright)/2, font:getHeight())

    love.graphics.pop()
  end,
  handle_press = function(self)
  end,
  handle_moved = function(self)
  end,
  handle_release = function(self)
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

		headerbar.x = 64
		headerbar.y = 0
    headerbar.h = 26
  end,
  exit = function(self)
    print("exited map")
    if autolock.enabled then autolock.timer = 0 end
    floatingui.timer = 0
    floatingui.timer = love.timer.getTime()
    selected_stand = nil
    -- dialog_state_machine:set_state("idle")
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

    -- Calcular los límites del mapa
    local map = expoguia_map
    local map_w = map.png:getWidth() * map.scale
    local map_h = map.png:getHeight() * map.scale

    -- Limitar la posición del mapa
    -- UL no puede superar safe.w/2 y safe.h/2
    -- DR no puede ser menor a safe.w/2 y safe.h/2
    local ul_x = map.x - map_w/2  -- posición x de UL
    local ul_y = map.y - map_h/2  -- posición y de UL
    local dr_x = map.x + map_w/2  -- posición x de DR
    local dr_y = map.y + map_h/2  -- posición y de DR

    -- Aplicar restricciones
    if ul_x > safe.w/2 then
      map.x = safe.w/2 + map_w/2
    end
    if ul_y > safe.h/2 then
      map.y = safe.h/2 + map_h/2
    end
    if dr_x < safe.w/2 then
      map.x = safe.w/2 - map_w/2
    end
    if dr_y < safe.h/2 then
      map.y = safe.h/2 - map_h/2
    end

    -- headerbar.w = safe.w - headerbar.x
  end,
  draw = function(self)
    -- Dibujar el mapa
    love.graphics.draw(expoguia_map.png, expoguia_map.x, expoguia_map.y, 0, expoguia_map.scale, expoguia_map.scale, 0.5*expoguia_map.png:getWidth(), 0.5*expoguia_map.png:getHeight())

    -- Renderizar stands
    -- Este bucle dibuja todos los stands con la opacidad aproppiada según los filtros
    for _, stand in ipairs(stands) do
      local tex = get_stand_texture(stand)
      -- Convertir coordenadas lógicas a pantalla
      -- Suponiendo que stand.x y stand.y están en el sistema lógico (-1000 a 1000)
      local map = expoguia_map
      local map_w, map_h = map.png:getWidth(), map.png:getHeight()
      local sx = map.x + ((stand.x + 1000) / 2000) * map_w * map.scale - map_w * map.scale / 2
      local sy = map.y + ((stand.y + 1000) / 2000) * map_h * map.scale - map_h * map.scale / 2

      stand_scale = math.min(0.30, map.scale*0.8)

      -- Determinar la opacidad del stand según si pasa el filtro actual
      -- isStandFiltered() retorna true si el stand está en los filtros seleccionados
      local opacity = 1.0  -- opacidad normal (stand visible)
      if not isStandFiltered(stand.id) then
        opacity = 0.30  -- opacidad reducida (stand atenuado)
      end

      -- Establecer el color con la opacidad calculada
      -- Mantener RGB en blanco (1, 1, 1) y solo cambiar la opacidad (alpha)
      love.graphics.setColor(1, 1, 1, opacity)

      -- Dibujar la textura centrada
      -- love.graphics.draw( drawable, x, y, r, sx, sy, ox, oy, kx, ky )
      love.graphics.draw(tex, sx, sy, 0, stand_scale, stand_scale, tex:getWidth() / 2, tex:getHeight())
    end

    -- Resetear el color a blanco y opacidad completa para los siguientes elementos
    love.graphics.setColor(1, 1, 1, 1)

    -- Mostrar info del stand seleccionado
    if selected_stand then
      --[[
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 10, 10, 260, 60, 8, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(font_reddit_regular_16)
        love.graphics.print("x,y: " .. selected_stand.x .. "," .. selected_stand.y, 20, 20)
        love.graphics.print("Título: " .. (selected_stand.texto or "-"), 20, 40)
        if selected_stand.curso then
          love.graphics.print("Curso: " .. selected_stand.curso .. (selected_stand.especialidad or ""), 20, 60)
        end
        if selected_stand.profesor then
          love.graphics.print("Profesor: " .. selected_stand.profesor, 20, 80)
        end
        ]]
      expo.draw_stand(selected_stand, safe,
      -- stand textures
      stand_info_top_bg_png, stand_info_top_fg_png,
      stand_info_bottom_bg_png, stand_info_bottom_fg_png,
      -- fonts
      font_reddit_stand_small,
      font_reddit_stand_curso,
      font_reddit_stand_title)
    end


    -- cartel de aviso del autolock
    if autolock.timer >= autolock.warn then
      expo.pillbutton(safe.w/2, safe.h/2, "Volviendo automáticamente al menú.", font_reddit_regular_16, Color.background, Color.text, 20, 0.5,0.5)
    end

    if debug_map_coord_x then
      love.graphics.setFont(font_reddit_regular_16)

      local text = "x: " .. debug_map_coord_x .. " y: " .. debug_map_coord_y
      r, g, b, a = expo.hexcolorfromstring(Color.button_idle)
      love.graphics.setColor(r, g, b, a)
      love.graphics.rectangle("fill", 10, safe.h-100, font_reddit_regular_16:getWidth(text), font_reddit_regular_16:getHeight())

      local r, g, b, a = expo.hexcolorfromstring(Color.text)
      love.graphics.setColor(r, g, b, a)
      love.graphics.print(text, 10, safe.h-100)
    end
  end,
  handle_press = function(self)
  end,
  handle_moved = function(self)
  end,
  handle_release = function(self)
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
  end,
  handle_press = function(self)
  end,
  handle_moved = function(self)
  end,
  handle_release = function(self)
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
  end,
  handle_press = function(self)
  end,
  handle_moved = function(self)
  end,
  handle_release = function(self)
  end
})
-- filtros
dialog_state_machine:add_state("filter", {
  enter = function(self, prev)
    dialog.y = safe.h * 0.5
    dialog.min_y = safe.h * 0.2
    dialog.max_y = safe.h * 0.8
    dialog.scroll_y = 0
    dialog.dragging = false
    -- Construir los botones de filtros con el ancho completo
    dialog.buttons = expo.build_filter_buttons(filters_ui, filters_data, safe.w)
  end,
  exit = function(self)
    dialog.scroll_y = 0
    dialog.dragging = false
    dialog.scroll_started = false
  end,
  update = function(self, dt)
    if ui_state_machine:in_state("menu") then
      dialog_state_machine:set_state("idle")
    end
    -- Recalcular dimensiones dinámicamente cada frame
    -- Usar ancho completo (sin padding lateral en el área clickeable)
    dialog.content_width = safe.w
    dialog.content_x = 0

    local radius = 24
    local full_header_height = radius * 6

    dialog.content_top = dialog.y + full_header_height
    dialog.content_y = dialog.content_top
    dialog.content_height = safe.h - dialog.content_y
  end,
  draw = function(self)
    local content = {
      windowtype = "filtros",
      mode = filter_mode
    }

    -- Dibujar el canvas con los filtros
    expo.draw_filter_canvas(
      dialog.canvas,
      filters_ui,
      filters_data,
      font_reddit_regular_16,
      Color,
      dialog.scroll_y,
      dialog.content_width
    )

    -- Dibujar el diálogo
    expo.dialog(
      0,
      dialog.y,
      safe,
      content,
      stands,
      font_reddit_regular_32,
      font_reddit_regular_16,
      Color,
      filters_ui,
      filters_data,
      toggleCategory,
      toggleStand,
      filter_mode
    )

    -- Dibujar el canvas en pantalla sin clipping (el canvas es lo suficientemente grande)
    if dialog.canvas then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(dialog.canvas, dialog.content_x, dialog.content_y)
    end
  end,
  handle_press = function(self)
  end,
  handle_moved = function(self)
  end,
  handle_release = function(self)
  end
})

--- Realiza un zoom logarítmico en el mapa, manteniendo el punto (px, py) fijo en pantalla
--
-- Parámetros:
--   factor (number): factor de multiplicación (>1 para acercar, <1 para alejar)
--   px (number): punto de referencia en coordenadas de pantalla X (opcional, por defecto centro)
--   py (number): punto de referencia en coordenadas de pantalla Y (opcional, por defecto centro)
--
-- Funcionamiento:
--   1. Calcula la nueva escala multiplicando la escala actual por el factor
--   2. Limita la nueva escala entre minZoom y maxZoom para evitar zoom extremo
--   3. Ajusta la posición del mapa para que el punto bajo el cursor permanezca fijo
--   4. Usa la fórmula matemática de zoom: new_x = px - (px - map.x) * (new_scale / old_scale)
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

-- ========================================
-- FUNCIÓN: reloadJson
-- ========================================
-- Recarga el archivo JSON de stands y categorías.
-- Reinicia el proceso de descarga y limpia los filtros.
--
-- Funcionamiento:
--   1. Resetea jsonFile para forzar recarga
--   2. Resetea jsondltimer para reiniciar la cuenta regresiva
--   3. Limpia los filtros actuales
--   4. Regresa al estado de menú para mostrar pantalla de carga
--
-- Retorna: void
local function reloadJson()
  jsonFile = 0
  jsondltimer = 0
  errorOffline = false
  filters_ui.categories = {}
  filters_data = nil
  ui_state_machine:set_state("menu")
end

function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here

  -- canvas para la tarjeta de los stands
  canvasscale = expo.scale(math.min(420, safe.w*0.9), safe.h, stand_info_top_bg_png:getWidth(), stand_info_top_bg_png:getHeight(), 1)
  canvas = love.graphics.newCanvas(stand_info_top_bg_png:getWidth(), safe.h)

  -- canvas para los filtros (scrolleable)
  -- Usar dimensiones completas de la pantalla para máxima flexibilidad
  dialog.canvas = love.graphics.newCanvas(safe.w, safe.h)


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

  -- boton de filtros
  uibuttons.register{
    get_rect = function()
      local texto = "Filtrar"
      local radius = 20 -- Usa el radio que quieras
      local text_w = font_reddit_regular_16:getWidth(texto)
      local total_w = text_w + 2 * radius
      local total_h = 2 * radius
      -- Tu fórmula original para el centro del botón:
      local cx = safe.w - 14 + floatingui.lx
      local cy = safe.h - 14 + floatingui.ly
      -- El área de toque debe ser el rectángulo que contiene el píldora, alineado a la esquina inferior derecha
      local x = cx - total_w
      local y = cy - total_h
      return x, y, total_w, total_h, texto, radius, cx, cy
    end,
    draw = function(self)
      local x, y, w, h, texto, radius, cx, cy = self.get_rect()
      -- Fondo del botón
      local bcolor = Color.button_idle
      if self.pressed then
        bcolor = Color.button_pressed
      else
        bcolor = Color.button_idle
      end
      -- Dibuja el botón igual que antes, usando ox=1, oy=1
      expo.pillbutton(cx, cy, texto, font_reddit_regular_16, bcolor, Color.text, radius, 1, 1)
    end,
    onpress = function(self)
      print("Botón Filtrar presionado")
      -- dialog_state_machine:set_state("filter")
    end,
    onrelease = function(self)
      print("Botón Filtrar presionado")
      dialog_state_machine:set_state("filter")

      -- sólo para testear:
      -- toggleCategory(filters_ui.categories["elec"])

    end
  }

  -- boton de volver al menu
  uibuttons.register{
    get_rect = function()
      local cx = safe.x + 38 - floatingui.lx
      local cy = safe.y + 38 - floatingui.ly
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
        r, g, b, a = expo.hexcolorfromstring(Color.button_pressed)
      else
        r, g, b, a = expo.hexcolorfromstring(Color.button_idle)
      end
      love.graphics.setColor(r, g, b, a)
      love.graphics.circle("fill", cx, cy, radius)
      -- Ícono (Color.text)
      r, g, b, a = expo.hexcolorfromstring(Color.text)
      love.graphics.setColor(r, g, b, a)
      local scale = 0.30
      love.graphics.draw(back_png, cx, cy, 0, scale, scale, 0.5*back_png:getWidth(), 0.5*back_png:getHeight())

    end,
    onpress = function(self)
      -- print("")
    end,
    onrelease = function(self)
      print("Botón de volver")
      ui_state_machine:set_state("menu")
    end

  }


  -- boton de recargar json
  uibuttons.register{
    get_rect = function()
      local cx = safe.x + 38 - floatingui.lx + 38*2
      local cy = safe.y + 38 - floatingui.ly
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
        r, g, b, a = expo.hexcolorfromstring(Color.button_pressed)
      else
        r, g, b, a = expo.hexcolorfromstring(Color.button_idle)
      end
      love.graphics.setColor(r, g, b, a)
      love.graphics.circle("fill", cx, cy, radius)
      -- Ícono (Color.text)
      r, g, b, a = expo.hexcolorfromstring(Color.text)
      love.graphics.setColor(r, g, b, a)
      local scale = 0.30
      love.graphics.draw(reload_png, cx, cy, 0, scale, scale, 0.5*reload_png:getWidth(), 0.5*reload_png:getHeight())

    end,
    onpress = function(self)
      -- print("")
    end,
    onrelease = function(self)
      print("recargar json!")
      reloadJson()
      -- ui_state_machine:set_state("menu") -- esto lo hará automáticamente el reloadJson()
    end

  }

  overlayStats.load() -- Should always be called last
end

function love.update(dt)
  -- lovebird
  if debug then
    require("lib.lovebird").update()
  end

  -- si dt es demasiado alto, limitarlo a 0.07.
  if dt > 0.07 then
    dt = 0.07
  end


  -- safearea
  -- safe.x, safe.y, safe.w, safe.h = love.window.getSafeArea()

  ui_state_machine:update(dt)
  dialog_state_machine:update(dt)
  -- if ui_state_machine:in_state("menu") then
  --   dialog_state_machine:set_state("idle")
  -- end
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


  -- dibujar botones
  uibuttons.draw()

end

function love.draw()
  -- Your game draw here
  love.graphics.push()
  love.graphics.setColor(1, 1, 1, 1) -- setear el color a blanco

  love.graphics.setFont(font_reddit_regular_16) -- setear la fuente por defecto
  local r, g, b, a = expo.hexcolorfromstring(Color.background)
  love.graphics.setBackgroundColor(r, g, b, a) -- setear el background a negro
  love.graphics.translate(safe.x, safe.y) -- translatear a safe_x y safe_y
  ui_state_machine:draw()

  draw_always_shown_content()

  dialog_state_machine:draw()

	-- draw headerbar if on a supported platform
	if (love.system.getOS() == "Linux" or love.system.getOS() == "Windows" or love.system.getOS() == "MacOS") and experimentalheader == true then
		local r,g,b,a = expo.hexcolorfromstring(Color.button_idle)
		love.graphics.setColor(r,g,b,a)
		love.graphics.rectangle("fill", headerbar.x, headerbar.y, headerbar.w, headerbar.h)

		local r,g,b,a = expo.hexcolorfromstring(Color.background)
		love.graphics.setColor(r,g,b,a)
		love.graphics.draw(headerbar.png, headerbar.x+headerbar.padding, headerbar.y, 0, safe.w-headerbar.x -headerbar.padding*2, 1)
  end
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
	elseif key == "3" then
		love.window.setPosition(10, 10)
  end
end


local function handlepressed(id, x, y, button, istouch)
  -- ========================================
  -- PROCESAR ENTRADA DE BOTONES DE UI
  -- ========================================
  local pressed_button = uibuttons.handle_press(x - safe.x, y - safe.y)

  -- Notificar a las máquinas de estado sobre la entrada
  ui_state_machine:handle_press()
  dialog_state_machine:handle_press()

  -- ========================================
  -- MANEJAR ENTRADA EN DIÁLOGO DE FILTROS
  -- ========================================
  if dialog_state_machine:in_state("filter") then
    -- Marcar que se presionó el botón (para arrastre)
    dialog.is_pressed = true

    -- Dimensiones del canvas de filtros (deben coincidir con draw y handlemoved)
    local content_x = dialog.content_x
    local content_y = dialog.content_y
    local content_w = dialog.content_width
    local content_h = dialog.content_height
    local radius = 24

    -- ========================================
    -- DETECTAR CLICS EN BOTONES DEL HEADER
    -- ========================================
    local radius = 24

    -- Botón "Reestablecer Filtros" - ubicado en el centro superior
    -- Las dimensiones se basan en el dibujado en expo.dialog()
    local reset_btn_y = dialog.y + radius * 3
    local reset_btn_h = radius * 1.5
    local reset_btn_text = "Reestablecer Filtros"
    local reset_btn_w = font_reddit_regular_16:getWidth(reset_btn_text) + 2 * 18
    local reset_btn_x = safe.w * 0.5 - reset_btn_w * 0.5

    if expo.inrange(x, reset_btn_x, reset_btn_x + reset_btn_w) and
       expo.inrange(y, reset_btn_y, reset_btn_y + reset_btn_h) then
      pressed_dialog_button = "reset_filters"
      return
    end

    -- Botón de modo toggle (Incluir/Excluir)
    -- Se encuentra en una línea debajo del botón de reset
    local toggle_y = dialog.y + radius * 4 + 4
    local toggle_h = radius * 1.5
    local toggle_bg_x = 30
    local toggle_bg_w = safe.w - 60

    -- El toggle switch está dentro del background box
    -- Calcular la posición del switch basada en el código de dibujo
    local switch_w = 50
    local switch_padding = 8
    local incluir_text_w = font_reddit_regular_16:getWidth("Incluir")
    local excluir_text_w = font_reddit_regular_16:getWidth("Excluir")

    -- Posición del switch en el centro de la caja
    local switch_x = safe.w - 30 - radius + 4 - excluir_text_w - switch_w / 2 - switch_padding
    local switch_center = switch_x + switch_w / 2

    if expo.inrange(x, toggle_bg_x, toggle_bg_x + toggle_bg_w) and
       expo.inrange(y, toggle_y, toggle_y + toggle_h) then
      pressed_dialog_button = "toggle_mode"
      return
    end

    -- Detectar si está dentro del área del canvas
    if expo.inrange(x, content_x, content_x + content_w) and
       expo.inrange(y, content_y, content_y + content_h) then

      -- Convertir coordenadas a coordenadas del canvas (incluyendo scroll)
      local local_x = x - content_x
      local local_y = (y - content_y) + dialog.scroll_y

      -- ========================================
      -- DETECTAR CLICK EN CATEGORÍA
      -- ========================================
      for _, btn in ipairs(dialog.buttons.categories) do
        if expo.inrange(local_x, btn.x, btn.x + btn.w) and
           expo.inrange(local_y, btn.y, btn.y + btn.h) then
          -- Registrar qué botón fue presionado (ejecutar en release)
          pressed_filter_button = {type = "category", id = btn.id}
          return
        end
      end

      -- ========================================
      -- DETECTAR CLICK EN STAND
      -- ========================================
      for _, btn in ipairs(dialog.buttons.stands) do
        if expo.inrange(local_x, btn.x, btn.x + btn.w) and
           expo.inrange(local_y, btn.y, btn.y + btn.h) then
          -- Registrar qué botón fue presionado (ejecutar en release)
          pressed_filter_button = {
            type = "stand",
            category_id = btn.category_id,
            stand_id = btn.stand_id
          }
          return
        end
      end

      return
    end

    -- Detectar si el toque está fuera del diálogo
    if expo.inrange(x, 0, safe.w) and expo.inrange(y, 0, dialog.y) then
      dialog_closing = true
    else
      dialog_closing = false
      -- Detectar si está en el header para arrastrarlo
      if expo.inrange(y, dialog.y, dialog.y + dialog.borderheight) then
        dialog.dragging = true
      end
    end

    return
  end

  -- ========================================
  -- LÓGICA DE DEBUG: MOSTRAR COORDENADAS
  -- ========================================
  if debug then
    -- Convertir coordenadas de pantalla a coordenadas lógicas del mapa (-1000 a 1000)
    -- 1. Ajustar por el offset y escala del mapa
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

  -- ========================================
  -- MANEJAR ENTRADA EN ESTADO MAP
  -- ========================================
  if ui_state_machine:in_state("map") then
    -- Guardar la posición inicial del toque para detectar arrastres
    drag_start_x = x
    drag_start_y = y
    did_drag = false

    -- Solo permitir arrastrar el mapa si:
    -- 1. NO se tocó un botón de UI
    -- 2. NO es un toque táctil (mouse puede arrastrar)
    if not pressed_button and not istouch then
      expoguia_map.allowdrag = true
    end
  end

end

local function handlemoved(id, x, y, dx, dy, istouch)
  -- ========================================
  -- NOTIFICAR A MÁQUINAS DE ESTADO
  -- ========================================
  ui_state_machine:handle_moved()
  dialog_state_machine:handle_moved()

  if debug then
    -- print("moved: " .. id .. " x,y: " .. x .. "," .. y .. " dx,dy: " .. dx .. "," .. dy)
  end

  -- ========================================
  -- MANEJAR SCROLL Y ARRASTRE DEL DIÁLOGO DE FILTROS
  -- ========================================
  if dialog_state_machine:in_state("filter") and dialog.is_pressed then
    local content_x = dialog.content_x
    local content_y = dialog.content_y
    local content_w = dialog.content_width
    local content_h = dialog.content_height

    -- Manejar arrastre del diálogo desde el header
    if dialog.dragging then
      -- Mover el diálogo verticalmente
      local multiplier = istouch and touchmultiplier or 1
      dialog.y = dialog.y + dy * multiplier
      if dialog.y < dialog.min_y then
        dialog.y = dialog.min_y
      elseif dialog.y > dialog.max_y then
        dialog.y = dialog.max_y
      end
      return  -- Salir para no procesar más lógica
    end

    -- Si el scroll ya comenzó, permitir continuar sin restricciones de posición
    if dialog.scroll_started then
      -- Scroll vertical del contenido
      local max_scroll = math.max(0, dialog.buttons.content_height - content_h)
      dialog.scroll_y = math.min(max_scroll, math.max(0, dialog.scroll_y - dy))
      return  -- Salir para no procesar más lógica
    end

    -- Detectar si está dentro del área del canvas (para iniciar scroll)
    -- Solo permitir INICIAR scroll si el toque está dentro del canvas
    if expo.inrange(x, content_x, content_x + content_w) and
       expo.inrange(y, content_y, content_y + content_h) then
      -- Marcar que el scroll ha comenzado
      dialog.scroll_started = true
      -- Scroll vertical del contenido
      local max_scroll = math.max(0, dialog.buttons.content_height - content_h)
      dialog.scroll_y = math.min(max_scroll, math.max(0, dialog.scroll_y - dy))
      return  -- Salir para no procesar más lógica
    end

    return
  end

  -- ========================================
  -- DETECTAR SI SE ESTÁ ARRASTRANDO
  -- ========================================
  -- Calcular distancia recorrida desde el inicio del toque
  if not did_drag then
    local dist = math.abs(x - drag_start_x) + math.abs(y - drag_start_y)
    -- Usar distancia de Manhattan (suma de diferencias absolutas)
    -- Es más eficiente que calcular la distancia euclidiana (sqrt)
    if dist > 10 then -- umbral de 10 píxeles para considerar que se está arrastrando
      did_drag = true
    else
      did_drag = false
    end
  end

  -- ========================================
  -- MANEJAR ARRASTRE DEL MAPA
  -- ========================================
  -- Si estamos en el estado de mapa y el arrastre está habilitado
  if ui_state_machine:in_state("map") and expoguia_map.allowdrag then
    local multiplier = istouch and touchmultiplier or 1
    expoguia_map.x = expoguia_map.x + dx * multiplier
    expoguia_map.y = expoguia_map.y + dy * multiplier
  end
end

local function handlereleased(id, x, y, button, istouch)
  -- ========================================
  -- NOTIFICAR A MÁQUINAS DE ESTADO
  -- ========================================
  -- Informar a las máquinas de estado que se liberó la entrada
  ui_state_machine:handle_release()
  dialog_state_machine:handle_release()

  -- ========================================
  -- PROCESAR LIBERACIÓN DE BOTONES DE UI
  -- ========================================
  -- Detectar si se liberó un botón de UI y ejecutar su callback
  local released_button = uibuttons.handle_release(x - safe.x, y - safe.y)

  -- Si se procesó un botón de UI, salir sin procesar más lógica
  if released_button then
    return
  end

  if debug then
    -- print("released: " .. id .. " x,y: " .. x .. "," .. y .. " button: " .. button)
  end

  -- ========================================
  -- MANEJAR LIBERACIÓN EN DIÁLOGO DE FILTROS
  -- ========================================
  if dialog_state_machine:in_state("filter") then
    -- Marcar que se liberó el botón
    dialog.is_pressed = false

    -- Si había un botón del diálogo presionado, ejecutar la acción
    if pressed_dialog_button then
      if pressed_dialog_button == "reset_filters" then
        resetFilters()
      elseif pressed_dialog_button == "toggle_mode" then
        toggleFilterMode()
      end
    end

    -- Limpiar el registro del botón del diálogo
    pressed_dialog_button = nil

    -- Si había un botón de filtro presionado y NO hubo scroll, ejecutar la acción
    if pressed_filter_button and not dialog.scroll_started then
      if pressed_filter_button.type == "category" then
        local cat_ui = filters_ui.categories[pressed_filter_button.id]
        toggleCategory(cat_ui)
      elseif pressed_filter_button.type == "stand" then
        local cat_ui = filters_ui.categories[pressed_filter_button.category_id]
        toggleStand(cat_ui, pressed_filter_button.stand_id)
      end
    end

    -- Limpiar el registro del botón presionado
    pressed_filter_button = nil

    if dialog.dragging then
      -- Si estábamos arrastrando el diálogo, dejar de hacerlo
      dialog.dragging = false
    elseif not dialog.scroll_started and
           expo.inrange(x, 0, safe.w) and
           expo.inrange(y, 0, dialog.y) and
           dialog_closing then
      -- Si tocamos fuera del diálogo, NO estábamos scrolleando, y puede cerrarse
      dialog_state_machine:set_state("idle")
    end

    -- Resetear el flag de scroll sin importar qué pasó
    dialog.scroll_started = false
  end

  -- ========================================
  -- MANEJAR TRANSICIÓN DESDE MENÚ
  -- ========================================
  if ui_state_machine:in_state("menu") then
    -- Si estamos en el menú y el JSON se cargó correctamente, ir al mapa
    if not errorOffline and jsonFile ~= 0 then
      ui_state_machine:set_state("map")
    end
  end

  -- ========================================
  -- MANEJAR ENTRADA EN ESTADO MAPA
  -- ========================================
  if ui_state_machine:in_state("map") then
    -- Si es entrada de mouse (no táctil), deshabilitar arrastre del mapa
    if not istouch then
      expoguia_map.allowdrag = false
    end

    -- Detectar si se tocó un stand en estas coordenadas
    -- Se suma un offset Y para ajustar por la altura de la textura del stand
    local stand = get_stand_at_point(x - safe.x, y - safe.y + stand_electro_png:getHeight()*0.1)
    -- Si se tocó un stand Y no se arrastró (movimiento mínimo)
    if stand and not did_drag then
      -- Seleccionar el stand y mostrar su tarjeta informativa
      selected_stand = stand
    else
      -- Si se arrastró o no se tocó un stand, deseleccionar
      selected_stand = nil
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
  -- Recrear el canvas con las nuevas dimensiones
  if dialog.canvas then
    dialog.canvas:release()
  end
  dialog.canvas = love.graphics.newCanvas(safe.w, safe.h)
end
