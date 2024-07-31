local highlight = require 'highlight'

Text = {}

function Text:get_line(n)
  local line_beg = 0
  for i=1,n-1 do
    line_beg = self.str:find('\n', line_beg+1)
    if line_beg == nil then 
      print(self.str, n, line_beg)
      return nil 
    end
  end
  local line_end = self.str:find('\n', line_beg+1) or 1
  return self.str:sub(line_beg+1, line_end-1)
end

function count_lines(str)
  local res = 0
  for _line in str:gmatch('\n') do
    res = res + 1
  end
  return res
end

function Text:clear()
  self.str = ''
  self.lines = 0
  self.dirty = false
end

function Text:insert(t, pos)
  local before = self.str:sub(1, pos)
  local after  = self.str:sub(pos + 1, -1)
  self.str = before..t..after
  self.dirty = true
  self:update(prev_first_line)
  self.lines = self.lines + count_lines(t)
end

function Text:remove(pos1, pos2)
  pos1 = clamp(pos1, 0, pos1)
  pos2 = clamp(pos2, pos2, #self.str)
  local before = self.str:sub(1, pos1-1)
  local after = self.str:sub(pos2+1, -1)
  local between = self.str:sub(pos1, pos2)
  self.str = before..after
  self.dirty = true
  self:update(prev_first_line)
  self.lines = self.lines - count_lines(between)
end

function Text:highlight(first_line)
  local str = ''
  local i = 1
  for line in self.str:gmatch('.-\n') do
    if i >= first_line then
      str = str..line
    end
    if i > first_line + lines_on_screen() then break end
    i = i + 1
  end
  if self.mode == nil or highlight[self.mode] == nil then
    return str
  end
  local indexes = {}
  for _,hl_entry in ipairs(highlight[self.mode]) do
    local i,j = str:find(hl_entry.to_hl, 0)
    while i do
      if hl_entry.rule(str, i, j) then 
        table.insert(indexes, {i, j, hl_entry.color})
      end
      i,j = str:find(hl_entry.to_hl, j+1)
    end
  end
  local total_lines = math.max(self.lines, 100)
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

prev_first_line = 0
highlighted = {}

function Text:update(first_line, optional)
  if (not optional) or first_line ~= prev_first_line then
    highlighted = self:highlight(first_line)
    self.drawable_text:set(highlighted)
  end
  prev_first_line = first_line
end

function Text:draw(x, y)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(self.drawable_text, x, y)
end

function Text:find_word_end(cursor_pos)
  local line = self:get_line(cursor_pos[1])..' '
  local i,j = line:find('.-'..separators, cursor_pos[2] + 1)
  return (j or #line) - 1
end

function Text:find_word_beg(cursor_pos)
  local line = self:get_line(cursor_pos[1]):sub(1, cursor_pos[2] - 1)
  local i,j = line:find('.*'..separators)
  return (j or 0) + 1
end


function Text:new()
  local new = setmetatable({}, {__index = Text})
  new.drawable_text = love.graphics.newText(font)
  new.str = ''
  new.dirty = false
  new.lines = 0
  return new
end
