function clamp(v, minv, maxv)
  if     v < minv then return minv
  elseif v > maxv then return maxv
  else return v end
end

function read_file(fname)
  local file = io.open(fname, 'r')
  local content = file:read('*all')
  file:close()
  return content
end

function write_file(fname, str)
  local file = io.open(fname, 'w')
  file:write(str)
  file:close()
end

local text = {}
text.str = ''
text.y = 0

function get_text_line(n)
  local line_beg = 0
  for i=1,n-1 do
    line_beg = string.find(text.str, '\n', line_beg+1)
  end
  local line_end = string.find(text.str, '\n', line_beg+1)
  return text.str:sub(line_beg+1, line_end-1)
end

function text_lines()
  local res = 0
  for line in text.str:gmatch('\n') do
    res = res + 1
  end
  return res
end

local font_size = 20
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
cursor.position = {1,0,0} -- line, char in line, char in whole text

function move_text(y)
  local font_height = font:getHeight()
  text.y = text.y + y*font_height
  text.y = clamp(text.y, -(text_lines()-1)*font_height, 0)
  start_number = 1 - text.y/font_height
  cursor.position[1] = clamp(cursor.position[1], start_number, start_number + lines_on_screen()-1)
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
  love.graphics.setColor(1,0,0)
  love.graphics.print(table.concat(self.position, '; '), 1000, 0)
end

function cursor:update()
  cursor.position[1] = clamp(cursor.position[1], 1, text_lines())
  cursor.position[2] = clamp(cursor.position[2], 0, #get_text_line(cursor.position[1]))
  cursor.position[3] = 0
  for i=1,cursor.position[1]-1 do
    cursor.position[3] = cursor.position[3] + #get_text_line(i) + 1
  end
  cursor.position[3] = cursor.position[3] + cursor.position[2]
  local cursor_y = text.y + cursor.position[1]*font:getHeight()
  if cursor_y < font:getHeight() then 
    move_text(1)
  elseif cursor_y > love.graphics.getHeight() then
    move_text(-1)
  end
  cursor.t = os.clock()
end

function text:insert(t)
  local before = text.str:sub(1,cursor.position[3])
  local after  = text.str:sub(cursor.position[3]+1,#text.str)
  text.str = before..t..after
  cursor.position[2] = cursor.position[2] + #t
  cursor:update()
end

function love.load()
  love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
  update_font()
  text.str = read_file(arg[2])
  text.str = text.str..'\n'
  love.window.setTitle(arg[2])
  love.keyboard.setKeyRepeat(true)
end

function love.draw()
  love.graphics.setColor(1,1,1)
  love.graphics.printf(numbers_text(), 0,0, numbers_width, 'right')
  love.graphics.print(text.str, numbers_width, text.y)
  cursor:draw()
end

function love.wheelmoved(x,y)
  move_text(y)
end

function love.keypressed(key)
  if love.keyboard.isDown('lgui') then
    if key == '=' then 
      font_size = font_size+1
      update_font()
    elseif key == '-' then
      font_size = font_size-1
      update_font()
    elseif key == 's' then
      write_file(arg[2], text.str)
    elseif key == 'left' then 
      cursor.position[2] = 0
    elseif key == 'right' then
      cursor.position[2] = #get_text_line(cursor.position[1])
    elseif key == 'up' then
      cursor.position[1] = 1
      cursor.position[2] = 0
    elseif key == 'down' then
      cursor.position[1] = text_lines()
      cursor.position[2] = #get_text_line(cursor.position[1])
    end
  else
    if key == 'left' then
      cursor.position[2] = cursor.position[2] - 1
    elseif key == 'right' then
      cursor.position[2] = cursor.position[2] + 1
    elseif key == 'up' then
      cursor.position[1] = cursor.position[1] - 1
    elseif key == 'down' then
      cursor.position[1] = cursor.position[1] + 1
    elseif key == 'backspace' then
      local before = text.str:sub(1,cursor.position[3]-1)
      local after  = text.str:sub(cursor.position[3]+1,#text.str)
      text.str = before..after
      if cursor.position[2] == 0 then
        cursor.position[1] = cursor.position[1] - 1
        cursor:update()
        cursor.position[2] = #get_text_line(cursor.position[1])
        cursor:update()
      else
        cursor.position[2] = cursor.position[2] - 1
      end
    elseif key == 'return' then
      text:insert('\n')
      cursor.position[1] = cursor.position[1] + 1
    elseif key == 'tab' then
      text:insert('  ')
    end
  end
  cursor:update()
end

function love.textinput(t)
  text:insert(t)
end
