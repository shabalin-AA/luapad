function Tab(directory, file)
  local new = {}
  new.directory = directory
  new.file = file
  function new:title()
    return self.file or self.directory
  end
  return new
end