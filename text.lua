separators = '[%s%+%-=%*/:;%%,%.%(%)%[%]{}]'

function Text()
  local new = {}
  new.str = ''
  
  function new:get_line(n)
    local line_beg = 0
    for i=1,n-1 do
      line_beg = self.str:find('\n', line_beg+1)
    end
    local line_end = self.str:find('\n', line_beg+1) or 1
    return self.str:sub(line_beg+1, line_end-1)
  end

  function new:count_lines()
    local res = 0
    for _line in self.str:gmatch('\n') do
      res = res + 1
    end
    return res
  end

  function new:insert(t, pos)
    local before = self.str:sub(1, pos)
    local after  = self.str:sub(pos + 1, -1)
    self.str = before..t..after
  end

  function new:remove(pos1, pos2)
    pos1 = clamp(pos1-1, 0, pos1-1)
    pos2 = clamp(pos2+1, pos2+1, #self.str)
    local before = self.str:sub(1, pos1)
    local after = self.str:sub(pos2, -1)
    self.str = before..after
  end

  function new:highlight(first_line)
    local str = ''
    local i = 1
    for line in self.str:gmatch('.-\n') do
      if i >= first_line then
        str = str..line
      end
      if i > first_line + lines_on_screen() then break end
      i = i+1
    end
    local indexes = {}
    for _,hl_entry in ipairs(self.mode) do
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
  
  function new:draw(x,y, first_line)
    love.graphics.print(self:highlight(first_line), x, y)
  end

  function new:find_word_end(cursor)
    local line = self:get_line(cursor.position[1])..' '
    local i,j = line:find('.-'..separators, cursor.position[2] + 2)
    return (j or #line) - 1
  end

  function new:find_word_beg(cursor)
    local line = self:get_line(cursor.position[1]):sub(1, cursor.position[2] - 1)
    local i,j = line:find('.*'..separators)
    return (j or 0)
  end

  return new
end

return Text()