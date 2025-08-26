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

-- función que crea una ventana.
-- ésta funcion va a ser utilizada para los filtros y para el about.
-- la función va a dibujar un rectángulo blanco, va a dibujar una
-- headerbar sobre éste rectángulo, y dependiendo de qué argumento especial
-- se le pase, va a dibujar la pantalla de filtros o el about.
-- el argumento debe ser "filter" o "about".
-- el segundo argumento debe ser la fuente.
function expo.renderwindow(windowtype, lfont, sfont)
    love.graphics.push()
    local _, _, safe_w, safe_h = love.window.getSafeArea()
    local w, h = safe_w*0.9, safe_h*0.5
    local x, y = expo.centered(safe_w, safe_h, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)

    -- dibujar la headerbar
    love.graphics.setColor(24/255, 38/255, 47/255, 1)
    love.graphics.rectangle("fill", x, y, w, 60)

	-- dark:
	-- love.graphics.setColor(38/255, 38/255, 38/255, 1)
    -- white:
	-- love.graphics.setColor(1, 1, 1, 1)
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

-- funcion que reemplaza lo siguiente:
-- if var >= a and var <= b then.
function expo.inrange(var, a, b)
  return var >= a and var <= b
end




return expo
