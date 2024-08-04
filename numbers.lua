Numbers = {}

function Numbers:str()
  local last_on_screen = self.first + lines_on_screen()
  local delimiter = '|'
  local empty_line = string.format('~ %s\n', delimiter)
  self.width = font:getWidth(' '..last_on_screen..delimiter)
  local last_in_text = self.text.lines
  local res = ''
  for i=self.first,math.min(last_on_screen, last_in_text) do
    res = res..string.format(' %d%s\n', i, delimiter)
  end
  for i=last_in_text,last_on_screen do
    res = res..empty_line
  end
  return res
end

local prev_first = 0
function Numbers:update()
  if self.first ~= prev_first then
    self.drawable_text:setFont(font)
    self.drawable_text:setf(self:str(), self.width, 'right')
  end
end

function Numbers:draw(x, y)
  love.graphics.setColor(comment_color)
  love.graphics.draw(self.drawable_text, x, y)
end


function Numbers:new(text)
  local new = setmetatable({}, {__index = Numbers})
  new.first = 1
  new.width = 0
  new.text = text
  new.drawable_text = love.graphics.newText(font)
  return new
end