--------------------------------------------------------------------------------------------------- globals times
separators = '[#%s%+%-=%*/:;%%,%.%(%)%[%]{}\'\"]'

function lines_on_screen()
  return math.floor(love.graphics.getHeight() / font:getHeight()) + 1
end

require 'tab'
local utf8 = require 'utf8'

--------------------------------------------------------------------------------------------------- utils
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

function execute(cmd)
  local handle = io.popen(cmd)
  local content = handle:read('*all')
  return content
end

function current_user()
  return execute('whoami'):sub(1, -2)
end


--------------------------------------------------------------------------------------------------- tabs
local tabs = {}
tabs.font = love.graphics.newFont('Iosevka-Regular.ttc', 18)
local text = nil
local cursor = nil
local file = nil
local directory = nil
local numbers = nil
local selection = nil
local completion = nil
local search = nil

function change_tab(i)
  i = clamp(i, 1, #tabs)
  tabs.active = tabs[i]
  text = tabs.active.text
  cursor = tabs.active.cursor
  file = tabs.active.file
  directory = tabs.active.directory
  numbers = tabs.active.numbers
  selection = tabs.active.selection
  completion = tabs.active.completion
  search = tabs.active.search
  text:update(numbers.first)
end

function new_tab(directory)
  local tab = Tab:new(directory, nil)
  table.insert(tabs, tab)
  change_tab(#tabs)
  open_directory(directory)
end

function update_font()
  font_size = clamp(font_size, 2, 60)
  font = love.graphics.newFont(font_file, font_size)
  love.graphics.setFont(font)
end

--------------------------------------------------------------------------------------------------- opens
function open_file(path)
  tabs.active.file = path
  file = path
  text:clear()
  text:insert(read_file(path):gsub('\t', tab_replacement)..'\n', 0)
  local i,j = path:find('.+%.')
  local file_ext = nil
  if j then 
    file_ext = path:sub(j+1, -1)
  end
  text.mode = file_ext
  text:update(numbers.first)
end

function open_directory(path)
  local content = execute('ls -a '..path)
  text:clear()
  text:insert(content, 0)
  tabs.active.directory = path
  directory = path
  text.mode = nil
  love.window.setTitle(path)
  text:update(numbers.first)
end

function open(path)
  cursor:reset()
  numbers.first = 1
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
    print('ERROR: '..content)
    return 
  elseif content:find('directory') then
    open_directory(path..'/')
  elseif content:find('text') or content:find('empty') then
    open_file(path)
  end
end


--------------------------------------------------------------------------------------------------- load
function load_config()
  local home = love.filesystem.getUserDirectory()
  local config_file_path = '.luapad.conf.lua'
  local config_content = read_file(home..config_file_path)
  local  success, message = love.filesystem.write('config.lua', config_content, #config_content)
  require('config')
  -- config variables
  tab_replacement = tab_replacement or '    '
  font_size = font_size or 16
  font_file = font_file or 'Menlo.ttc'
end

function love.load()
  love.graphics.setBackgroundColor(back_color)
  love.keyboard.setKeyRepeat(true)
  load_config()
  update_font()
  new_tab('/Users/'..current_user()..'/')
end

--------------------------------------------------------------------------------------------------- update
function love.update(dt)
  text:update(numbers.first, true)
  numbers:update()
end

function update_cursor()
  cursor:update(text)
  local offscreen = 0
  local lower_bound = numbers.first
  local upper_bound = numbers.first + lines_on_screen() - 3
  if cursor.position[1] >= upper_bound then
    offscreen = cursor.position[1] - upper_bound
  elseif cursor.position[1] <= lower_bound then
    offscreen = cursor.position[1] - lower_bound
  end
  numbers.first = numbers.first + offscreen
end

--------------------------------------------------------------------------------------------------- draw
function love.draw()
  tabs.width = love.graphics.getWidth() / #tabs
  tabs.height = tabs.font:getHeight()
  tabs.active:draw(0, tabs.height)
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
    love.graphics.printf(title, tabs.font, x, y, tabs.width, 'center')
  end
end

function love.keypressed(key)
--------------------------------------------------------------------------------------------------- gui
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
      cursor.position[1] = text.lines
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
        selection.active = false
      end
    elseif key == 'v' then
      if selection.active then
        cursor.position = selection:remove(text, cursor.position)
      end
      local ins = love.system.getClipboardText()  
      text:insert(ins, cursor.position[3])
      cursor.position[2] = cursor.position[2] + #ins
    elseif key == 'a' then
      selection.active = true
      selection.beg_pos = {1,0,0}
      local last_line = text.lines
      cursor.position = {
        last_line,
        #text:get_line(last_line),
        #text.str
      }
    elseif key == 'backspace' then
      text:remove(cursor.position[3] - cursor.position[2] + 1, cursor.position[3])
      cursor.position[2] = 0
    elseif key == 'o' then
      open(text:get_line(cursor.position[1]))
    elseif key == 't' then
      new_tab(directory)
    elseif key == 'w' then
      love.event.clear()
      if #tabs == 0 then
        love.event.push('quit')
      end
      local active_tab_i = 0
      for i,v in ipairs(tabs) do
        if v == tabs.active then
          active_tab_i = i
          break
        end
      end
      local new_active = active_tab_i - 1
      new_active = 1 + (new_active-1) % #tabs
      change_tab(new_active)
      table.remove(tabs, active_tab_i)
    elseif key == 'd' then
      local str_content = text:get_line(cursor.position[1])
      text:insert('\n'..str_content, cursor.position[3])
      cursor.position[1] = cursor.position[1] + 1
    elseif key == ']' then
      if selection.active then
        local l1 = math.min(selection.beg_pos[1], cursor.position[1])
        local l2 = math.max(selection.beg_pos[1], cursor.position[1])
        cursor.position[1] = l1
        cursor.position[2] = 0
        update_cursor()
        local l_beg_pos = cursor.position[3]
        for i=l1,l2 do
          text:insert(tab_replacement, l_beg_pos)
          l_beg_pos = l_beg_pos + #text:get_line(i) + 1
        end
      else
        text:insert(tab_replacement, cursor.position[3] - cursor.position[2])
        cursor.position[2] = cursor.position[2]
      end
    elseif key == '[' then
      if selection.active then
        local l1 = math.min(selection.beg_pos[1], cursor.position[1])
        local l2 = math.max(selection.beg_pos[1], cursor.position[1])
        cursor.position[1] = l1
        cursor.position[2] = 0
        update_cursor()
        local l_beg_pos = cursor.position[3]
        for i=l1, l2 do
          local line = text:get_line(i)
          local j,k = line:find(tab_replacement)
          if j == 1 then
            text:remove(l_beg_pos + j, l_beg_pos + k)
          end
          l_beg_pos = l_beg_pos + #text:get_line(i) + 1
        end
      else
        local line = text:get_line(cursor.position[1])
        local j,k = line:find(tab_replacement)
        if j == 1 then
          local line_beg = cursor.position[3] - cursor.position[2]
          text:remove(line_beg + j, line_beg + k)
        end
      end
    elseif key == 'f' then
      if selection.active then
        local word = selection:str(text.str, cursor.position[3])
        selection.active = false      
        if #word > 0 and word ~= search.prev_word then
          search:reset()
          search:fill(word, text)
        end
      end
      cursor.position = search:next() or cursor.position
    end
--------------------------------------------------------------------------------------------------- alt
  elseif love.keyboard.isDown('lalt') then
    if key == 'left' then
      cursor.position[2] = clamp(cursor.position[2] - 1, 0, #text:get_line(cursor.position[1]))
      cursor.position[2] = text:find_word_beg(cursor.position) - 1
    elseif key == 'right' then
      cursor.position[2] = clamp(cursor.position[2] + 1, 0, #text:get_line(cursor.position[1]))
      cursor.position[2] = text:find_word_end(cursor.position)
    elseif key == 'up' then
      cursor.position[1] = cursor.position[1] - lines_on_screen()
    elseif key == 'down' then
      cursor.position[1] = cursor.position[1] + lines_on_screen()
    elseif key == 'backspace' then
      local line_beg = cursor.position[3] - cursor.position[2]
      local word_beg = text:find_word_beg(cursor.position)
      text:remove(line_beg + word_beg, cursor.position[3])
      cursor.position[2] = word_beg - 1
      cursor.position[3] = line_beg + cursor.position[2]
    elseif key == 'return' then
      local wb = text:find_word_beg(cursor.position)
      local we = text:find_word_end(cursor.position)
      local word = text:get_line(cursor.position[1]):sub(wb, we)
      if not completion:contains(word) then
        completion:reset()
      end
      if #completion.words == 0 then
        completion:fill(word, text.str)
      end
      -- remove old word
      local line_beg = cursor.position[3] - cursor.position[2]
      text:remove(line_beg + wb, cursor.position[3])
      cursor.position[2] = wb - 1
      cursor.position[3] = line_beg + cursor.position[2]
      -- insert completion word
      local ins = completion:next()
      text:insert(ins, cursor.position[3])
      cursor.position[2] = cursor.position[2] + #ins
    else
    end
--------------------------------------------------------------------------------------------------- ctrl
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
      change_tab(active_tab_i)
    end
--------------------------------------------------------------------------------------------------- just key
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
      local line = text:get_line(cursor.position[1])
      if selection.active then
        cursor.position = selection:remove(text, cursor.position)
      elseif line:find(tab_replacement, cursor.position[2] - #tab_replacement + 1) then
        text:remove(cursor.position[3] - #tab_replacement + 1, cursor.position[3])
        cursor.position[2] = cursor.position[2] - #tab_replacement
      else
        if cursor.position[2] == 0 then 
          if cursor.position[1] ~= 1 then
            cursor.position[2] = #text:get_line(cursor.position[1] - 1)
            cursor.position[1] = cursor.position[1] - 1
          else return end
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
    if not (love.keyboard.isDown('lshift') or key == 'lshift') then
      selection.active = false
      selection:set_beg(cursor.position)
    end
  end
  if love.keyboard.isDown('lshift') then
    if not selection.active then
      selection.active = true
      selection:set_beg(cursor.position)
    end
  end
  text:update(numbers.first)
  update_cursor()
end

--------------------------------------------------------------------------------------------------- textinput
function love.textinput(t)
  if not file then return end
  if love.keyboard.isDown('lshift') then
    selection.active = false
  end
  if selection.active and math.abs(selection.beg_pos[3] - cursor.position[3]) > 0 then
    cursor.position = selection:remove(text, cursor.position)
    selection.active = false
  end
  if #t == utf8.len(t) then
    text:insert(t, cursor.position[3])
    cursor.position[2] = cursor.position[2] + #t
  end
  update_cursor()
end

--------------------------------------------------------------------------------------------------- mouse
function love.wheelmoved(x,y)
  numbers.first = clamp(numbers.first + y, 1, text.lines)
end

function love.mousepressed(mx, my, button, istouch, presses)
  if mx > numbers.width then
    cursor.position = {
      numbers.first + math.floor((my - tabs.height) / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' ')),
      0
    }
    update_cursor()
  end
  selection.active = true
  if presses == 1 then
    selection:set_beg(cursor.position)
  elseif presses == 2 then
    cursor.position[2] = text:find_word_beg(cursor.position) - 1
    update_cursor()
    selection:set_beg(cursor.position)
    cursor.position[2] = text:find_word_end(cursor.position)
  elseif presses == 3 then
    selection.beg_pos = {cursor.position[1], 0, cursor.position[3] - cursor.position[2]}
    cursor.position[2] = #text:get_line(cursor.position[1])
  end
  update_cursor()
end

function love.mousemoved(mx, my, dx, dy)
  if love.mouse.isDown(1) then
    cursor.position = {
      numbers.first + math.floor((my - tabs.height) / font:getHeight()),
      math.floor((mx - numbers.width) / font:getWidth(' '))
    }
    update_cursor()
  end
end

function love.wheelmoved(x,y)
  numbers.first = clamp(numbers.first - y, 1, text.lines)
end

--------------------------------------------------------------------------------------------------- file drop
function love.filedropped(file)
  open_file(file:getFilename())
end

function love.directorydropped(path)
  open_directory(path..'/')
end


--[[

  TODO:
1. check and highlight unmatched parenthesis
3. go to line (status bar)
4. line wrapping

]]
