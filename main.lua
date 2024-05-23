local highlight = require 'highlight'


function id(x) return x end

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
  if not file then return end
  local content = file:read('*all')
  file:close()
  return content
end

function write_file(fname, str)
  local file = io.open(fname, 'w')
  if not file then return end
  file:write(str)
  file:close()
end


local directory = '/'
local file = nil

local text = {}
text.str = ''

local font_size = 22
local font = nil

local numbers = {}
numbers.start = 1
numbers.width = 0

local cursor = {}
cursor.position = {1,0,0} -- line, char in line, char in whole text
cursor.t = os.clock() -- for blinking

local selection = {}
selection.color = {0.7, 0.7, 0.7}
selection.active = false
-- begin position that copies cursor position
selection.beg_pos = {0,0,0}


function update_font()
  font = love.graphics.newFont('Menlo.ttc', font_size)
  love.graphics.setFont(font)
end

function lines_on_screen()
  return math.floor(love.graphics.getHeight() / font:getHeight())
end

function execute(cmd)
  local handle = io.popen(cmd)
  local content = handle:read('*all')
  return content
end

function open_file(path)
  file = path
  text.str = read_file(file)
  love.window.setTitle(file)
end

function open_directory(path)
  local content = execute('ls -a '..path)
  text.str = content
  directory = path
  love.window.setTitle(directory)
end

