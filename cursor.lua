function Cursor()
  local cursor = {}
  cursor.position = {1,0,0} -- line, char in line, char in whole text
  cursor.t = os.clock() -- for blinking
  
  function cursor:reset()
    self.position = {1,0,0}
  end
  
  function cursor:blink()
    local elapsed = (os.clock() - self.t) % 0.1
    return 0 < elapsed and elapsed < 0.05 
  end
  
  function cursor:draw(numbers, font, y_offset)
    if self:blink() then
      love.graphics.setLineWidth(1)
      local x = numbers.width + self.position[2] * font:getWidth(' ')
      local y1 = (self.position[1] - numbers.start + 0)*font:getHeight() + y_offset
      local y2 = (self.position[1] - numbers.start + 1)*font:getHeight() + y_offset
      love.graphics.line(x,y1,x,y2)
      self.t = 0
    end
    local position_text = table.concat(self.position, ':')
    love.graphics.print(
      position_text, 
      love.graphics.getWidth()-font:getWidth(position_text), 
      love.graphics.getHeight()-font:getHeight()
    )
  end
  
  function cursor:update(text)
    self.position[1] = clamp(self.position[1], 1, text:count_lines())
    self.position[2] = clamp(self.position[2], 0, #text:get_line(self.position[1]))
    self.position[3] = 0
    for i=1,self.position[1]-1 do
      self.position[3] = self.position[3] + #text:get_line(i) + 1
    end
    self.position[3] = self.position[3] + self.position[2]
    self.t = os.clock()
  end
  
  return cursor
end