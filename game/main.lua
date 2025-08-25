
-- libraries

-- ovaltutu bootstrap things
https = nil
local overlayStats = require("lib.overlayStats")
local runtimeLoader = require("runtime.loader")

-- lick
local lick = require "lib/lick/lick"
lick.updateAllFiles = true
lick.clearPackages = true
lick.reset = true
lick.debug = true

-- dkjson
local json = require "lib/dkjson"


-- assets
local expoguia_title_png = love.graphics.newImage("assets/images/expoguia-title.png")
local font_reddit_regular_16 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 16)
local font_reddit_regular_24 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 24)
local font_reddit_regular_32 = love.graphics.newFont("assets/fonts/RedditSans-Regular.ttf", 32)

-- variables
local safe_x, safe_y, safe_w, safe_h = 0, 0, 0, 0

function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here
  overlayStats.load() -- Should always be called last
end

function love.draw()
  -- Your game draw here
	love.graphics.print("I have to rewrite my entire app, because it is spaghetti.", 10, 10)

  overlayStats.draw() -- Should always be called last
end

function love.update(dt)
  -- Your game update here
  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key)
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
    overlayStats.handleKeyboard(key) -- Should always be called last
  end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end
