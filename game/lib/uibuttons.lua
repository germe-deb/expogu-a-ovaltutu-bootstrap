local uibuttons = {}

uibuttons.list = {}

--- Registra un nuevo botón
-- @param btn table: {x, y, w, h, draw, onpress, userdata}
function uibuttons.register(btn)
  btn.pressed = false -- nuevo estado
  table.insert(uibuttons.list, btn)
end

--- Llama en love.draw()
function uibuttons.draw()
  for _, btn in ipairs(uibuttons.list) do
    if btn.draw then btn.draw(btn) end
  end
end

--- Llama en love.mousepressed/love.touchpressed
function uibuttons.handle_press(x, y)
  for _, btn in ipairs(uibuttons.list) do
    local bx, by, bw, bh
    if btn.get_rect then
      bx, by, bw, bh = btn.get_rect()
    else
      bx, by, bw, bh = btn.x, btn.y, btn.w, btn.h
    end
    if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
      btn.pressed = true
      if btn.onpress then btn.onpress(btn) end
      return true
    end
  end
  return false
end

function uibuttons.handle_release(x, y)
  for _, btn in ipairs(uibuttons.list) do
    btn.pressed = false
  end
end

return uibuttons
