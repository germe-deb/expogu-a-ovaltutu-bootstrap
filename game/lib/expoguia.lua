-- SPDX-FileCopyrightText: 2025 germe-deb <dpkg.luci@protonmail.com>
--
-- SPDX-License-Identifier: GPL-3.0-or-later

local Color = require "lib/colors"
-- ========================================
-- LIBRERÍA: expoguia
-- ========================================
-- Librería de utilidades y funciones UI creada específicamente para ExpoGuía.
-- Contiene funciones para:
--   - Cálculo de escalas y centrado
--   - Interpolación y animación (lerp)
--   - Conversión de colores (hex -> RGB)
--   - Utilidades matemáticas (rango)
--   - Componentes UI (botones, toggle, diálogos)
--   - Renderizado de tarjetas de stands
--
-- Estilo: Funciona como una librería con tabla public (local expo = {})
-- Todas las funciones se acceden como expo.nombreFuncion()
local expo = {}

-- ========================================
-- FUNCIÓN: centered
-- ========================================
-- Centra un objeto dentro de un contenedor, calculando los offsets necesarios.
-- Útil para posicionar elementos de forma relativa al contenedor.
--
-- Parámetros:
--   contW (number): ancho del contenedor
--   contH (number): alto del contenedor
--   objW (number): ancho del objeto a centrar
--   objH (number): alto del objeto a centrar
--   aliX (number, opcional): alineación horizontal (0=izquierda, 0.5=centro, 1=derecha; default=0.5)
--   aliY (number, opcional): alineación vertical (0=arriba, 0.5=centro, 1=abajo; default=0.5)
--
-- Retorna: offX, offY - Desplazamientos en X e Y para alinear el objeto
--
-- Ejemplo:
--   local offX, offY = expo.centered(800, 600, 200, 100, 0.5, 0.5)
--   love.graphics.draw(image, offX, offY)
function expo.centered(contW, contH, objW, objH, aliX, aliY)
  -- Por defecto alinear al centro en X y Y
  aliX = aliX or 0.5
  aliY = aliY or 0.5

  -- Calcular desplazamiento: qué tan lejos está el objeto del origen
  -- Si aliX=0, está en la izquierda; si aliX=1, está en la derecha
  local offX = (contW - objW) * aliX
  local offY = (contH - objH) * aliY

  return offX, offY
end

-- ========================================
-- FUNCIÓN: scale
-- ========================================
-- Calcula el factor de escala para que un objeto quepa dentro de un contenedor.
-- Útil para escalar imágenes, textos, o cualquier elemento para que se ajuste
-- al espacio disponible manteniendo su proporción.
--
-- Parámetros:
--   contW (number): ancho del contenedor
--   contH (number): alto del contenedor
--   objW (number): ancho del objeto original
--   objH (number): alto del objeto original
--   scale (number, opcional): escala adicional (default=1)
--     - 0.5: el objeto ocupará el 50% del contenedor
--     - 1.0: el objeto ocupará el 100% del contenedor
--     - 1.5: el objeto ocupará el 150% del contenedor (puede salirse)
--
-- Retorna: number - factor de escala a aplicar al objeto
--
-- Ejemplo:
--   local scaleFactor = expo.scale(800, 600, 400, 300, 0.9)
--   love.graphics.draw(image, x, y, 0, scaleFactor, scaleFactor)
function expo.scale(contW, contH, objW, objH, scale)
  scale = scale or 1
  -- Calcular qué escala se necesita en X e Y para encajar el objeto
  local scaleX = contW / objW
  local scaleY = contH / objH
  -- Usar el escala menor para asegurar que encaja en ambas dimensiones
  -- Luego aplicar la escala adicional solicitada por el usuario
  local scaleFactor = math.min(scaleX, scaleY) * scale
  return scaleFactor
end

-- ========================================
-- FUNCIÓN: automate_stand_id
-- ========================================
-- Automatiza la asignación de IDs a los stands basándose en su posición en la tabla.
-- Útil cuando los stands se cargan desde JSON sin IDs predefinidos.
--
-- Parámetros:
--   stand_table (table): tabla de stands a los que se asignarán IDs
--
-- Retorna: table - la misma tabla con los IDs actualizados
--
-- Funcionamiento:
--   - Recorre cada stand en la tabla
--   - Asigna como ID el índice de la tabla (1, 2, 3, ...)
--   - Retorna la tabla actualizada
--
-- Ejemplo:
--   stands = json.decode(json_string)
--   stands = expo.automate_stand_id(stands)  -- Ahora cada stand tiene stand.id = posición
function expo.automate_stand_id(stand_table)
    for i, stand in ipairs(stand_table) do
        stand.id = i
    end
    return stand_table
