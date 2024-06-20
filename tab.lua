function Tab(directory, file)
  local new = {}
  new.directory = directory
  new.file = file
  new.text = nil
  new.cursor = nil
  function new:title()
    local res = self.file or self.directory
    if self.text.dirty then res = res..'*' end
    return res
  end
  return new
end