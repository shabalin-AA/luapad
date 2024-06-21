function Numbers()
  local numbers = {}
  numbers.start = 1
  numbers.width = 0
  
  function numbers:str(text, font)
    local last_on_screen = self.start + lines_on_screen()
    local delimiter = '|'
    self.width = font:getWidth(' '..last_on_screen..delimiter)
    local last_in_text = text:count_lines()
    local res = ''
    for i=self.start,math.min(last_on_screen, last_in_text) do
      res = res..string.format(' %d%s\n', i, delimiter)
    end
    for i=last_in_text,last_on_screen do
      res = res..string.format('~ %s\n', delimiter)
    end
    return res
  end
  
  return numbers
end