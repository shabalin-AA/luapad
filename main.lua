require 'text'
local text = Text()
local numbers    = require 'numbers'
local cursor     = require 'cursor'
local selection  = require 'selection'
local completion = require 'completion'
local highlight  = require 'highlight'
require 'tab'


function id(x) 
  return x 
end

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


local tabs = {}
table.insert(tabs, Tab('/', nil))
tabs.active = last(tabs)
tabs.font = love.graphics.newFont('Iosevka-Regular.ttc', 18)


local font_size = 22
local font = nil
local tab_replacement = '    '


function update_font()
  font_size = clamp(font_size, 2, 60)
  font = love.graphics.newFont('Iosevka-Regular.ttc', font_size)
  love.graphics.setFont(font)
end

function lines_on_screen()
  return math.floor(love.graphics.getHeight() / font:getHeight()) + 1
end

function execute(cmd)
  local handle = io.popen(cmd)
  local content = handle:read('*all')
  return content
end

function open_file(path)
  cursor:reset()
  tabs.active.file = path
  text.str = read_file(tabs.active.file):gsub('\t', tab_replacement)..'\n'
  local i,j = tabs.active.file:find('.+%.')
  local file_ext = nil
  if j then 
    file_ext = tabs.active.file:sub(j+1, -1)
  end
  text.mode = highlight[file_ext]
end

function open_directory(path)
  cursor:reset()
  local content = execute('ls -a '..path)
  text.str = content
  tabs.active.directory = path
  text.mode = nil
end

function open(path)
  local directory = tabs.active.directory
  cursor:reset() 
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
  elseif content:find('text') or content:find('empty') then
    open_file(path)
  end
end


function love.load()
  love.graphics.setBackgroundColor(back_color)
  update_font()
  open_directory(tabs.active.directory)
  love.keyboard.setKeyRepeat(true)
  quit = false
end

function sleep(a)
  local sec = tonumber(os.clock() + a)
  while os.clock() < sec do end
end

local sleep = 0
function love.update(dt)
  love.timer.sleep(sleep)
  if love.timer.getFPS() > 80 then
    sleep = sleep + 1e-5
  end
end

function love.draw()
  tabs.width = love.graphics.getWidth() / #tabs
  tabs.height = tabs.font:getHeight()
  for i,v in ipairs(tabs) do
    local x = (i-1)*tabs.width
    local y = 0
    love.graphics.setColor(back_color)
    love.graphics.rectangle('fill', x, 0, tabs.width, tabs.height)
    love.graphics.setColor(comment_color)
    love.graphics.rectangle('line', x, 0, tabs.width, tabs.height)
    if v == tabs.active then
      love.graphics.setColor({1,1,1})
    else
      love.graphics.setColor(comment_color)
    end
    local title = v:title()
    if text.dirty then title = title..'*' end
    love.graphics.printf(title, tabs.font, x, y, tabs.width, 'center')
  end
  
  love.graphics.setColor(back_color)
  love.graphics.rectangle('fill', 0, tabs.height, love.graphics.getWidth(), love.graphics.getHeight())
  
  love.graphics.setColor(comment_color)
  love.graphics.printf(numbers:str(text, font), 0, tabs.height, numbers.width, 'right')

  selection:draw(font, cursor, numbers, tabs.height)
  
  love.graphics.setColor({1,1,1})
  text:draw(numbers.width, tabs.height, numbers.start)
  
  love.graphics.setColor(text_color)
  cursor:draw(numbers, font, tabs.height)
end

