
class window.MBC2
    constructor: (mem) -> @mem = mem

    enable_disable_ext_ram: (addr, data) ->
        if addr & 0x100 == 0
            @mem.ext_ram_enable = not @mem.ext_ram_enable

    select_bank_lo: (addr, data) ->
        if (addr >> 12) & 1 == 1
            @mem.rom_bank_ptr = Math.max 1, data & 0xf

    select_bank_hi: (addr, data) ->

    select_banking_mode: (addr, data) ->

    ext_read: (s, addr) ->
        if addr < 0xa200
            (@mem.ram_read addr) & 0xf
        else
            @mem.ram_read addr

    ext_write: (s, addr, data) ->
        if addr < 0xa200
            @mem.ram_write addr, data & 0xf
        else
            @mem.ram_write addr, data