end

-- ========================================
-- FUNCIÓN: centeredtext
-- ========================================
-- Dibuja texto centrado en un contenedor con opciones de estilo.
-- Permite aplicar estilos especiales como enmarcar el texto.
--
-- Parámetros:
--   texto (string): texto a dibujar
--   alix (number): alineación horizontal (0=izquierda, 0.5=centro, 1=derecha)
--   aliy (number): alineación vertical (0=arriba, 0.5=centro, 1=abajo)
--   fuente (love.Font): fuente a usar
--   style (string, opcional): estilo ("normal", "bold", "italic", "enmarked"; default="normal")
--   contW (number, opcional): ancho del contenedor (default=safe.w)
--   contH (number, opcional): alto del contenedor (default=safe.h)
--
-- Ejemplo:
--   expo.centeredtext("Hola", 0.5, 0.5, font, "enmarked", 800, 600)
function expo.centeredtext(texto, alix, aliy, fuente, style, contW, contH)
    love.graphics.push()
    love.graphics.setFont(fuente)

	local color1, color2, color3, color4 = love.graphics.getColor()
    -- centrado
	local w, h
    local _, _, safe_w, safe_h = love.window.getSafeArea()

	w = contW or safe_w
	h = contH or safe_h
	local offsetx, offsety = expo.centered(w, h, fuente:getWidth(texto), fuente:getHeight(), alix, aliy)


    if style == "normal" or style == nil then end
    if style == "bold" then end
    if style == "italic" then end
    if style == "enmarked" then
		love.graphics.push()
		-- 24 38 47
		love.graphics.setColor(24/255, 38/255, 47/255, 0.75)

		local boxoffsetx, boxoffsety = offsetx - 0.4*fuente:getHeight(), offsety - 0.25*fuente:getHeight()
		local boxwidth = fuente:getWidth(texto) + 0.8*fuente:getHeight()
		local boxheight = fuente:getHeight() + 0.5*fuente:getHeight()
		love.graphics.rectangle("fill", boxoffsetx, boxoffsety, boxwidth, boxheight)
		love.graphics.pop()
    end
    -- if style == fancy then end
	love.graphics.setColor(color1, color2, color3, color4)

	love.graphics.translate(math.floor(offsetx), math.floor(offsety))
    love.graphics.print(texto)
    love.graphics.pop()
end

