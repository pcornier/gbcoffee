class window.MBC1

  constructor: (mem) -> @mem = mem

  enable_disable_ext_ram: (addr, data) ->
    if data & 0xff == 0x0a
        @mem.ext_ram_enable = true
    else
        @mem.ext_ram_enable = false

  select_bank_lo: (addr, data) ->
    if data & 0xf == 0 then data++
    @mem.rom_bank_ptr = data & 0x1f

  select_bank_hi: (addr, data) ->
    if @mem.banking_mode == 'rom'
        @mem.rom_bank_ptr = ((data & 0x3) << 5) | (@mem.rom_bank_ptr & 0x1f)
    else
        @mem.ram_bank_ptr = data & 0x3

  select_banking_mode: (addr, data) ->
    if data & 1
      @mem.banking_mode = 'ram'
    else
      @mem.banking_mode = 'rom'
      @mem.ram_bank_ptr = 0

  ext_read: (addr) ->
    addr = addr + @mem.ram_bank_ptr * 0x2000
    @mem.ram_read addr

  ext_write: (addr, data) ->
    addr = addr + @mem.ram_bank_ptr * 0x2000
    @mem.ram_write addr, data
