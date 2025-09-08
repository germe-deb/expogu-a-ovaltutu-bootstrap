-- SPDX-FileCopyrightText: 2025 germe-deb <dpkg.luci@protonmail.com>
--
-- SPDX-License-Identifier: GPL-3.0-or-later

local Color = require "lib/colors"
-- Librería de UI hecha para ExpoGuía.
local expo = {}

-- Centra un objeto dentro de un contenedor. devuelvo offsets en X e Y.
-- contW Ancho del contenedor.
-- contH Alto del contenedor.
-- bjW Ancho del objeto.
-- objH Alto del objeto.
-- aliX (Opcional) Alineación horizontal (0: izquierda, 1: derecha; por defecto 0.5).
-- aliY (Opcional) Alineación vertical (0: arriba, 1: abajo; por defecto 0.5).
-- return offX, offY: Desplazamientos en X e Y para alinear el objeto según lo indicado.
function expo.centered(contW, contH, objW, objH, aliX, aliY)
  -- por defecto alinear al centro en X y Y.
  aliX = aliX or 0.5
  aliY = aliY or 0.5

  local offX = (contW - objW) * aliX
  local offY = (contH - objH) * aliY

  return offX, offY
end

-- función que devuelve el factor de escala para que un objeto
-- (objW, objH) entre dentro de un contenedor (contW, contH) cuando scale es 1.
-- si scale es 0.5, el objeto ocupará la mitad del contenedor.
-- contW Ancho del contenedor.
-- contH Alto del contenedor.
-- objW Ancho del objeto.
-- objH Alto del objeto.
-- scale (Opcional) Escala del objeto (por defecto 1).
-- return factor de escala.
function expo.scale(contW, contH, objW, objH, scale)
  scale = scale or 1
  local scaleX = contW / objW
  local scaleY = contH / objH
  local scaleFactor = math.min(scaleX, scaleY) * scale
  return scaleFactor
end

-- automatizar los ID de los stands
function expo.automate_stand_id(stand_table)
    for i, stand in ipairs(stand_table) do
        stand.id = i
    end
    return stand_table
end

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

-- función que crea un diálogo.
-- x = posición en x
-- y = posición en y
-- safe
-- content
-- stands = tabla de los stands.
-- font_title
-- font_normal
-- color
function expo.dialog(x, y, safe, content, stands, font_title, font_normal, color)
    love.graphics.push()
    local radius = 24
    local title_h = radius*2
    -- dibujar la ventana
    -- establecer el color de fondo
    local r,g,b,a = expo.hexcolorfromstring(Color.background)
    love.graphics.setColor(r,g,b,a)
    love.graphics.rectangle("fill", x, y+title_h, safe.w, safe.h)

    -- dibujar la headerbar
    -- establecer el color del título
    r,g,b,a = expo.hexcolorfromstring(Color.foreground_light)
    love.graphics.setColor(r,g,b,a)
    love.graphics.circle("fill", x+radius, y+radius, radius)
    love.graphics.circle("fill", safe.w-radius, y+radius, radius)
    love.graphics.rectangle("fill", x+radius, y, safe.w-radius*2, title_h)

    if content.windowtype == "filtros" then
      -- dibujar una headerbar más grande
      love.graphics.rectangle("fill", x, y+radius, safe.w, title_h-radius+4*radius)

      love.graphics.setFont(font_title)
      -- dibujar la pantalla de filtros
      -- aquí va el código para dibujar la pantalla de filtros
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print("Filtros", safe.w*0.5, y + title_h/2, 0, 1,1, font_title:getWidth("Filtros")*0.5, font_title:getHeight()*0.5)

      love.graphics.setFont(font_normal)
      -- botones de la header
      expo.pillbutton(safe.w*0.5, y+radius*3, "Reestablecer Filtros", font_normal, Color.reestablecer, Color.text, 18, 0.5, 0.5)
      -- custom toggle para alternar incluir o excluir
      r,g,b,a = expo.hexcolorfromstring(Color.button_idle)
      love.graphics.setColor(r,g,b,a)
      love.graphics.rectangle("fill", x+30, y+radius*4+4, safe.w-60, radius*1.5, radius*0.75)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print("Modo:", x+30+radius-4, y+radius*4.75+4, 0, 1,1, 0, font_normal:getHeight()*0.5)
      love.graphics.print("Excluir", safe.w-30-radius+4, y+radius*4.75+4, 0, 1,1, font_normal:getWidth("Excluir"), font_normal:getHeight()*0.5)
      local switch_w = 50
      local switch_h = 25
      local padding = 8
      love.graphics.print("Incluir", safe.w-30-radius+4 - font_normal:getWidth("Excluir") - switch_w - padding*2, y+radius*4.75+4, 0, 1,1, font_normal:getWidth("Incluir"), font_normal:getHeight()*0.5)
      -- dibujar un switch
      expo.drawtoggle(safe.w-30-radius+4 - font_normal:getWidth("Excluir") - switch_w/2 - padding, y+radius*4.75+4, false, 0.5, 0.5, false)

    else
      -- terminar de dibujar la headerbar
      love.graphics.rectangle("fill", x, y+radius, safe.w, title_h-radius)
    end
    love.graphics.pop()
