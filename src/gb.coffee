
Number::x = (l) -> (this.toString 16).padStart l or 4, '0'

class gb

  constructor: ->
    @mem = new mem @
    @cpu = new z80 @
    @lcd = new lcd @
    @timer = new timer @
    @audio = new audio @

    @joypad_status = 0xff

    @total_cycles = 0
    @total_frames = 0
    @breakpoints = []
    @asm = {}

  # rom should be UInt8 array
  set_rom: (rom) -> @mem.set_rom rom

  color: (x, y, r, g, b) ->
  refresh: ->

  start: ->
    $ = @
    $.running = true
    $.runner = setInterval ->
      do $.frame
      if not $.running
        clearInterval $.runner
    ,1

  break: ->
    if @cpu.PC in @breakpoints
      @running = false
      do @break_actions

  break_actions: ->

  step: ->

    cycles = do @cpu.update

    if @cpu.IME
      IF = @mem.r 0xff0f
      IE = @mem.r 0xffff
      if IF
        if IF &  1 and IE &  1 then @cpu.interrupt  1 # vblank
        if IF &  2 and IE &  2 then @cpu.interrupt  2 # LCD
        if IF &  4 and IE &  4 then @cpu.interrupt  4 # timer
        if IF &  8 and IE &  8 then @cpu.interrupt  8 # serial
        if IF & 16 and IE & 16 then @cpu.interrupt 16 # joypad

    @timer.update cycles
    @lcd.update cycles
    # @audio.update cycles

    do @break
    cycles

  frame: ->
    @total_frames++
    max_frame_cycles = 69905
    while max_frame_cycles > 0 && @running == true
      cycles = do @step
      max_frame_cycles -= cycles
      @total_cycles += cycles

  joypad: (k, pressed) ->
    if pressed
      @joypad_status &= 0xff ^ (1 << k)
    else
      @joypad_status |= (1 << k)

  disasm: () ->
    start = 0
    end = 0xffff
    @asm = {}
    pc = @cpu.PC
    i = start
    while i <= end
      s = i
      opc = @mem.r i
      [opc, p1, p2] = @cpu.op[opc]

      sec = false
      if opc == 'cb_n'
        sec = true
        cb = @mem.r i + 1
        opc = @cpu.cbop[cb]
        p1 = @cpu.reg_names[cb & 0x7]

      [op, prm] = opc.split /_(.+)/

      if op == 'ldh' then prm = prm.replace 'ni', '(ff00+' + ((@mem.r i + 1).x 2) + ')=' + (@mem.r 0xff00 + @mem.r i+1).x 2
      if op.includes 'jr' then prm = prm.replace 'n',((@mem.r i + 1)+1 << 24) >> 24

      if prm
        if prm.includes 'nni' then prm = prm.replace 'nni', '(' + ((@mem.r i+1, 1).x 2) + ')=' + (@mem.r @mem.r i+1, 1).x 2
        if prm.includes 'nn' then prm = prm.replace 'nn', (@mem.r i+1, 1).x 2
        if prm.includes 'n' then prm = prm.replace 'n', (@mem.r i+1).x 2
        if prm.includes 'rri_' then prm = prm.replace 'rri', '(' + p1 + ')'
        if prm.includes '_rri' then prm = prm.replace 'rri', '(' + p2 + ')'
        if prm.includes 'rri_' then prm = prm.replace 'rri', '(' + p1 + ')'
        if prm.includes 'rri' then prm = prm.replace 'rri', '(' + p1 + ')'
        if prm.includes 'rr' then prm = prm.replace 'rr', p1
        if prm.includes 'rr' then prm = prm.replace 'rr', p2
        if prm.includes 'r_' then prm = prm.replace 'r', p1
        if prm.includes '_r' then prm = prm.replace 'r', (if p2 then p2 else p1)
        if prm.includes 'r' then prm = prm.replace 'r', (if p2 then p2 else p1)
        prm = prm.replace '_', ','

      e = i

      i++
      if opc.includes '_n' then i++
      if opc.includes 'nn' then i++
      if sec then i++

      hex = []
      for h in [s..i-1]
        hex.push (@mem.r h).x 2

      @asm[e] = do e.x + ':' + (hex.join ' ') + ('   '.repeat 3-hex.length) + ' ' + op + ' ' + (prm or '')

  dump_registers: ->
    regs = ''
    for r in ['A', 'F', 'B', 'C', 'D', 'E', 'HL']
      regs += ' ' + r + ':' + @cpu[r].x 2

    F = @cpu.F >> 4
    regs += ' SP:(' + do @cpu.SP.x + ')=' + do (@mem.r @cpu.SP, 1).x
    regs += ' ' + '-Z'[F>>3&1] + '-N'[F>>2&1] + '-H'[F>>1&1] + '-C'[F&1]
    regs += ' PC:' + do (@cpu.PC).x
    regs