function open(path)
  cursor.position = {1,0,0}
  numbers.start = 1
  if path == '..' then
    local i,j = directory:sub(1, #directory-1):find('.*/')
    if j == nil then return end
    path = directory:sub(i,j-1)
  elseif path == '.' then
    return
  else
    path = directory..path
  end
  local content = ''
  if path == '' then
    content = execute('file /')
  else
    content = execute('file '..path)
  end
  if content:find('cannot') then 
    text.str = content
    return 
  end
  if content:find('directory') then
    open_directory(path..'/')
  elseif content:find('text') then
    open_file(path)
  end
end

function text:get_line(n)
  local line_beg = 0
  for i=1,n-1 do
    line_beg = self.str:find('\n', line_beg+1)
  end
  local line_end = self.str:find('\n', line_beg+1) or 1
  return self.str:sub(line_beg+1, line_end-1)
end

function text:count_lines()
  local res = 0
  for _line in self.str:gmatch('\n') do
    res = res + 1
  end
  return res
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

function text:highlight(hl_table)
  local str = ''
  local i = 1
  for line in self.str:gmatch('.-\n') do
    if i >= numbers.start then
      str = str..line
    end
    if i > numbers.start + lines_on_screen() then break end
    i = i+1
  end
  local indexes = {}
  for _,hl_entry in ipairs(hl_table) do
    local i,j = str:find(hl_entry.to_hl, 0)
    while i do
      if hl_entry.rule(str, i, j) then 
        table.insert(indexes, {i, j, hl_entry.color})
      end
      i,j = str:find(hl_entry.to_hl, j+1)
    end
  end
  local total_lines = math.max(self:count_lines(), 100)
  table.sort(indexes, function(a,b)
    return (total_lines*a[1] + b[2]) < (total_lines*b[1] + a[2])
  end)
  local i = 2
  while i <= #indexes do
    local a = indexes[i-1]
    local b = indexes[i]
    if b[1] >= a[1] and b[2] <= a[2] then
      table.remove(indexes, i)
    else 
      i = i + 1
    end
  end
  local res = {}
  local j = 1
  for _,v in ipairs(indexes) do
    -- print(v[1], v[2], table.concat(v[3], ', '))
    table.insert(res, text_color)
    table.insert(res, str:sub(j, v[1]-1))
    table.insert(res, v[3])
    table.insert(res, str:sub(v[1], v[2]))
    j = v[2] + 1
  end
  table.insert(res, text_color)
  table.insert(res, str:sub(j, -1))
  return res
end

local separators = '[%s%+%-=%*/:;%%,%.%(%)%[%]]'

function text:find_word_end()
  local line = self:get_line(cursor.position[1])..' '
  local i,j = line:find('..-'..separators, cursor.position[2]+1)
  return (j or #line) - 1
end

function text:find_word_beg()
  local line = self:get_line(cursor.position[1]):sub(1, cursor.position[2]-1)
  local i,j = line:find('.*'..separators)
  return j or 0
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
  local elapsed = (os.clock() - self.t) % 0.1
  return 0 < elapsed and elapsed < 0.05 
end

function cursor:draw()
  if self:blink() then
    love.graphics.setLineWidth(1)
    local x = numbers.width + self.position[2] * font:getWidth(' ')
    local y1 = (self.position[1] - numbers.start + 0)*font:getHeight()
    local y2 = (self.position[1] - numbers.start + 1)*font:getHeight()
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
  self.t = os.clock()
  local on_screen = numbers.start < self.position[1] and self.position[1] < numbers.start + lines_on_screen()
  if not on_screen then
    numbers.start = self.position[1]
  end
end

function selection:draw()
  if not self.active then return end
  love.graphics.setColor(self.color)
  local fheight = font:getHeight()
  local fwidth = font:getWidth(' ')
  local p1, p2 = self.beg_pos, cursor.position
  if p2[3] < p1[3] then p1, p2 = p2, p1 end
  local fheight = font:getHeight()
  for line_i = p1[1], p2[1] do
    local y1 = (line_i + 0 - numbers.start) * fheight
    local y2 = (line_i + 1 - numbers.start) * fheight
    local x1 = numbers.width
    local x2 = love.graphics.getWidth()
    if line_i == p1[1] then x1 = p1[2] * fwidth + numbers.width end
    if line_i == p2[1] then x2 = p2[2] * fwidth + numbers.width end
    love.graphics.rectangle('fill', x1, y1, x2-x1, y2-y1)
  end
end

function selection:str()
  local p1 = self.beg_pos[3]
  local p2 = cursor.position[3]
  if p1 < p2 then
    return text.str:sub(p1, p2)
  else
    return text.str:sub(p2+1, p1)
  end
end

function selection:set_beg()
  self.beg_pos = map(cursor.position, id)
end

function selection:remove()
  local p1, p2 = self.beg_pos[3], cursor.position[3]
  p1, p2 = math.min(p1, p2), math.max(p1, p2)
  text:remove(p1+1, p2)
  if cursor.position[3] > self.beg_pos[3] then
    cursor.position = map(self.beg_pos, id)
  end
end


function love.load()
  love.graphics.setBackgroundColor(back_color)
  update_font()
  open_directory(directory)
  love.keyboard.setKeyRepeat(true)
end

function sleep(a)
  local sec = tonumber(os.clock() + a)
  while os.clock() < sec do end
end

local sleep = 0
function love.update(dt)
  love.timer.sleep(sleep)
  if love.timer.getFPS() > 80 then
    sleep = sleep + 0.00001
  end
end

function love.draw()
  love.graphics.setColor(comment_color)
  love.graphics.printf(numbers:str(), 0,0, numbers.width, 'right')
  selection:draw()
  love.graphics.setColor({1,1,1})
  love.graphics.print(text:highlight(highlight.lua), numbers.width, 0)
  love.graphics.setColor(text_color)
  cursor:draw()
end

function love.keypressed(key)
  if love.keyboard.isDown('lgui') then
    if key == '=' then 
      font_size = font_size + 1
      update_font()
    elseif key == '-' then
      font_size = font_size - 1
      update_font()
    elseif key == 's' then
      write_file(file or default_fpath, text.str)
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
      love.system.setClipboardText(selection:str())
      selection.active = false
    elseif key == 'x' then 
      if selection.active then
        love.system.setClipboardText(selection:str())
        selection:remove()
      end
      selection.active = false
    elseif key == 'v' then
      text:insert(love.system.getClipboardText())
    elseif key == 'backspace' then
      text:remove(cursor.position[3]-cursor.position[2]+1, cursor.position[3])
      cursor.position[2] = 0
    elseif key == 'o' then
      open(text:get_line(cursor.position[1]))
    end
  elseif love.keyboard.isDown('lalt') then
    if key == 'left' then
      cursor.position[2] = text:find_word_beg()
    elseif key == 'right' then
      cursor.position[2] = text:find_word_end()
    elseif key == 'up' then
      cursor.position[1] = cursor.position[1] - lines_on_screen()
    elseif key == 'down' then
      cursor.position[1] = cursor.position[1] + lines_on_screen()
    elseif key == 'backspace' then
      local toremove = cursor.position[2] - text:find_word_beg()
      text:remove(cursor.position[3] - toremove, cursor.position[3])
      cursor.position[2] = cursor.position[2] - toremove
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
      if selection.active then
        selection:remove()
      else
        text:remove(cursor.position[3], cursor.position[3])
        if cursor.position[2] == 0 then 
          cursor.position[1] = cursor.position[1] - 1
          cursor.position[2] = #text:get_line(cursor.position[1])
        else
          cursor.position[2] = cursor.position[2] - 1
        end
      end
    elseif key == 'return' then
      local cur_str = text:get_line(cursor.position[1])
      local i,j = cur_str:find('%s*')
      local indentation = cur_str:sub(i,j)
      text:insert('\n'..indentation)
      cursor.position[1] = cursor.position[1] + 1
      cursor.position[2] = #indentation
    elseif key == 'tab' then
      text:insert('  ')
    elseif key == 'escape' then
      file = nil
      open_directory(directory)
    elseif directory and key == 'o' then
      open(text:get_line(cursor.position[1]))
    end
  end
  if love.keyboard.isDown('lshift') then
    if not selection.active then
      selection.active = true
      selection:set_beg()
    end
  end
  cursor:update()
end

function love.keyreleased(key, isrepeat)
  if not (love.keyboard.isDown('lshift') or key == 'lshift') then
    selection.active = false
    selection:set_beg()
  end
end

function love.textinput(t)
  if not file then return end
  if selection.active then
    selection:remove()
    selection.active = false
  end
  text:insert(t)
end

function love.wheelmoved(x,y)
  numbers.start = clamp(numbers.start + y, 1, text:count_lines())
end

function love.mousepressed(mx, my, button, istouch, presses)
  if mx > numbers.width then
    cursor.position = {
      numbers.start + math.floor(my / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' ')),
      0
    }
    cursor:update()
  end
  selection.active = true
  selection:set_beg()
  if presses == 2 then
    selection.beg_pos[2] = text:find_word_beg()
    cursor.position[2] = text:find_word_end()
  elseif presses == 3 then
    selection.beg_pos = {cursor.position[1], 0, cursor.position[3] - cursor.position[2]}
    cursor.position[2] = #text:get_line(cursor.position[1])
  end
  cursor:update()
end

function love.mousemoved(mx, my, dx, dy)
  if love.mouse.isDown(1) then
    cursor.position = {
      numbers.start + math.floor(my / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' '))
    }
    cursor:update()
  end
end

function love.wheelmoved(x,y)
  numbers.start = clamp(numbers.start - y, 1, text:count_lines())
end

function love.filedropped(file)
  open_file(file:getFilename())
end

function love.directorydropped(path)
  open_directory(path)
end


--[[

  TODO:
3. go to line (status bar)
4. completion
5. search 

]]
