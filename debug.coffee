
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
# rom = load_rom 'roms/tetris.gb'
# rom = load_rom 'roms/SuperMarioLand.gb'
# rom = load_rom 'roms/zelda.gb'
# rom = load_rom 'roms/BubbleBobble.gb'
# rom = load_rom 'roms/halt_bug.gb'
# rom = load_rom 'roms/Bomberman.gb'

gb.set_rom rom

# show disassembly

update_disasm = ->
  div = document.getElementById 'code'
  formatted = []
  pc = gb.cpu.PC
  key_index = ((Object.keys gb.asm).indexOf String pc)
  if key_index == -1 # possible halt bug
    key_index = ((Object.keys gb.asm).indexOf String ++pc)
  key_index = Math.max 0, key_index - 20
  i = 0
  while i < 40
    key = (Object.keys gb.asm)[key_index++]
    row = gb.asm[key]
    color = '#fff'
    if 1 * key == pc
      color = '#bad'
    if (1 * key) in gb.breakpoints
      if color == '#bad'
        color = '#e88'
      else
        color = '#eaa'

    row = (row.split ' ').join '&nbsp;'
    row = '<span id="' + key + '" onclick="gb_breakpoint(' + key + ')" style="background-color: ' + color + '; width:100%;display:inline-block">' + row + '</span>'
    formatted.push row
    i++
  div.innerHTML = formatted.join '<br>'
  div.scrollTop = div.scrollHeight * 0.33
  div = document.getElementById 'regs'
  div.innerHTML = do gb.dump_registers + ' frq:' + gb.timer.freq_counter + ' lcd:' + gb.lcd.ly + ':' + gb.lcd.lcd_cycles

do gb.disasm
do update_disasm


saved = window.localStorage.getItem 'gb_breakpoints'
gb.breakpoints = if saved then (saved.split ',').map (v) -> parseInt v else []

# ask a refresh after a breakpoint
gb.break_actions = ->
  do gb.disasm
  do update_disasm
  do mem_dump
  document.getElementById 'run'
    .disabled = ''

# populate dropdowns
hi = document.getElementById 'hi'
lo = document.getElementById 'lo'
for i in [0..0xff]
  opt1 = document.createElement 'option'
  opt2 = do opt1.cloneNode
  opt1.text = opt2.text = i.x 2
  hi.appendChild opt1
  lo.appendChild opt2

mem_dump = (addr = -1) ->
  hi = document.getElementById 'hi'
  lo = document.getElementById 'lo'
  if addr == -1
    addr = parseInt hi.options[hi.selectedIndex].text, 16
    addr = (addr << 8) | parseInt lo.options[lo.selectedIndex].text, 16
    window.localStorage.setItem 'gb_dump_addr', addr
  dump = []
  i = addr
  while i < addr + 32
    dump.push ((gb.mem.r i).x 2)
    i++
  document.getElementById 'dump'
    .innerHTML = dump.join ' '

saved = window.localStorage.getItem 'gb_dump_addr'
hi.selectedIndex = saved >> 8
lo.selectedIndex = saved & 0xff
do mem_dump

window.gb_step = ->
  gb.running = false
  do gb.step
  do gb.disasm
  do update_disasm
  do mem_dump
  document.getElementById 'run'
    .disabled = ''

window.gb_start = ->
  document.getElementById 'run'
    .disabled = 'disabled'
  do gb.start


window.gb_breakpoint = (id) ->
  onpc = gb.cpu.PC == id
  if id in gb.breakpoints
    gb.breakpoints.splice (gb.breakpoints.indexOf id), 1
    document.getElementById id
      .style.backgroundColor = if onpc then '#bad' else '#fff'
  else
    gb.breakpoints.push id
    document.getElementById id
      .style.backgroundColor = if onpc then '#e88' else '#eaa'
  window.localStorage.setItem 'gb_breakpoints', gb.breakpoints

window.gb_reset = ->
  do gb.cpu.reset
  do gb.disasm
  do update_disasm
  do mem_dump

window.gb_goto = (addr) ->
  gb.cpu.PC = addr & 0xffff
  do gb.disasm
  do update_disasm


btns = ['bright', 'bleft', 'bup', 'bdown', 'ba', 'bb', 'bselect', 'bstart']
for btn, i in btns
  el = document.getElementById btn
  el.dataset.gbid = i
  el.addEventListener 'touchstart', -> gb.joypad @dataset.gbid, true
  el.addEventListener 'touchend', -> gb.joypad @dataset.gbid, false
  el.addEventListener 'mousedown', -> gb.joypad @dataset.gbid, true
  el.addEventListener 'mouseup', -> gb.joypad @dataset.gbid, false

# right, left, up, down, space, ctrl, tab, enter
keys = [39, 37, 38, 40, 32, 17, 9, 13]
document.onkeydown = (e) -> if e.keyCode in keys then gb.joypad (keys.indexOf e.keyCode), true
document.onkeyup = (e) ->
  if e.keyCode in keys then gb.joypad (keys.indexOf e.keyCode), false
  if e.keyCode == 118 then do gb_step  # F7
  if e.keyCode == 120 then do gb_start # F9

window.gb_mem_dump = -> do mem_dump

