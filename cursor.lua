Cursor = {}

function Cursor:reset()
  self.position = {1,0,0}
end

function Cursor:blink()
  local elapsed = (os.clock() - self.t) % 0.1
  return 0 < elapsed and elapsed < 0.05 
end

function Cursor:draw(numbers, font, y_offset, text)
  if self:blink() then
    love.graphics.setLineWidth(1)
    local cur_line = text:get_line(self.position[1])
    local x = numbers.width + font:getWidth(cur_line:sub(0, self.position[2]))
    local y1 = (self.position[1] - numbers.first + 0)*font:getHeight() + y_offset
    local y2 = (self.position[1] - numbers.first + 1)*font:getHeight() + y_offset
    love.graphics.line(x,y1,x,y2)
    self.t = 0
  end
end

function Cursor:update(text)
  self.position[1] = clamp(self.position[1], 1, text.lines)
  self.position[2] = clamp(self.position[2], 0, #(text:get_line(self.position[1]) or ''))
  self.position[3] = 0
  for i=1,self.position[1]-1 do
    self.position[3] = self.position[3] + #text:get_line(i) + 1
  end
  self.position[3] = self.position[3] + self.position[2]
  self.t = os.clock()
end


function Cursor:new()
  local new = setmetatable({}, {__index = self})
  new.position = {1,0,0} -- line, char in line, char in whole text
  new.t = os.clock() -- for blinking
  return new
end
