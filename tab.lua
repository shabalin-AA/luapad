require 'text'
require 'cursor'
require 'numbers'
require 'selection'
require 'completion'
require 'search'

function Tab(directory, file)
  local tab = {}
  tab.directory = directory
  tab.file = file
  tab.text = Text()
  tab.cursor = Cursor()
  tab.numbers = Numbers()
  tab.selection = Selection()
  tab.completion = Completion()
  tab.search = Search()
  
  function tab:title()
    local res = self.file or self.directory
    if self.text.dirty then res = res..'*' end
    return res
  end
  
  function tab:draw(x, y)
    -- back
    love.graphics.setColor(back_color)
    local width = love.graphics.getWidth() - x
    local height = love.graphics.getHeight() - y - font:getHeight()
    love.graphics.rectangle('fill', x, y, width, height)
    -- numbers
    love.graphics.setColor(comment_color)
    love.graphics.printf(
      self.numbers:str(self.text, font), 
      x, y, 
      self.numbers.width, 
      'right'
    )
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
    local lines_total = self.text:count_lines() + lines_on_screen()
    love.graphics.rectangle(
      'fill', 
      love.graphics.getWidth() - scroll_width,
      y + height * (self.numbers.first-1) / lines_total,
      scroll_width,
      height * lines_on_screen() / lines_total
    )
  end
  
  return tab
end