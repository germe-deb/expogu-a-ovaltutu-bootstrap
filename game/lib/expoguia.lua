-- SPDX-FileCopyrightText: 2025 germe-deb <dpkg.luci@protonmail.com>
--
-- SPDX-License-Identifier: MIT

-- Librería de UI hecha para ExpoGuía.
local expo = {}

-- Centra un objeto dentro de un contenedor, devolviendo los offsets en X e Y.
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
-- @param x = posición en x
-- @param y = posición en y
-- @param w = ancho
-- @param h = alto
-- @param title_h = alto del título
-- @param content = tabla con el contenido de la ventana.
function expo.dialog(x, y, safe, title_h, content)
    love.graphics.push()
    radius = 24
    title_h = title_h or radius*2
    -- dibujar la ventana
    -- establecer el color de fondo
    -- love.graphics.setColor(r,g,b,a)
    love.graphics.rectangle("fill", x, y, safe.w, safe.h)

    -- dibujar la headerbar
    -- establecer el color del título
    -- love.graphics.setColor(24/255, 38/255, 47/255, 1)
    love.graphics.circle("fill", x+radius, y+radius)
    love.graphics.rectangle("fill", x+radius, y, safe.w-radius*2, title_h)
    love.graphics.rectangle("fill", x, y+radius, safe.w, title_h-radius)

    if windowtype == "filter" then

		local font = lfont
		love.graphics.setFont(font)
        -- dibujar la pantalla de filtros
        -- aquí va el código para dibujar la pantalla de filtros
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Filtros", x + font:getHeight()*0.3, y + font:getHeight()*0.3)
        love.graphics.setColor(38/255, 38/255, 38/255, 1)
		local font = sfont
		love.graphics.setFont(font)
    elseif windowtype == "about" then
        local font = lfont
		love.graphics.setFont(font)
		love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Acerca de", x + font:getHeight()*0.3, y + font:getHeight()*0.3)
		love.graphics.setColor(38/255, 38/255, 38/255, 1)
		local font = sfont
		love.graphics.setFont(font)
		-- texto del about
		local offsetx = x + font:getHeight()*1.3
		local offsety = y + 70 + font:getHeight()*0.3
		local spacing = 22
		love.graphics.print("Expoguía", offsetx, offsety + 0*spacing)
		love.graphics.print("Aplicación desarrollada por el alumno Lucia Gianluca, para la EESTn°1.", offsetx, offsety + 1*spacing)
		love.graphics.print("Esta aplicación está construida sobre el motor de videojuegos Love2D.", offsetx, offsety + 2*spacing)
		-- love.graphics.print("Esta aplicación está construida sobre el motor de videojuegos Love2D.", offsetx, offsety + 2*spacing)


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
-- @param x number: posición x del pivote del botón
-- @param y number: posición y del pivote del botón
-- @param texto string: texto a mostrar
-- @param fuente love.Font: fuente a usar
-- @param bg_color table: {r,g,b,a} color de fondo
-- @param text_color table: {r,g,b,a} color del texto
-- @param padding number: padding horizontal (opcional, default 16)
-- @param radius number: radio de los extremos (opcional, default altura/2)
-- @param ox number: pivote horizontal (0=izquierda, 0.5=centro, 1=derecha; opcional, default 0)
-- @param oy number: pivote vertical (0=arriba, 0.5=centro, 1=abajo; opcional, default 0)
function expo.pillbutton(x, y, texto, fuente, bg_color, text_color, radius, ox, oy)
  ox = ox or 0
  oy = oy or 0
  love.graphics.setFont(fuente)
  local segment = 200
  local text_w = fuente:getWidth(texto)
  local text_h = fuente:getHeight()

  -- local draw_x = x - w * pivot_x
  -- local draw_y = y - h * pivot_y

  local total_w = radius*2 + text_w
  local total_h = radius*2

  -- implementar ox y oy.
    x = x - ox * (text_w + radius)
    y = y - oy * (radius)

  -- Fondo
  r, g, b, a = expo.hexcolorfromstring(bg_color)
  love.graphics.setColor(r, g, b, a)
  love.graphics.rectangle("fill", x, y-radius, text_w, radius*2)
  love.graphics.circle("fill", x, y, radius, segment)
  love.graphics.circle("fill", x+text_w, y, radius, segment)

  -- Texto
  r, g, b, a = expo.hexcolorfromstring(text_color)
  love.graphics.setColor(r, g, b, a)
  -- love.graphics.print( text, x, y, r, sx, sy, ox, oy, kx, ky )
  love.graphics.print(texto, x, y, 0, 1, 1, 0, 0.5*text_h)
end


return expo
