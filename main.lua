local utils = require 'utils'


local text = {""}
text.y = 0

function text_lines()
  local res = 0
  for line in table.concat(text):gmatch('\n') do
    res = res + 1
  end
  return res
end

local font_size = 16
local font = nil

function update_font()
  font = love.graphics.newFont('Menlo.ttc', font_size)
  love.graphics.setFont(font)
end

function lines_on_screen()
  return math.floor(love.graphics.getHeight() / font:getHeight())
end

local start_number = 1
local numbers_width = 0

function numbers_text()
  local end_number = start_number + lines_on_screen()
  local last_number = text_lines()
  local delimiter = '| '
  numbers_width = font:getWidth(' '..end_number..delimiter)
  local res = ''
  for i=start_number,math.min(end_number, last_number) do
    local s = string.format(' %d%s\n', i, delimiter)
    res = res..s
  end
  for i=last_number,end_number do
    local s = string.format('~ %s\n', delimiter)
    res = res..s
  end
  return res
end

local cursor = {}
cursor.position = {1,0}

function move_text(y)
  local font_height = font:getHeight()
  text.y = text.y + y*font_height
  if text.y > 0 then text.y = 0 end
  local down_border = -(text_lines()-1)*font_height
  if text.y < down_border then
    text.y = down_border
  end
  start_number = 1 - text.y/font_height
  if cursor.position[1] < start_number then
    cursor.position[1] = start_number
  elseif cursor.position[1] > start_number + lines_on_screen() then
    cursor.position[1] = start_number + lines_on_screen() - 1
  end
end

function cursor:blink()
  local elapsed = os.clock() - self.t
  return 0 < elapsed%0.1 and elapsed%0.1 < 0.05 
end
cursor.t = os.clock()

function cursor:draw()
  if self:blink() then
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,1,1)
    local x = numbers_width + font:getWidth(string.rep(' ', self.position[2]))
    local y1 = (self.position[1]+0-start_number)*font:getHeight()
    local y2 = (self.position[1]+1-start_number)*font:getHeight()
    love.graphics.line(x,y1,x,y2)
    self.t = 0
  end
end

function love.load()
  love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
  update_font()
  text[1] = utils.read_file(arg[2])
  love.window.setTitle(arg[2])
  love.keyboard.setKeyRepeat(true)
end

function love.draw()
  love.graphics.printf(numbers_text(), 0,0, numbers_width, 'right')
  love.graphics.print(table.concat(text, ''), numbers_width, text.y)
  cursor:draw()
end

function love.wheelmoved(x,y)
  move_text(y)
end

function love.keypressed(key)
  if love.keyboard.isDown('lctrl') then
    if key == '=' then 
      font_size = font_size+1
      update_font()
    elseif key == '-' then
      font_size = font_size-1
      update_font()
    end
  else
    if key == 'left' then
      cursor.position[2] = cursor.position[2] - 1
      if cursor.position[2] < 0 then 
        cursor.position[2] = 0 
      end
    elseif key == 'right' then
      cursor.position[2] = cursor.position[2] + 1
    elseif key == 'up' then
      cursor.position[1] = cursor.position[1] - 1
      if cursor.position[1] < 1 then 
        cursor.position[1] = 1
      end
    elseif key == 'down' then
      cursor.position[1] = cursor.position[1] + 1
      if cursor.position[1] > text_lines() then 
        cursor.position[1] = text_lines() 
      end
    end
    local cursor_y = text.y + cursor.position[1]*font:getHeight()
    if cursor_y < font:getHeight() then 
      move_text(1)
    elseif cursor_y > love.graphics.getHeight() then
      move_text(-1)
    end
    cursor.t = os.clock()
  end
end
