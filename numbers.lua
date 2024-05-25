local numbers = {}
numbers.start = 1
numbers.width = 0

function numbers:str(text, font)
  local end_number = self.start + lines_on_screen()
  local delimiter = '|'
  self.width = font:getWidth(' '..end_number..delimiter)
  local last_number = text:count_lines()
  local res = ''
  for i=self.start,math.min(end_number, last_number) do
    res = res..string.format(' %d%s\n', i, delimiter)
  end
  for i=last_number,end_number do
    res = res..string.format('~ %s\n', delimiter)
  end
  return res
end

return numbers