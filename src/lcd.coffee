
class lcd

  constructor: (gb) ->
    @gb = gb
    @scanline = 0
    @lcd_cycles = 0
    @scanline_colors = []

  @prop 'lcd_on',      get: -> (@gb.mem.r 0xff40) & 0b10000000
  @prop 'win_map',     get: -> (@gb.mem.r 0xff40) & 0b01000000
  @prop 'win_on',      get: -> (@gb.mem.r 0xff40) & 0b00100000
  @prop 'data_select', get: -> (@gb.mem.r 0xff40) & 0b00010000
  @prop 'bg_map',      get: -> (@gb.mem.r 0xff40) & 0b00001000
  @prop 'spr_16',      get: -> (@gb.mem.r 0xff40) & 0b00000100
  @prop 'spr_on',      get: -> (@gb.mem.r 0xff40) & 0b00000010
  @prop 'bg_on',       get: -> (@gb.mem.r 0xff40) & 0b00000001

  @prop 'status',
    get: -> @gb.mem.r 0xff41
    set: (v) -> @gb.mem.w 0xff41, v

  @prop 'control',
    get: -> @gb.mem.r 0xff40

  @prop 'mode',
    get: -> @status & 3
    set: (i) ->
      @status = (@status & 252) | i
      @gb.mem.w 0xff41, @status

  @prop 'scy',
    get: -> @gb.mem.r 0xff42

  @prop 'scx',
    get: -> @gb.mem.r 0xff43

  @prop 'wiy',
    get: -> @gb.mem.r 0xff4a

  @prop 'wix',
    get: -> (@gb.mem.r 0xff4b) - 7

  @prop 'ly',
    get: -> @gb.mem.r 0xff44


  render_scanline: ->

    if @bg_on
      do @render_bg

    if @spr_on
      do @render_sprites


  render_sprites: ->

    spr16 = @spr_16
    for i in [0..39]

      idx = 0xfe00 + i * 4
      yp = (@gb.mem.r idx) - 16
      xp = (@gb.mem.r idx + 1) - 8
      tl = @gb.mem.r idx + 2
      at = @gb.mem.r idx + 3
      xf = at & 0b00100000
      yf = at & 0b01000000
      yz = if spr16 then 16 else 8
      sb = at & 0b10000000

      if (@scanline >= yp) and (@scanline < yp + yz)

        ys = @scanline - yp
        if yf then ys = yz - ys

        ys *= 2
        addr = 0x8000 + (tl * 16) + ys
        d1 = @gb.mem.r addr
        d2 = @gb.mem.r addr + 1

        for p in [0..7]

          x = xp + 7 - p

          if sb
            c = @scanline_colors[x]
            if c != 0 then continue

          bit = p
          if xf then bit = 7 - bit
          c1 = (d1 & (1 << bit)) > 0
          c2 = (d2 & (1 << bit)) > 0
          col = (c2 << 1) | c1
          if col == 0 then continue

          pal_addr = if at & 0b10000 then 0xff49 else 0xff48
          pal = @gb.mem.r pal_addr
          col = (pal & (3 << (col << 1))) >> (col << 1)

          c = [255, 150, 100, 0][col]

          @gb.color x, @scanline, c, c, c


  render_bg: ->

    win = false

    if @win_on # win enabled
      if @scanline > @wiy
        win = true

    data = if @data_select then 0x8000 else 0x8800

    yp = @scanline

    if win
      map = if @win_map then 0x9c00 else 0x9800
      yp -= @wiy
    else
      map = if @bg_map then 0x9c00 else 0x9800
      yp = (yp + @scy) & 0xff

    tr = ((yp / 8) << 0) * 32
    scx = @scx
    wix = @wix

    @scanline_colors = []
    for x in [0..160]

      xp = (x + scx) & 0xff
      if win and x >= wix then xp = x - wix

      tc = (xp / 8) << 0
      tn = @gb.mem.r map + tr + tc

      if data == 0x8800
        tn = (tn << 24) >> 24
        tloc = data + (tn+128) * 16 # bank 2/3
      else
        tloc = data + tn * 16 # bank 1/2

      line = (yp % 8) * 2

      t1 = @gb.mem.r tloc + line
      t2 = @gb.mem.r tloc + line + 1

      bit = 7 - (xp % 8)
      c1 = (t1 & (1 << bit)) > 0
      c2 = (t2 & (1 << bit)) > 0
      col = (c2 << 1) | c1

      pal = @gb.mem.r 0xff47
      col = (pal & (3 << (col << 1))) >> (col << 1)
      @scanline_colors.push col

      c = [255, 150, 100, 0][col]
      @gb.color x, @ly, c, c, c


  update: (cpu_cycles) ->

    if @lcd_on
      @lcd_cycles += cpu_cycles

    else
      @lcd_cycles = 0
      @gb.mem.w 0xff44, 0
      @mode = 0
      return

    old_mode = @mode
    irq = false

    if @scanline < 144

      if @lcd_cycles < 80
        @mode = 2
        irq = @status & 0b00100000

      else if @lcd_cycles < 252
        @mode = 3

      else
        @mode = 0
        irq = @status & 0b00001000

    else
      @mode = 1
      irq = @status & 0b00010000

    if old_mode != @mode and irq
      @gb.cpu.irq 1

    if @scanline == @gb.mem.r 0xff45
      @status |= 0b100
      if @status & 0b01000000 then @gb.cpu.irq 1
    else
      @status &= ~0b100

    # end of scanline
    if @lcd_cycles >= 456

      @lcd_cycles = 0
      @scanline += 1

      # bypass scanline reset
      @gb.mem.ram_write 0xff44, @scanline

      if @scanline == 144 #vblank
        do @gb.refresh
        @gb.cpu.irq 0
        @status = (@status & 0xfc) | 1

      else if @scanline > 153
        @scanline = 0
        @gb.mem.w 0xff44, @scanline

      else if @scanline < 144
        do @render_scanline
