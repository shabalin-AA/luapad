require 'text'

local status_bar = {}
status_bar.active = false
status_bar.str = ''
status_bar.x = 0
status_bar.y = 0

function status_bar:draw()
  love.graphics.print(self.str, self.x, self.y)
end

return status_bar
