function Completion()
  local completion = {}
  completion.words = {}
  completion.iter = 0
  
  function completion:reset()
    completion.words = {}
    completion.iter = 2
  end
  
  function completion:contains(word)
    for _,v in ipairs(self.words) do
      if v == word then return true end
    end
    return false
  end
  
  function completion:append(word)
    if not self:contains(word) then 
      table.insert(self.words, word)
    end
  end
  
  function completion:next()
    self.iter = clamp(self.iter, 1, #self.words)
    local res = self.words[self.iter]
    self.iter = self.iter + 1
    if self.iter > #self.words then self.iter = 1 end
    return res
  end
  
  function completion:fill(word, str)
    table.insert(self.words, word)
    if #word < 1 then return end
    local i,j = str:find(separators..word)
    i = (i or 0)
    while j do
      j = str:find(separators, j)
      local found = str:sub(i+1, j-1)
      self:append(found)
      i,j = str:find(separators..word, j)
      i = (i or -1)
    end
  end
  
  return completion
end