-- ========================================
-- FUNCIÓN: dialog
-- ========================================
-- Dibuja un diálogo modal con headerbar redondeada y contenido personalizable.
-- Actualmente soporta el tipo "filtros" para mostrar la interfaz de filtros.
--
-- Parámetros:
--   x (number): posición x del diálogo
--   y (number): posición y del diálogo
--   safe (table): tabla de dimensiones seguras (x, y, w, h)
--   content (table): tabla con configuración del contenido
--     - windowtype (string): tipo de diálogo ("filtros", etc.)
--     - mode (string): modo de filtrado ("include" o "exclude")
--   stands (table): tabla de stands (para futuras funcionalidades)
--   font_title (love.Font): fuente para títulos
--   font_normal (love.Font): fuente normal
--   color (table): tabla de colores disponibles
--   filter_mode (string): modo de filtrado actual ("include" o "exclude")
--
-- Ejemplo:
--   local content = { windowtype = "filtros", mode = "include" }
--   expo.dialog(0, dialog.y, safe, content, stands, font_big, font_normal, Color, filters_ui,
--               filters_data, toggleCategoryFn, toggleStandFn, filter_mode)
function expo.dialog(x, y, safe, content, stands, font_title, font_normal, color, filters_ui,
                     filters_data, toggleCategoryFn, toggleStandFn, filter_mode)
    love.graphics.push()
    local radius = 24
    local title_h = radius * 2

    -- dibujar la ventana
    local r, g, b, a = expo.hexcolorfromstring(Color.background)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", x, y + title_h, safe.w, safe.h)

    -- dibujar la headerbar
    r, g, b, a = expo.hexcolorfromstring(Color.foreground_light)
    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", x + radius, y + radius, radius)
    love.graphics.circle("fill", safe.w - radius, y + radius, radius)
    love.graphics.rectangle("fill", x + radius, y, safe.w - radius * 2, title_h)

    if content.windowtype == "filtros" then
      love.graphics.rectangle("fill", x, y + radius, safe.w, title_h - radius + 4 * radius)

      love.graphics.setFont(font_title)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print("Filtros", safe.w * 0.5, y + title_h / 2, 0, 1, 1, font_title:getWidth("Filtros") * 0.5, font_title:getHeight() * 0.5)

      love.graphics.setFont(font_normal)
      -- botones de la header
      expo.pillbutton(safe.w * 0.5, y + radius * 3, "Reestablecer Filtros", font_normal, Color.reestablecer, Color.text, 18, 0.5, 0.5)

      -- custom toggle para alternar incluir o excluir
      local r, g, b, a = expo.hexcolorfromstring(Color.button_idle)
      love.graphics.setColor(r, g, b, a)
      love.graphics.rectangle("fill", x + 30, y + radius * 4 + 4, safe.w - 60, radius * 1.5, radius * 0.75)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print("Modo:", x + 30 + radius - 4, y + radius * 4.75 + 4, 0, 1, 1, 0, font_normal:getHeight() * 0.5)
      love.graphics.print("Excluir", safe.w - 30 - radius + 4, y + radius * 4.75 + 4, 0, 1, 1, font_normal:getWidth("Excluir"), font_normal:getHeight() * 0.5)

      local switch_w = 50
      local switch_h = 25
      local padding = 8
      love.graphics.print("Incluir", safe.w - 30 - radius + 4 - font_normal:getWidth("Excluir") - switch_w - padding * 2, y + radius * 4.75 + 4, 0, 1, 1, font_normal:getWidth("Incluir"), font_normal:getHeight() * 0.5)

      -- Dibujar el toggle basado en filter_mode
      if filter_mode == "include" then
        expo.drawtoggle(safe.w - 30 - radius + 4 - font_normal:getWidth("Excluir") - switch_w / 2 - padding, y + radius * 4.75 + 4, true, 0.5, 0.5, false)
      else
        expo.drawtoggle(safe.w - 30 - radius + 4 - font_normal:getWidth("Excluir") - switch_w / 2 - padding, y + radius * 4.75 + 4, false, 0.5, 0.5, false)
      end
    else
      love.graphics.rectangle("fill", x, y + radius, safe.w, title_h - radius)
    end
    love.graphics.pop()
end

-- ========================================
-- FUNCIONES DE INTERPOLACIÓN (Lerp)
-- ========================================
-- Las funciones de interpolación permiten crear animaciones suaves entre dos valores.
-- Todas siguen el patrón: resultado = inicio + (destino - inicio) * t
--   Donde t es un valor entre 0 y 1 (0=inicio, 1=destino)
--
-- Tipos de interpolación:
--   - Linear: velocidad constante
--   - EaseIn: comienza lento, termina rápido (acelera)
--   - EaseOut: comienza rápido, termina lento (desacelera)
--   - EaseInOut: suave en ambos extremos

-- ========================================
-- FUNCIÓN: lerp (Linear)
-- ========================================
-- Interpolación lineal: velocidad constante
-- Parámetros:
--   a (number): posición inicial/actual
--   b (number): posición destino
--   t (number): progreso (0 a 1)
--
-- Ejemplo:
--   Para animar de 0 a 100 en 1 segundo:
--   local value = expo.lerp(0, 100, elapsed_time / 1.0)
function expo.lerp(a, b, t)
    return a + (b - a) * t
end

-- ========================================
-- FUNCIÓN: lerpin (EaseIn)
-- ========================================
-- Interpolación con aceleración: comienza lento, termina rápido
-- Útil para entradas suaves que aceleran al final (ej: objeto que cae)
--
-- Parámetros:
--   a (number): posición inicial/actual
--   b (number): posición destino
--   t (number): progreso (0 a 1)
function expo.lerpin(a, b, t)
    return a + (b - a) * (t * t)
end

