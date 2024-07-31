Search = {}

function Search:reset()
  self.positions = {}
  self.iter = 0
end

function Search:fill(word, text)
  if #word == 0 then return end
  self:reset()
  for p1=1,text.lines do
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

function Search:next()
  if #self.positions < 1 then return nil end
  self.iter = clamp(self.iter, 1, #self.positions)
  local res = self.positions[self.iter]
  self.iter = self.iter + 1
  if self.iter > #self.positions then self.iter = 1 end
  return res
end


function Search:new()
  local new = setmetatable({}, {__index = Search})
  new.positions = {}
  new.iter = 0
  new.prev_word = nil
  return new
end