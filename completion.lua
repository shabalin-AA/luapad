Completion = {}  

function Completion:reset()
  self.words = {}
  self.iter = 2
end

function Completion:contains(word)
  for _,v in ipairs(self.words) do
    if v == word then return true end
  end
  return false
end

function Completion:append(word)
  if not self:contains(word) then 
    table.insert(self.words, word)
  end
end

function Completion:next()
  self.iter = clamp(self.iter, 1, #self.words)
  local res = self.words[self.iter]
  self.iter = self.iter + 1
  if self.iter > #self.words then self.iter = 1 end
  return res
end

function Completion:fill(word, str)
  table.insert(self.words, word)
  if #word < 1 then return end
  local i,j = str:find(word)
  if i ~= 1 then
    i,j = str:find(separators..word)
  else
    i = i-1
  end
  i = (i or 0)
  while j do
    j = str:find(separators, j)
    local found = str:sub(i+1, j-1)
    self:append(found)
    i,j = str:find(separators..word, j)
    i = (i or -1)
  end
end


function Completion:new()
  local new = setmetatable({}, {__index = Completion})
  new.words = {}
  new.iter = 0
  return new
end