function love.keypressed(key)
  if love.keyboard.isDown('lgui') then
    if key == '=' then 
      font_size = font_size + 2
      update_font()
    elseif key == '-' then
      font_size = font_size - 2
      update_font()
    elseif key == 's' then
      if tabs.active.file then  
        write_file(tabs.active.file, text.str:sub(1, -2))
        text.dirty = false
      end
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
      local ins = love.system.getClipboardText()
      text:insert(ins, cursor.position[3])
      cursor.position[2] = cursor.position[2] + #ins
    elseif key == 'c' then
      love.system.setClipboardText(selection:str(text.str, cursor.position[3]))
    elseif key == 'x' then 
      if selection.active then
        love.system.setClipboardText(selection:str(text.str, cursor.position[3]))
        cursor.position = selection:remove(text, cursor.position)
      end
    elseif key == 'v' then
      local ins = love.system.getClipboardText()  
      text:insert(ins, cursor.position[3])
      cursor.position[2] = cursor.position[2] + #ins
    elseif key == 'backspace' then
      text:remove(cursor.position[3] - cursor.position[2] + 1, cursor.position[3])
      cursor.position[2] = 0
    elseif key == 'o' then
      open(text:get_line(cursor.position[1]))
    elseif key == 't' then
      table.insert(tabs, Tab(tabs.active.directory, nil))
      tabs.active = last(tabs)
      cursor:reset()
      numbers.start = 1
      open_directory(tabs.active.directory)
    elseif key == 'w' then
      love.event.clear()
      local active_tab_i = 0
      for i,v in ipairs(tabs) do
        if v == tabs.active then
          active_tab_i = i
          break
        end
      end
      table.remove(tabs, active_tab_i)
      if #tabs == 0 then
        love.event.push('quit', 0)
      end
      active_tab_i = active_tab_i - 1
      active_tab_i = 1 + (active_tab_i-1) % #tabs
      tabs.active = tabs[active_tab_i]
    end
  elseif love.keyboard.isDown('lalt') then
    if key == 'left' then
      cursor.position[2] = text:find_word_beg(cursor)
    elseif key == 'right' then
      cursor.position[2] = text:find_word_end(cursor)
    elseif key == 'up' then
      cursor.position[1] = cursor.position[1] - lines_on_screen()
    elseif key == 'down' then
      cursor.position[1] = cursor.position[1] + lines_on_screen()
    elseif key == 'backspace' then
      local toremove = cursor.position[2] - text:find_word_beg(cursor)
      text:remove(cursor.position[3] - toremove + 1, cursor.position[3])
      cursor.position[2] = cursor.position[2] - toremove
    elseif key == 'return' then
      local wb = text:find_word_beg(cursor)
      local word = text:get_line(cursor.position[1]):sub(wb + 1, text:find_word_end(cursor))
      if not completion:contains(word) then
        completion:reset()
      end
      if #completion.words == 0 then
        completion:fill(word, text.str)
      end
      -- remove old word
      local toremove = cursor.position[2] - wb
      text:remove(cursor.position[3] - toremove + 1, cursor.position[3])
      cursor.position[2] = wb
      cursor.position[3] = cursor.position[3] - toremove
      -- insert completion word
      local ins = completion:next()
      text:insert(ins, cursor.position[3])
      cursor.position[2] = cursor.position[2] + #ins
    end
  elseif love.keyboard.isDown('lctrl') then
    if key == 'tab' then
      local active_tab_i = 0
      for i,v in ipairs(tabs) do
        if v == tabs.active then 
          active_tab_i = i
          break
        end
      end
      active_tab_i = active_tab_i + 1
      active_tab_i = 1 + (active_tab_i-1) % #tabs
      tabs.active = tabs[active_tab_i]
      if tabs.active.file then
        open_file(tabs.active.file)
      else
        open_directory(tabs.active.directory)
      end
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
        cursor.position = selection:remove(text, cursor.position)
      else
        if cursor.position[2] == 0 then 
          cursor.position[2] = #text:get_line(cursor.position[1] - 1)
          cursor.position[1] = cursor.position[1] - 1
        else
          cursor.position[2] = cursor.position[2] - 1
        end
        text:remove(cursor.position[3], cursor.position[3])
      end
    elseif key == 'return' then
      if not tabs.active.file then 
        open(text:get_line(cursor.position[1]))
        return 
      end
      local cur_str = text:get_line(cursor.position[1])
      local i,j = cur_str:find('%s*')
      local indentation = '\n'..cur_str:sub(i,j)
      text:insert(indentation, cursor.position[3])
      cursor.position[1] = cursor.position[1] + 1
      cursor.position[2] = #indentation - 1   
    elseif key == 'tab' then
      local ins = tab_replacement
      text:insert(ins, cursor.position[3])
      cursor.position[2] = cursor.position[2] + #ins
    elseif key == 'escape' then
      tabs.active.file = nil
      open_directory(tabs.active.directory)
    end
  end
  if love.keyboard.isDown('lshift') then
    if not selection.active then
      selection.active = true
      selection:set_beg(cursor.position)
    end
  end
  cursor:update(text, numbers)
end

function love.keyreleased(key, isrepeat)
  if not (love.keyboard.isDown('lshift') or key == 'lshift') then
    selection.active = false
    selection:set_beg(cursor.position)
  end
end

function love.textinput(t)
  if not tabs.active.file then return end
  if love.keyboard.isDown('lshift') then
    selection.active = false
  end
  if selection.active and math.abs(selection.beg_pos[3] - cursor.position[3]) > 0 then
    cursor.position = selection:remove(text, cursor.position)
    selection.active = false
  end
  text:insert(t, cursor.position[3])
  cursor.position[2] = cursor.position[2] + #t
  cursor:update(text, numbers)
end

function love.wheelmoved(x,y)
  numbers.start = clamp(numbers.start + y, 1, text:count_lines())
end

function love.mousepressed(mx, my, button, istouch, presses)
  if mx > numbers.width then
    cursor.position = {
      numbers.start + math.floor((my - tabs.height) / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' ')),
      0
    }
    cursor:update(text, numbers)
  end
  selection.active = true
  if presses == 1 then
    selection:set_beg(cursor.position)
  elseif presses == 2 then
    cursor.position[2] = text:find_word_beg(cursor)
    cursor:update(text, numbers)
    selection:set_beg(cursor.position)
    cursor.position[2] = text:find_word_end(cursor)
  elseif presses == 3 then
    selection.beg_pos = {cursor.position[1], 0, cursor.position[3] - cursor.position[2]}
    cursor.position[2] = #text:get_line(cursor.position[1])
  end
  cursor:update(text, numbers)
end

function love.mousemoved(mx, my, dx, dy)
  if love.mouse.isDown(1) then
    cursor.position = {
      numbers.start + math.floor((my - tabs.height) / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' '))
    }
    cursor:update(text, numbers)
  end
end

function love.wheelmoved(x,y)
  numbers.start = clamp(numbers.start - y, 1, text:count_lines())
end

function love.filedropped(file)
  open_file(file:getFilename())
end

function love.directorydropped(path)
  open_directory(path..'/')
end

function love.quit()
  return quit
end


--[[

  TODO:
1. check and highlight unmatched parenthesis
3. go to line (status bar)
5. search 

]]