end

-- Lerp function
-- funciona así:
-- a es la posición inicial, o la posición real actual
-- b es la posición destino
-- t es la velocidad
function expo.lerp(a, b, t)
    return a + (b - a) * t
end

-- Interpolación con aceleración (comienza lento, termina rápido)
function expo.lerpin(a, b, t)
    return a + (b - a) * (t * t)
end

-- Interpolación con desaceleración (comienza rápido, termina lento)
function expo.lerpout(a, b, t)
    return a + (b - a) * (t * (2 - t))
end

-- Interpolación con aceleración y desaceleración (suave en ambos extremos)
function expo.lerpinout(a, b, t)
    t = t * 2
    if t < 1 then
        return a + (b - a) * (0.5 * t * t)
    else
        t = t - 1
        return a + (b - a) * (0.5 * (1 - t * (2 - t)) + 0.5)
    end
end

-- función para transformar hex a r, g, b, a
function expo.hexcolor(int)
  return bit.band(bit.rshift(int, 24), 255)/255,
  bit.band(bit.rshift(int, 16), 255)/255,
  bit.band(bit.rshift(int, 8), 255)/255,
  bit.band(int, 255)/255
end
function expo.hexcolorfromstring(str)
  if not str then
    return 0, 0, 0, 1 -- Color negro por defecto
  end
  local int = str:match('#(%x+)')
  return expo.hexcolor( tonumber(int, 16) )
end
--[[
  function expo.hexcolorfromstring(hex)
    hex = hex:gsub("#","")
    return {
      tonumber("0x"..hex:sub(1,2))/255,
      tonumber("0x"..hex:sub(3,4))/255,
      tonumber("0x"..hex:sub(5,6))/255
    }
  end
]]


-- funcion que reemplaza lo siguiente:
-- if var >= a and var <= b then.
function expo.inrange(var, a, b)
  return var >= a and var <= b
end

--- Dibuja un botón tipo píldora (rectángulo con extremos redondeados)
-- x number: posición x del pivote del botón
-- y number: posición y del pivote del botón
-- texto string: texto a mostrar
-- fuente love.Font: fuente a usar
-- bg_color table: {r,g,b,a} color de fondo
-- text_color table: {r,g,b,a} color del texto
-- padding number: padding horizontal (opcional, default 16)
-- radius number: radio de los extremos (opcional, default altura/2)
-- ox number: pivote horizontal (0=izquierda, 0.5=centro, 1=derecha; opcional, default 0)
-- oy number: pivote vertical (0=arriba, 0.5=centro, 1=abajo; opcional, default 0)
function expo.pillbutton(x, y, texto, fuente, bg_color, text_color, radius, ox, oy)
  ox = ox or 0
  oy = oy or 0
  love.graphics.setFont(fuente)
  local segment = 200
  local text_w = fuente:getWidth(texto)
  local text_h = fuente:getHeight()

  local total_w = radius * 2 + text_w
  local total_h = radius * 2

  -- Ajustar x, y para que (0,0) sea la esquina superior izquierda del área total
  x = x - ox * total_w
  y = y - oy * total_h

  -- Fondo
  local r, g, b, a = expo.hexcolorfromstring(bg_color)
  love.graphics.setColor(r, g, b, a)
  -- Rectángulo central
  love.graphics.rectangle("fill", x + radius, y, text_w, total_h)
  -- Círculo izquierdo
  love.graphics.circle("fill", x + radius, y + radius, radius, segment)
  -- Círculo derecho
  love.graphics.circle("fill", x + radius + text_w, y + radius, radius, segment)

  -- Texto (centrado verticalmente)
  r, g, b, a = expo.hexcolorfromstring(text_color)
  love.graphics.setColor(r, g, b, a)
  love.graphics.print(texto, x + radius, y + (total_h - text_h) / 2)
end

