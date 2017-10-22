
gb = new gb()

# gfx things
canvas = document.getElementById 'screen'
ctx = canvas.getContext '2d'
ctx.imageSmoothingEnabled = false
screen = ctx.createImageData 160, 144

# register a color function
gb.color = (x, y, r, g, b) ->
  index = 4 * (y * 160 + x)
  screen.data[index  ] = r
  screen.data[index+1] = g
  screen.data[index+2] = b
  screen.data[index+3] = 255

# register a refresh function
gb.refresh = -> ctx.putImageData screen, 0, 0

# load file using XMLHttpRequest
load_rom = (uri) ->
  req = new XMLHttpRequest
  req.open 'GET', uri, false
  req.overrideMimeType 'text\/plain; charset=x-user-defined'
  req.send(null)
  req.responseText
    .split ''
    .map (c) -> 0xff & c.charCodeAt 0

rom = load_rom 'roms/cpu_instrs.gb'
gb.set_rom rom

# right, left, up, down, space, ctrl, tab, enter
keys = [39, 37, 38, 40, 32, 17, 9, 13]
document.onkeydown = (e) -> if e.keyCode in keys then gb.joypad (keys.indexOf e.keyCode), true
document.onkeyup = (e) ->
  if e.keyCode in keys then gb.joypad (keys.indexOf e.keyCode), false

do gb.start