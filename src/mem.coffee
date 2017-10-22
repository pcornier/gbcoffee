
class mem

  _mem = new Uint8Array 0x8000
  _rom = new Uint8Array 0x8000

  constructor: (gb) ->

    @gb = gb
    @_mem = _mem
    @_rom = _rom

    @_read_map = {}
    @_write_map = {}

    @ram_bank_ptr = 0
    @rom_bank_ptr = 1
    @banking_mode = 0
    @ext_ram_enable = false

    @bank_types =
      0: 'none'
      1: 'MBC1'
      2: 'MBC1'
      3: 'MBC1'
      5: 'MBC2'
      6: 'MBC2'

    for a in [0..0x10000]
      if a < 0x4000 # rom bank 0 - fixed home
        @_read_map[a] = 'rom_read'

        if a < 0x2000 # enable/disable ext ram
          @_write_map[a] = 'enable_disable_ext_ram'

        else if a < 0x4000 # select rom bank nb
          @_write_map[a] = 'select_bank_lo'

      else if a < 0x8000 # switchable rom bank - home
        @_read_map[a] = 'rom_bank_read'

        if a < 0x6000 # upper bits rom nb or ram bank nb
          @_write_map[a] = 'select_bank_hi'

        if a < 0x8000
          @_write_map[a] = 'select_banking_mode'

      else if a < 0xa000 # vram 8000-9fff
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'vram_write'

      else if a < 0xc000 # ext ram
        @_read_map[a] = 'ext_read'
        @_write_map[a] = 'ext_write'

      else if a < 0xd000 # wram bank 0
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'ram_write'

      else if a < 0xe000 # wram bank 1
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'ram_write'

      else if a < 0xfe00 # echo
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'mirror_write'

      else if a < 0xfea0 # OAM sprite attribute table
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'ram_write'

      else if a < 0xff00 # n/u
        @_read_map[a] = 'nu_read'
        @_write_map[a] = 'nu_write'

      else if a < 0xff80 # I/O

        if a == 0xff00 # joypad
          @_read_map[a] = 'joypad_read'
          @_write_map[a] = 'ram_write'

        else if a == 0xff04 # DIV write reset
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'div_write'

        else if a == 0xff05 # TIMA write
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'timer_write'

        else if a == 0xff07 # timer control TMC
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'timer_control_write'

        else if a == 0xff0f # int flags IF
          @_read_map[a] = 'IF_read'
          @_write_map[a] = 'ram_write'

        else if a == 0xff11 # NR11
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'NR11_write'

        else if a == 0xff13 # NR13
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'NR13_write'

        else if a == 0xff14 # NR14
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'NR14_write'

        else if a == 0xff16 # NR21
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'NR21_write'

        else if a == 0xff18 # NR23
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'NR23_write'

        else if a == 0xff19 # NR24
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'NR24_write'

        else if a == 0xff40 # lcd status
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'lcd_status_write'

        else if a == 0xff44 # scanline FY write reset
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'write_reset'

        else if a == 0xff46 # DMA transfer
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'DMA_transfer'

        else
          @_read_map[a] = 'ram_read'
          @_write_map[a] = 'ram_write'

      else if a < 0xffff # hram
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'ram_write'

      else if a == 0xffff # int enable reg
        @_read_map[a] = 'ram_read'
        @_write_map[a] = 'ram_write'


  @prop 'max_banks',
    get: -> _rom[0x148]

  @prop 'bank_type',
    get: -> @bank_types[_rom[0x147]]

  set_rom: (rom) ->
    _rom = rom
    @_rom = _rom
    if @bank_type != 'none'
      @mbc = new window[@bank_type] @
    else
      @mbc =
        ext_read: @ram_read
        ext_write: @ram_write
        enable_disable_ext_ram: @nothing
        select_bank_lo: @nothing
        select_bank_hi: @nothing
        select_banking_mode: @nothing

  nothing: ->

  NR11_write: (i, data) ->
    @gb.audio.sqr1_duty = ['00000001', '10000001', '10000111', '01111110'][data >> 6]
    _mem[i-0x8000] = data
  
  NR13_write: (i, data) ->
    @gb.audio.sqr1_frequency = (_mem[0x7f14] & 0x700) | data
    @gb.audio.sqr1_frequency = (0x800 - @gb.audio.sqr1_frequency) << 2
    _mem[i-0x8000] = data
    
  NR14_write: (i, data) ->
    @gb.audio.sqr1_frequency = (_mem[0x7f13] & 0xff) | ((data & 7) << 8)
    @gb.audio.sqr1_frequency = (0x800 - @gb.audio.sqr1_frequency) << 2
    @gb.audio.sqr1_vol = _mem[0x7f12] >> 4 # NR12
    _mem[i-0x8000] = data

  NR21_write: (i, data) ->
    @gb.audio.sqr2_duty = ['00000001', '10000001', '10000111', '01111110'][data >> 6]
    _mem[i-0x8000] = data
  
  NR23_write: (i, data) ->
    @gb.audio.sqr2_frequency = (_mem[0x7f19] & 0x700) | data
    @gb.audio.sqr2_frequency = (0x800 - @gb.audio.sqr2_frequency) << 2
    _mem[i-0x8000] = data
    
  NR24_write: (i, data) ->
    @gb.audio.sqr2_frequency = (_mem[0x7f18] & 0xff) | ((data & 7) << 8)
    @gb.audio.sqr2_frequency = (0x800 - @gb.audio.sqr2_frequency) << 2
    @gb.audio.sqr2_vol = _mem[0x7f17] >> 4 # NR22
    _mem[i-0x8000] = data

  lcd_status_write: (i, data) ->
    _mem[i-0x8000] = data

  ram_read: (i) -> _mem[i-0x8000]

  ram_write: (i, data) -> _mem[i-0x8000] = data

  vram_write: (i, data) -> _mem[i-0x8000] = data

  rom_read: (i) -> _rom[i]

  ext_read: (i) -> @mbc.ext_read i

  ext_write: (i, data) -> @mbc.ext_write i, data

  nu_read: -> 0 # DMG returns 0
  nu_write: ->

  rom_bank_read: (i) ->
    i -= 0x4000
    i += @rom_bank_ptr * 0x4000
    return _rom[i]

  timer_control_write: (i, data) ->
    @ram_write i, data

  timer_write: (i, data) ->
    @ram_write i, data

  div_write: (i, data) ->
    @ram_write i, 0

  div_read: (i) ->
    (@db.timer.DTIC >> 8) & 0xff

  mirror_write: (i, data) ->
    @_mem[i-0x8000] = data
    @_mem[i-0xa000] = data

  write_reset: (i, data) -> @ram_write(i, 0)

  joypad_read: ->
    stat = @ram_read 0xff00
    if stat & 0x10
      0xc0 | (stat & 0x30) | (@gb.joypad_status >> 4)
    else
      0xc0 | (stat & 0x30) | (@gb.joypad_status & 0xf)

  DMA_transfer: (i, data) ->
    src = data << 8
    for i in [0..160]
      @ram_write 0xfe00+i, @ram_read src+i

  IF_read: (i) ->
    (@ram_read i) | 0b11100000

  enable_disable_ext_ram: (i, data) -> @mbc.enable_disable_ext_ram i, data
  select_banking_mode: (i, data) -> @mbc.select_banking_mode i, data
  select_bank_lo: (i, data) -> @mbc.select_bank_lo i, data
  select_bank_hi: (i, data) -> @mbc.select_bank_hi i, data

  r: (i, word) ->
    i &= 0xffff
    if word
      h = (i + 1) & 0xffff
      (@[@_read_map[h]] h) << 8 | @[@_read_map[i]] i
    else
      @[@_read_map[i]] i

  w: (i, data) ->
    i &= 0xffff
    if data > 0xff
      @[@_write_map[i]] i, data & 0xff
      @[@_write_map[i+1]] i+1, data >> 8 & 0xff
    else
      @[@_write_map[i]] i, data

