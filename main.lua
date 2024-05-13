function last(t)
  return t[#t]
end

function map(t, f)
  local nt = {}
  for k,v in pairs(t) do
    nt[k] = f(v)
  end
  return nt
end

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

local back_color = {0.1, 0.1, 0.12}

local text = {}
text.str = ''
text.y = 0

local font_size = 22
local font = nil

local numbers = {}
numbers.start = 1
numbers.width = 0

local cursor = {}
cursor.position = {1,0,0} -- line, char in line, char in whole text
cursor.t = os.clock() -- for blinking

local selection = {}
selection.active = false
selection.intervals = {}


function update_font()
  font = love.graphics.newFont('Menlo.ttc', font_size)
  love.graphics.setFont(font)
end

function lines_on_screen()
  return math.floor(love.graphics.getHeight() / font:getHeight())
end

function text:get_line(n)
  local line_beg = 0
  for i=1,n-1 do
    line_beg = self.str:find('\n', line_beg+1)
  end
  local line_end = self.str:find('\n', line_beg+1)
  return self.str:sub(line_beg+1, line_end-1)
end

function text:count_lines()
  local res = 0
  for _line in self.str:gmatch('\n') do
    res = res + 1
  end
  return res
end

function text:move(y)
  local font_height = font:getHeight()
  self.y = self.y + y*font_height
  self.y = clamp(text.y, -(self:count_lines()-1)*font_height, 0)
  numbers.start = 1 - self.y/font_height
  cursor.position[1] = clamp(cursor.position[1], numbers.start, numbers.start + lines_on_screen()-1)
end

function text:insert(t)
  local before = self.str:sub(1,cursor.position[3])
  local after  = self.str:sub(cursor.position[3]+1,-1)
  self.str = before..t..after
  cursor.position[2] = cursor.position[2] + #t
  cursor:update()
end

function text:remove(pos1, pos2)
  pos1 = clamp(pos1-1, 0, pos1-1)
  pos2 = clamp(pos2+1, pos2+1, #self.str)
  local before = self.str:sub(1, pos1)
  local after = self.str:sub(pos2, -1)
  self.str = before..after
end

function numbers:str()
  local end_number = self.start + lines_on_screen()
  local delimiter = '|'
  self.width = font:getWidth(' '..end_number..delimiter)
  local last_number = text:count_lines()
  local res = ''
  for i=self.start,math.min(end_number, last_number) do
    res = res..string.format(' %d%s\n', i, delimiter)
  end
  for i=last_number,end_number do
    res = res..string.format('~ %s\n', delimiter)
  end
  return res
end

function cursor:blink()
  local elapsed = os.clock() - self.t
  return 0 < elapsed%0.1 and elapsed%0.1 < 0.05 
end

function cursor:draw()
  if self:blink() then
    love.graphics.setLineWidth(1)
    local x = numbers.width + font:getWidth(string.rep(' ', self.position[2]))
    local y1 = text.y + (self.position[1]-1)*font:getHeight()
    local y2 = text.y + (self.position[1]-0)*font:getHeight()
    love.graphics.line(x,y1,x,y2)
    self.t = 0
  end
  local position_text = table.concat(self.position, ':')
  love.graphics.print(
    position_text, 
    love.graphics.getWidth()-font:getWidth(position_text), 
    love.graphics.getHeight()-font:getHeight()
  )
end

function cursor:update()
  self.position[1] = clamp(self.position[1], 1, text:count_lines())
  self.position[2] = clamp(self.position[2], 0, #text:get_line(self.position[1]))
  self.position[3] = 0
  for i=1,self.position[1]-1 do
    self.position[3] = self.position[3] + #text:get_line(i) + 1
  end
  self.position[3] = self.position[3] + self.position[2]
  local y_lines = self.position[1] - numbers.start
  text:move(clamp(y_lines, 1, lines_on_screen()-1) - y_lines)
  self.t = os.clock()
end

function selection:draw()
  local selection_color = map(back_color, function(x) return (x+0.5) end)
  love.graphics.setColor(selection_color)
  -- love.graphics.rectangle('fill', 100, 100, 150, 150)
end


function love.load()
  love.graphics.setBackgroundColor(back_color)
  update_font()
  text.str = read_file(arg[2])
  text.str = text.str..'\n'
  love.window.setTitle(arg[2])
  love.keyboard.setKeyRepeat(true)
end

function love.draw()
  love.graphics.setColor(0.25,0.25,0.25)
  love.graphics.printf(numbers:str(), 0,0, numbers.width, 'right')
  selection:draw()
  love.graphics.setColor(1,1,1)
  love.graphics.print(text.str, numbers.width, text.y)
  cursor:draw()
end

function love.wheelmoved(x,y)
  text:move(y)
end

function love.keypressed(key)
  selection.active = false
  selection.intervals = {}
  if key == 'lshift' then 
    selection.active = true 
    table.insert(selection.intervals, {})
  end
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
      cursor.position[2] = #text:get_line(cursor.position[1])
    elseif key == 'up' then
      cursor.position[1] = 1
      cursor.position[2] = 0
    elseif key == 'down' then
      cursor.position[1] = text:count_lines()
      cursor.position[2] = #text:get_line(cursor.position[1])
    elseif key == 'v' then
      text:insert(love.system.getClipboardText())
    elseif key == 'c' then
      -- love.system.setClipboardText(selection.str)
    elseif key == 'backspace' then
      text:remove(cursor.position[3]-cursor.position[2]+1, cursor.position[3])
      cursor.position[2] = 0
    end
  else
    if selection.active then 
      table.insert(last(selection.intervals), cursor.position[3]) 
    end
    if key == 'left' then
      cursor.position[2] = cursor.position[2] - 1
    elseif key == 'right' then
      cursor.position[2] = cursor.position[2] + 1
    elseif key == 'up' then
      cursor.position[1] = cursor.position[1] - 1
    elseif key == 'down' then
      cursor.position[1] = cursor.position[1] + 1
    elseif key == 'backspace' then
      text:remove(cursor.position[3], cursor.position[3])
      if cursor.position[2] == 0 then 
        cursor.position[1] = cursor.position[1] - 1
        cursor.position[2] = #text:get_line(cursor.position[1])
      else
        cursor.position[2] = cursor.position[2]-1
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

function love.keyreleased(key)
  if key == 'lshift' then 
    selection.active = false 
  end
end

function love.mousepressed(mx, my, button)
  if mx > numbers.width then
    cursor.position = {
      1 + math.floor(my / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' '))
    }
    cursor:update()
  end
end


--[[

  TODO:
1. selection
2. code highlighting
3. go to line (status bar)
4. substitution

]]