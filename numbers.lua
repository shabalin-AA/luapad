function Numbers()
  local numbers = {}
  numbers.first = 1
  numbers.width = 0
  
  function numbers:str(text, font)
    local last_on_screen = self.first + lines_on_screen()
    local delimiter = '|'
    local empty_line = string.format('~ %s\n', delimiter)
    self.width = font:getWidth(' '..last_on_screen..delimiter)
    local last_in_text = text:count_lines()
    local res = ''
    for i=self.first,math.min(last_on_screen, last_in_text) do
      res = res..string.format(' %d%s\n', i, delimiter)
      --local n = math.floor(font:getWidth(text:get_line(i)) / (love.graphics.getWidth() - self.width))
      --res = res..empty_line:rep(n)
    end
    for i=last_in_text,last_on_screen do
      res = res..empty_line
    end
    return res
  end
  
  return numbers
end