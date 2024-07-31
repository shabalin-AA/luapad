require 'text'
require 'cursor'
require 'numbers'
require 'selection'
require 'completion'
require 'search'


Tab = {}

function Tab:title()
  local res = self.directory
  if self.file then
    local i,j = self.file:find('.*/')
    res = self.file:sub(j+1, -1)
    if self.text.dirty == true then res = res..'*' end
  end
  return res
end

function Tab:draw(x, y)
  -- back
  love.graphics.setColor(back_color)
  local width = love.graphics.getWidth() - x
  local height = love.graphics.getHeight() - y - font:getHeight()
  love.graphics.rectangle('fill', x, y, width, height)
  love.graphics.setColor(map(back_color, function (x) return x -0.02 end))
  love.graphics.rectangle(
    'fill', 
    0, y + (self.cursor.position[1] - self.numbers.first) * font:getHeight(), 
    love.graphics.getWidth(), font:getHeight()
  )
  -- numbers
  self.numbers:draw(x,y)
  -- selection
  self.selection:draw(font, self.cursor, self.numbers, y)
  -- text
  love.graphics.setColor({1,1,1})
  self.text:draw(x + self.numbers.width, y, self.numbers.first, wrap)
  -- cursor
  love.graphics.setColor(text_color)
  self.cursor:draw(self.numbers, font, y)
  local position_text = table.concat(self.cursor.position, ':')
  love.graphics.print(
    position_text, 
    love.graphics.getWidth()-font:getWidth(position_text), 
    love.graphics.getHeight()-font:getHeight()
  )
  -- scroll bar
  love.graphics.setColor({0.5, 0.5, 0.5})
  local scroll_width = font:getWidth(' ') / 2
  local lines_total = self.text.lines + lines_on_screen()
  love.graphics.rectangle(
    'fill', 
    love.graphics.getWidth() - scroll_width,
    y + height * (self.numbers.first-1) / lines_total,
    scroll_width,
    height * lines_on_screen() / lines_total
  )
end


function Tab:new(directory, file)
  local new = setmetatable({}, {__index = Tab})
  new.directory = directory
  new.file = file
  new.text = Text:new()
  new.cursor = Cursor:new()
  new.numbers = Numbers:new(new.text)
  new.selection = Selection:new()
  new.completion = Completion:new()
  new.search = Search:new()
  return new
end