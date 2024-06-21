function Search()
  local search = {}
  search.positions = {}
  search.iter = 0
  search.prev_word = nil
  
  function search:reset()
    self.positions = {}
    self.iter = 0
  end
  
  function search:fill(word, text)
    if #word == 0 then return end
    self:reset()
    for p1=1,text:count_lines() do
      local line = text:get_line(p1)
      if #line > #word then
        local _i,p2 = line:find(word)
        while p2 do
          local pos = {p1, p2, nil}
          table.insert(self.positions, pos)
          _i,p2 = line:find(word, p2+1)
        end
      end
    end
    self.iter = 1
  end
  
  function search:next()
    if #self.positions < 1 then return nil end
    self.iter = clamp(self.iter, 1, #self.positions)
    local res = self.positions[self.iter]
    self.iter = self.iter + 1
    if self.iter > #self.positions then self.iter = 1 end
    return res
  end
  
  return search
end