-- función que dibuja un switch o un toggle.
-- x number: posición x del toggle
-- y number: posición y del toggle
-- state boolean: estado del toggle (true=on, false=off)
-- ox number: pivote horizontal
-- oy number: pivote vertical
-- activar colores
function expo.drawtoggle(x, y, state, ox, oy, colors)
  ox = ox or 0
  oy = oy or 0
  colors = colors or false
  local w = 50
  local h = 25
  local radius = h / 2

  -- dibujar el fondo
  if colors then
    if state then
      -- verde
      local r, g, b, a = expo.hexcolorfromstring(Color.greentoggle)
      love.graphics.setColor(r, g, b, a)
    else
      -- rojo
      local r, g, b, a = expo.hexcolorfromstring(Color.redtoggle)
      love.graphics.setColor(r, g, b, a)
    end
  else
    local r, g, b, a = expo.hexcolorfromstring(Color.button_pressed)
    love.graphics.setColor(r, g, b, a)
  end
  love.graphics.rectangle("fill", x - ox * w, y - oy * h, w, h, radius)

  -- dibujar el circulo (fg)
  love.graphics.setColor(1,1,1,1)
  if state == false then
    x = x -w/2
  end
  love.graphics.circle("fill", x+radius, y, radius*0.8)

end

-- función para dibujar la tarjeta informativa de un stand.
function expo.draw_stand(stand, safe, stand_info_top_bg_png, stand_info_top_fg_png, stand_info_bottom_bg_png, stand_info_bottom_fg_png, font_small, font_curso, font_title)

  canvasscale = expo.scale(math.min(420, safe.w*0.9), safe.h, stand_info_top_bg_png:getWidth(), stand_info_top_bg_png:getHeight(), 1)

  -- usar el canvas
  love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setBlendMode("alpha")

    -- primero, setear los colores y valores
    -- setear los colores en función de la especialidad
    local r, g, b, a
    if stand.especialidad == "E" then
      r, g, b, a = expo.hexcolorfromstring("#3746d0ff")
    elseif stand.especialidad == "C" then
      r, g, b, a = expo.hexcolorfromstring("#cf781dff")
    elseif stand.especialidad == "IPP" then
      r, g, b, a = expo.hexcolorfromstring("#24a7aaff")
    elseif stand.especialidad == "ESC" then
      r, g, b, a = expo.hexcolorfromstring("#0e8d0aff")
    elseif stand.especialidad == "BH" or stand.especialidad == "BM" then
      r, g, b, a = expo.hexcolorfromstring("#475864ff")
    elseif stand.especialidad == "expoguia" then
      r, g, b, a = expo.hexcolorfromstring("#212121ff")
    else
      r, g, b, a = expo.hexcolorfromstring("#28a06eff")
    end

    -- dibujar la porción de arriba
    local scale = expo.scale(canvas:getWidth(), canvas:getHeight(), stand_info_top_bg_png:getWidth(), stand_info_top_bg_png:getHeight(), 1)
    love.graphics.setColor(r, g, b, a)
    love.graphics.draw(stand_info_top_bg_png, 0, 0, 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(stand_info_top_fg_png, 0, 0, 0, scale, scale)


    -- dibujar el rectángulo blanco del medio
    local w = stand_info_top_bg_png:getWidth()*scale
    local y = stand_info_top_bg_png:getHeight()*scale
    local h = 34 + font_small:getHeight() + 17 + font_title:getHeight() + 34
    if stand.profesor then h = h + 54 + font_small:getHeight() end
    love.graphics.rectangle("fill", 0, y, w, h)

    -- dibujar la porción de abajo

    y = y + h
    love.graphics.setColor(r, g, b, a)
    love.graphics.draw(stand_info_bottom_bg_png, 0, y, 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(stand_info_bottom_fg_png, 0, y, 0, scale, scale)

    -- curso
    if stand.curso then
      local padding = 5
      local rect_bg_x = font_curso:getWidth(stand.curso .. (stand.especialidad or "")) + padding*2
      local rect_bg_y = stand_info_top_bg_png:getHeight()*scale

      love.graphics.setColor(r, g, b, a)

      love.graphics.rectangle("fill", w-w*0.2-rect_bg_x, 0, rect_bg_x, rect_bg_y)

      love.graphics.setFont(font_curso)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(stand.curso .. (stand.especialidad or ""), w-w*0.2-rect_bg_x+padding, (rect_bg_y/2), 0, 1,1, 0, 0.5*font_curso:getHeight())
    end

    -- información
    local xpadding = 20

    love.graphics.setColor(0, 0, 0, 1)
    y = stand_info_top_bg_png:getHeight()*scale + 34

    love.graphics.setFont(font_small)
    love.graphics.print("TÍTULO:", xpadding, y)

    y = y + font_small:getHeight() + 17

    love.graphics.setFont(font_title)
    love.graphics.print(stand.texto, xpadding, y)

    if stand.profesor then
      y = y + font_title:getHeight() + 54

      love.graphics.setFont(font_small)
      love.graphics.print("PROFESOR: " .. (stand.profesor or ""), xpadding, y)
    end

  love.graphics.setCanvas()

  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(canvas, safe.w/2, 12, 0, canvasscale, canvasscale, 0.5*canvas:getWidth(), 0)
  love.graphics.setBlendMode("alpha")

end


return expo
