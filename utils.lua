local utils = {}


function utils.last(t)
  return t[#t]
end

function utils.map(t, f)
  local nt = {}
  for k,v in pairs(t) do
    nt[k] = f(v)
  end
  return nt
end

function utils.chunks(t, n)
  local nt = {}
  table.insert(nt, {})
  local k = 0
  for i,v in ipairs(t) do
    table.insert(utils.last(nt), v)
    k = k+1
    if k == n then 
      table.insert(nt, {})
      k = 0 
    end
  end
  table.remove(nt)
  return nt
end

function utils.ppm_export(pixels, fname)
  local file = io.open(fname, "wb")
  file:write(string.format("P6\n%d %d\n255\n", pixels.width, pixels.height))
  for i=1,pixels.height do
    for j=1,pixels.width do
      file:write(string.char(unpack(pixels[i][j])))
    end
  end
  file:close()
end

function utils.ppm_import(pixels, fname)
  local file = io.open(fname, "rb")
  local _format    = file:read()
  local sizes      = file:read()
  local _max_color = file:read()
  local tsizes = {}
  for w in string.gmatch(sizes, '%d+') do
    table.insert(tsizes, tonumber(w))
  end
  local width, height = tsizes[1], tsizes[2]
  local bytes = {}
  local color_components = 3 --rgb
  for i=1,width*height*color_components do
    bytes[i] = file:read(1)
  end
  local npixels = utils.chunks(
    utils.chunks(
      utils.map(bytes, string.byte), 
      color_components), 
    width
  )
  for i=1,height do
    if not pixels[i] then pixels[i] = {} end
    for j=1,width do
      pixels[i][j] = npixels[i][j]
    end
  end
  pixels.height = height
  pixels.width = width
  file:close()
end

function utils.read_file(fname)
  local file = io.open(fname, 'r')
  local res = file:read('*all')
  file:close()
  return res
end


return utils
