Selection = {}

function Selection:draw(font, cursor, numbers, y_offset)
  if not self.active then return end
  love.graphics.setColor(self.color)
  local fheight = font:getHeight()
  local fwidth = font:getWidth(' ')
  local p1, p2 = self.beg_pos, cursor.position
  if p2[3] < p1[3] then p1, p2 = p2, p1 end
  local fheight = font:getHeight()
  for line_i = p1[1], p2[1] do
    local y1 = (line_i + 0 - numbers.first) * fheight + y_offset
    local y2 = (line_i + 1 - numbers.first) * fheight + y_offset
    local x1 = numbers.width
    local x2 = love.graphics.getWidth()
    if line_i == p1[1] then x1 = p1[2] * fwidth + numbers.width end
    if line_i == p2[1] then x2 = p2[2] * fwidth + numbers.width end
    love.graphics.rectangle('fill', x1, y1, x2-x1, y2-y1)
  end
end

function Selection:str(str, end_pos)
  local p1 = self.beg_pos[3]
  local p2 = end_pos
  p1, p2 = math.min(p1, p2), math.max(p1, p2)
  return str:sub(p1 + 1, p2)
end

function Selection:set_beg(cursor_position)
  self.beg_pos = map(cursor_position, id)
end

function Selection:remove(text, cursor_position)
  local p1, p2 = self.beg_pos[3], cursor_position[3]
  p1, p2 = math.min(p1, p2), math.max(p1, p2)
  text:remove(p1 + 1, p2)
  if self.beg_pos[3] < cursor_position[3] then
    return map(self.beg_pos, id)
  end
  return cursor_position
end


function Selection:new()
  local new = setmetatable({}, {__index = Selection})
  new.color = {0.5, 0.5, 0.5}
  new.active = false
  -- begin position that copies cursor position
  new.beg_pos = {}
  return new
end