-- ========================================
-- FUNCIÓN: lerpout (EaseOut)
-- ========================================
-- Interpolación con desaceleración: comienza rápido, termina lento
-- Útil para salidas suaves que se ralentizan al final (ej: objeto que se detiene)
--
-- Parámetros:
--   a (number): posición inicial/actual
--   b (number): posición destino
--   t (number): progreso (0 a 1)
function expo.lerpout(a, b, t)
    return a + (b - a) * (t * (2 - t))
end

-- ========================================
-- FUNCIÓN: lerpinout (EaseInOut)
-- ========================================
-- Interpolación suave en ambos extremos: aceleración al inicio, desaceleración al final
-- Útil para animaciones que se sienten naturales (ej: UI que entra y sale)
--
-- Parámetros:
--   a (number): posición inicial/actual
--   b (number): posición destino
--   t (number): progreso (0 a 1)
function expo.lerpinout(a, b, t)
    t = t * 2
    if t < 1 then
        return a + (b - a) * (0.5 * t * t)
    else
        t = t - 1
        return a + (b - a) * (0.5 * (1 - t * (2 - t)) + 0.5)
    end
end

-- ========================================
-- FUNCIONES DE CONVERSIÓN DE COLORES
-- ========================================
-- Convierten entre formato hexadecimal (#RRGGBBAA) y RGBA (0-1, 0-1, 0-1, 0-1)
-- Útil para trabajar con colores definidos en JSON y usarlos en LÖVE

-- ========================================
-- FUNCIÓN: hexcolor
-- ========================================
-- Convierte un número entero hexadecimal a componentes RGBA (0-1)
--
-- Parámetros:
--   int (number): número entero en formato hex (ej: 0xFF0000FF para rojo opaco)
--
-- Retorna: r, g, b, a - Componentes en rango 0-1
--
-- Ejemplo:
--   local r, g, b, a = expo.hexcolor(0xFF0000FF)  -- Retorna: 1, 0, 0, 1 (rojo opaco)
function expo.hexcolor(int)
  return bit.band(bit.rshift(int, 24), 255)/255,
  bit.band(bit.rshift(int, 16), 255)/255,
  bit.band(bit.rshift(int, 8), 255)/255,
  bit.band(int, 255)/255
end

-- ========================================
-- FUNCIÓN: hexcolorfromstring
-- ========================================
-- Convierte un string hexadecimal a componentes RGBA (0-1)
-- Formato esperado: "#RRGGBBAA" o "#RRGGBB"
--
-- Parámetros:
--   str (string): color en formato hex (ej: "#FF0000FF" para rojo opaco)
--
-- Retorna: r, g, b, a - Componentes en rango 0-1
--
-- Ejemplo:
--   local r, g, b, a = expo.hexcolorfromstring("#3746d0ff")  -- Azul oscuro
--   love.graphics.setColor(r, g, b, a)
function expo.hexcolorfromstring(str)
  if not str then
    return 0, 0, 0, 1 -- Color negro por defecto si str es nil
  end
  local int = str:match('#(%x+)')
  return expo.hexcolor( tonumber(int, 16) )
end


-- ========================================
-- FUNCIÓN: inrange
-- ========================================
-- Verifica si un valor está dentro de un rango (entre dos números).
-- Reemplaza la lógica: if var >= a and var <= b then
--
-- Parámetros:
--   var (number): valor a verificar
--   a (number): límite inferior del rango (inclusive)
--   b (number): límite superior del rango (inclusive)
--
-- Retorna: boolean - true si var está en el rango [a, b], false en caso contrario
--
-- Ejemplo:
--   if expo.inrange(100, 50, 150) then  -- true
--     print("El valor está en el rango")
--   end
function expo.inrange(var, a, b)
  return var >= a and var <= b
end

-- ========================================
-- FUNCIÓN: pillbutton
-- ========================================
-- Dibuja un botón tipo píldora (rectángulo con extremos redondeados).
-- El nombre "píldora" viene de su forma: rectángulo con círculos en los extremos.
-- Este estilo es muy popular en UI moderna.
--
-- Parámetros:
--   x (number): posición x del pivote del botón
--   y (number): posición y del pivote del botón
--   texto (string): texto a mostrar en el botón
--   fuente (love.Font): fuente a usar para el texto
--   bg_color (string): color de fondo en formato "#RRGGBBAA"
--   text_color (string): color del texto en formato "#RRGGBBAA"
--   radius (number, opcional): radio de los extremos redondeados (default=10)
--   ox (number, opcional): pivote horizontal (0=izquierda, 0.5=centro, 1=derecha; default=0)
--   oy (number, opcional): pivote vertical (0=arriba, 0.5=centro, 1=abajo; default=0)
--
-- Ejemplo:
--   expo.pillbutton(400, 300, "Aceptar", font, "#FF6B6Bff", "#FFFFFFff", 20, 0.5, 0.5)
--   -- Dibuja un botón rojo centrado en (400, 300) con texto blanco
function expo.pillbutton(x, y, texto, fuente, bg_color, text_color, radius, ox, oy)
  ox = ox or 0
  oy = oy or 0
  love.graphics.setFont(fuente)
  local segment = 200  -- número de segmentos para los círculos (más = más suave)
  local text_w = fuente:getWidth(texto)
  local text_h = fuente:getHeight()

  -- Calcular dimensiones totales del botón
  local total_w = radius * 2 + text_w
  local total_h = radius * 2

  -- Ajustar posición para que los pivotes funcionen correctamente
  x = x - ox * total_w
  y = y - oy * total_h

  -- Dibujar fondo del botón
  local r, g, b, a = expo.hexcolorfromstring(bg_color)
  love.graphics.setColor(r, g, b, a)
  -- Rectángulo central (la parte recta del botón)
  love.graphics.rectangle("fill", x + radius, y, text_w, total_h)
  -- Círculo izquierdo (extremo izquierdo redondeado)
  love.graphics.circle("fill", x + radius, y + radius, radius, segment)
  -- Círculo derecho (extremo derecho redondeado)
  love.graphics.circle("fill", x + radius + text_w, y + radius, radius, segment)

  -- Dibujar el texto (centrado verticalmente)
  r, g, b, a = expo.hexcolorfromstring(text_color)
  love.graphics.setColor(r, g, b, a)
  love.graphics.print(texto, x + radius, y + (total_h - text_h) / 2)
end

-- ========================================
-- FUNCIÓN: drawtoggle
-- ========================================
-- Dibuja un switch (toggle) interactivo que representa un estado on/off.
-- El switch tiene un fondo rectangular y un círculo que se desliza.
--
-- Parámetros:
--   x (number): posición x del centro del toggle
--   y (number): posición y del centro del toggle
--   state (boolean): estado actual (true=encendido, false=apagado)
--   ox (number, opcional): pivote horizontal (0, 0.5, 1; default=0)
--   oy (number, opcional): pivote vertical (0, 0.5, 1; default=0)
--   colors (boolean, opcional): si true, usa colores verde/rojo según estado (default=false)
--
-- Ejemplo:
--   expo.drawtoggle(200, 100, true, 0.5, 0.5, true)
--   -- Dibuja un toggle centrado, activo (verde), con pivote centrado
function expo.drawtoggle(x, y, state, ox, oy, colors)
  ox = ox or 0
  oy = oy or 0
  colors = colors or false
  local w = 50
  local h = 25
  local radius = h / 2

  -- Dibujar el fondo del toggle
  if colors then
    if state then
      -- Verde para estado activo (on)
      local r, g, b, a = expo.hexcolorfromstring(Color.greentoggle)
      love.graphics.setColor(r, g, b, a)
    else
      -- Rojo para estado inactivo (off)
      local r, g, b, a = expo.hexcolorfromstring(Color.redtoggle)
      love.graphics.setColor(r, g, b, a)
    end
  else
    -- Color por defecto si no se especifican colores
    local r, g, b, a = expo.hexcolorfromstring(Color.button_pressed)
    love.graphics.setColor(r, g, b, a)
  end
  -- Dibujar el rectángulo de fondo con extremos redondeados
  love.graphics.rectangle("fill", x - ox * w, y - oy * h, w, h, radius)

  -- Dibujar el círculo del toggle (color blanco)
  love.graphics.setColor(1,1,1,1)
  -- Si el estado es false (off), el círculo está a la izquierda
  if state == false then
    x = x - w/2
  end
  -- El círculo se dibuja en el center o hacia la derecha dependiendo del estado
  love.graphics.circle("fill", x+radius, y, radius*0.8)

end

-- ========================================
-- FUNCIÓN: draw_stand
-- ========================================
-- Dibuja la tarjeta informativa de un stand seleccionado.
-- La tarjeta tiene tres secciones:
--   1. Encabezado (top): Muestra el curso/especialidad con color de la especialidad
--   2. Medio: Información del stand (título, profesor)
--   3. Pie (bottom): Decorativo con color de la especialidad
--
-- Parámetros:
--   stand (table): objeto del stand con propiedades:
--     - especialidad (string): código de especialidad (E, C, IPP, ESC, BH, BM, etc.)
--     - texto (string): título del stand
--     - curso (string, opcional): número de curso
--     - profesor (string, opcional): nombre del profesor
--   safe (table): tabla con dimensiones seguras de pantalla (x, y, w, h)
--   stand_info_*_png (love.Image): texturas de la tarjeta (top_bg, top_fg, bottom_bg, bottom_fg)
--   font_small (love.Font): fuente pequeña para etiquetas
--   font_curso (love.Font): fuente grande para el curso
--   font_title (love.Font): fuente muy grande para el título
--
-- Ejemplo:
--   expo.draw_stand(selected_stand, safe, top_bg, top_fg, bot_bg, bot_fg, f_small, f_curso, f_title)
function expo.draw_stand(stand, safe, stand_info_top_bg_png, stand_info_top_fg_png, stand_info_bottom_bg_png, stand_info_bottom_fg_png, font_small, font_curso, font_title)

  canvasscale = expo.scale(math.min(420, safe.w*0.9), safe.h, stand_info_top_bg_png:getWidth(), stand_info_top_bg_png:getHeight(), 1)

  -- Usar un canvas para renderizar la tarjeta completa
  -- Esto permite mejor control de la composición y mejora el rendimiento
  love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setBlendMode("alpha")

    -- ========================================
    -- SELECCIONAR COLOR SEGÚN ESPECIALIDAD
    -- ========================================
    -- Cada especialidad tiene un color único que se usa en la tarjeta
    local r, g, b, a
    if stand.especialidad == "E" then
      -- Electromecánica: Azul
      r, g, b, a = expo.hexcolorfromstring("#3746d0ff")
    elseif stand.especialidad == "C" then
      -- Construcciones: Naranja
      r, g, b, a = expo.hexcolorfromstring("#cf781dff")
    elseif stand.especialidad == "IPP" then
      -- Informática: Cian
      r, g, b, a = expo.hexcolorfromstring("#24a7aaff")
    elseif stand.especialidad == "ESC" then
      -- Escape: Verde
      r, g, b, a = expo.hexcolorfromstring("#0e8d0aff")
    elseif stand.especialidad == "BH" or stand.especialidad == "BM" then
      -- Baños: Gris azulado
      r, g, b, a = expo.hexcolorfromstring("#475864ff")
    elseif stand.especialidad == "expoguia" then
      -- ExpoGuía: Negro
      r, g, b, a = expo.hexcolorfromstring("#212121ff")
    else
      -- Ciclo Básico: Verde
      r, g, b, a = expo.hexcolorfromstring("#28a06eff")
    end

    -- ========================================
    -- DIBUJAR SECCIÓN SUPERIOR (ENCABEZADO)
    -- ========================================
    -- Calcular escala de la tarjeta para que quepa en el canvas
    local scale = expo.scale(canvas:getWidth(), canvas:getHeight(), stand_info_top_bg_png:getWidth(), stand_info_top_bg_png:getHeight(), 1)

    -- Dibujar fondo de la sección superior con el color de la especialidad
    love.graphics.setColor(r, g, b, a)
    love.graphics.draw(stand_info_top_bg_png, 0, 0, 0, scale, scale)

    -- Dibujar detalles/decoraciones de la sección superior en blanco
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(stand_info_top_fg_png, 0, 0, 0, scale, scale)

    -- ========================================
    -- DIBUJAR SECCIÓN MEDIA (CONTENIDO BLANCO)
    -- ========================================
    -- Esta sección tiene fondo blanco y contiene la información del stand
    local w = stand_info_top_bg_png:getWidth()*scale
    local y = stand_info_top_bg_png:getHeight()*scale
    -- Calcular la altura dinámicamente según si hay profesor o no
    local h = 34 + font_small:getHeight() + 17 + font_title:getHeight() + 34
    if stand.profesor then h = h + 54 + font_small:getHeight() end

    -- Dibujar el fondo blanco de la sección media
    love.graphics.rectangle("fill", 0, y, w, h)

    -- ========================================
    -- DIBUJAR SECCIÓN INFERIOR (PIE)
    -- ========================================
    -- Similar al encabezado pero al final de la tarjeta
    y = y + h
    love.graphics.setColor(r, g, b, a)
    love.graphics.draw(stand_info_bottom_bg_png, 0, y, 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(stand_info_bottom_fg_png, 0, y, 0, scale, scale)

    -- ========================================
    -- MOSTRAR CURSO EN LA ESQUINA SUPERIOR DERECHA
    -- ========================================
    if stand.curso then
      local padding = 5
      -- Calcular el ancho del texto del curso
      local rect_bg_x = font_curso:getWidth(stand.curso .. (stand.especialidad or "")) + padding*2
      local rect_bg_y = stand_info_top_bg_png:getHeight()*scale

      -- Dibujar un rectángulo de fondo con el color de la especialidad
      love.graphics.setColor(r, g, b, a)
      love.graphics.rectangle("fill", w-w*0.2-rect_bg_x, 0, rect_bg_x, rect_bg_y)

      -- Dibujar el texto del curso en blanco
      love.graphics.setFont(font_curso)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(stand.curso .. (stand.especialidad or ""), w-w*0.2-rect_bg_x+padding, (rect_bg_y/2), 0, 1,1, 0, 0.5*font_curso:getHeight())
    end

    -- ========================================
    -- MOSTRAR INFORMACIÓN DEL STAND
    -- ========================================
    local xpadding = 20

    -- Color negro para el texto informativo
    love.graphics.setColor(0, 0, 0, 1)
    y = stand_info_top_bg_png:getHeight()*scale + 34

    -- Etiqueta "TÍTULO:"
    love.graphics.setFont(font_small)
    love.graphics.print("TÍTULO:", xpadding, y)

    -- Título del stand
    y = y + font_small:getHeight() + 17
    love.graphics.setFont(font_title)
    love.graphics.print(stand.texto, xpadding, y)

    -- Mostrar profesor si existe
    if stand.profesor then
      y = y + font_title:getHeight() + 54

      love.graphics.setFont(font_small)
      love.graphics.print("PROFESOR: " .. (stand.profesor or ""), xpadding, y)
    end

  -- Dejar de renderizar en el canvas
  love.graphics.setCanvas()

  -- ========================================
  -- MOSTRAR EL CANVAS EN PANTALLA
  -- ========================================
  -- Usar blendmode "premultiplied" para mejor calidad de mezcla
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.setColor(1,1,1,1)
  -- Dibujar el canvas en la parte superior-central de la pantalla
  love.graphics.draw(canvas, safe.w/2, 12, 0, canvasscale, canvasscale, 0.5*canvas:getWidth(), 0)
  -- Volver al blendmode normal
  love.graphics.setBlendMode("alpha")

end

-- ========================================
-- FUNCIÓN: build_filter_buttons
-- ========================================
-- Construye la estructura de posiciones de botones para detección de clics.
-- Retorna información de cada botón (categoría y stands).
--
-- Parámetros:
--   filters_ui (table): tabla con las categorías y sus estados
--   filters_data (table): tabla con los datos cargados desde JSON
--   content_width (number): ancho disponible para el contenido
--
-- Retorna: table - estructura con posiciones de botones
function expo.build_filter_buttons(filters_ui, filters_data, content_width)
  local padding = 15
  local button_height = 40
  local category_height = 35
  local spacing = 10
  local current_y = padding
  local buttons = {
    categories = {},
    stands = {}
  }

  for _, category_data in ipairs(filters_data) do
    local cat_id = category_data.id
    local cat_ui = filters_ui.categories[cat_id]

    if cat_ui then
      local header_y = current_y

      -- Registrar botón de categoría
      table.insert(buttons.categories, {
        id = cat_id,
        x = padding,
        y = header_y,
        w = content_width - (padding * 2),
        h = category_height
      })

      current_y = current_y + category_height + spacing

      -- Registrar botones de stands (siempre visibles)
      local stands_list = category_data.stands or {}
      local buttons_per_row = 3
      -- Calcular ancho de botón restando padding y spacing
      local available_w = content_width - (padding * 2)
      local button_width = (available_w - (spacing * (buttons_per_row - 1))) / buttons_per_row

      for i, stand_id in ipairs(stands_list) do
        local col = (i - 1) % buttons_per_row
        local row = math.floor((i - 1) / buttons_per_row)

        local button_x = padding + (col * (button_width + spacing))
        local button_y = current_y + (row * (button_height + spacing))

        table.insert(buttons.stands, {
          category_id = cat_id,
          stand_id = stand_id,
          x = button_x,
          y = button_y,
          w = button_width,
          h = button_height
        })
      end

      local num_stands = #stands_list
      local rows_needed = math.ceil(num_stands / buttons_per_row)
      current_y = current_y + (rows_needed * (button_height + spacing)) + spacing
      current_y = current_y + spacing
    end
  end

  buttons.content_height = current_y
  return buttons
end

-- ========================================
-- FUNCIÓN: draw_filter_canvas
-- ========================================
-- Dibuja el contenido de filtros en un canvas con scroll.
-- El canvas se redibuja cada frame para reflejar cambios en los filtros.
--
-- Parámetros:
--   canvas (love.Canvas): canvas donde dibujar
--   filters_ui (table): tabla con las categorías y sus estados
--   filters_data (table): tabla con los datos cargados desde JSON
--   font_small (love.Font): fuente para texto
--   color (table): tabla de colores
--   scroll_y (number): desplazamiento vertical actual
--   content_width (number): ancho del contenido
function expo.draw_filter_canvas(canvas, filters_ui, filters_data, font_small, color, scroll_y, content_width)
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)

  local padding = 15
  local button_height = 40
  local category_height = 35
  local spacing = 10
  local current_y = padding - scroll_y

  for _, category_data in ipairs(filters_data) do
    local cat_id = category_data.id
    local cat_ui = filters_ui.categories[cat_id]

    if cat_ui then
      local header_y = current_y

      -- Dibujar encabezado de categoría
      local button_color = Color.button_idle
      -- Si todos los stands están seleccionados, usar color verde
      if cat_ui.selected then
        button_color = Color.greentoggle
      end
      local r, g, b, a = expo.hexcolorfromstring(button_color)
      love.graphics.setColor(r, g, b, a)
      -- Usar ancho completo menos padding en ambos lados
      love.graphics.rectangle("fill", padding, header_y, content_width - (padding * 2), category_height, 8)

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.setFont(font_small)
      love.graphics.print(category_data.category, padding + 12, header_y + (category_height - font_small:getHeight()) / 2)

      current_y = current_y + category_height + spacing

      -- Dibujar stands
      local stands_list = category_data.stands or {}
      local buttons_per_row = 3
      -- Calcular ancho disponible para botones
      local available_w = content_width - (padding * 2)
      local button_width = (available_w - (spacing * (buttons_per_row - 1))) / buttons_per_row

      for i, stand_id in ipairs(stands_list) do
        local col = (i - 1) % buttons_per_row
        local row = math.floor((i - 1) / buttons_per_row)

        local button_x = padding + (col * (button_width + spacing))
        local button_y = current_y + (row * (button_height + spacing))

        local is_selected = cat_ui.stands[stand_id] or false

        if is_selected then
          r, g, b, a = expo.hexcolorfromstring(color.greentoggle)
        else
          r, g, b, a = expo.hexcolorfromstring(color.button_idle)
        end
        love.graphics.setColor(r, g, b, a)
        love.graphics.rectangle("fill", button_x, button_y, button_width, button_height, 6)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(font_small)
        local text_w = font_small:getWidth(tostring(stand_id))
        local text_h = font_small:getHeight()
        love.graphics.print(
          tostring(stand_id),
          button_x + (button_width - text_w) / 2,
          button_y + (button_height - text_h) / 2
        )
      end

      local num_stands = #stands_list
      local rows_needed = math.ceil(num_stands / buttons_per_row)
      current_y = current_y + (rows_needed * (button_height + spacing)) + spacing
      current_y = current_y + spacing
    end
  end

  love.graphics.setCanvas()
end

return expo
