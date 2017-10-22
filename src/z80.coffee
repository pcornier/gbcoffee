
Function::prop = (p, d) -> Object.defineProperty @::, p, d

class z80

  reset: ->
    @A = 0x1 # GBC = 0x11, GB = 0x1
    @F = @B = @D = 0
    @C = 0x13
    @E = 0xd8
    @HL = 0x014d
    @_PC = 0x100

    @cc = 0
    @SP = 0xfffe

    @IME = true
    @bug = false

    # PPU default values to be moved in LCD class
    @mem.w 0xff40, 0x91
    @mem.w 0xff41, 0x81
    @mem.ram_write 0xff44, 90

  constructor: (gb) ->

    @gb = gb
    @mem = gb.mem

    do @reset

    @cycles = [
    # 0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
      4, 12,  8,  8,  4,  4,  8,  4, 20,  8,  8,  8,  4,  4,  8,  4, # 0
      4, 12,  8,  8,  4,  4,  8,  4, 12,  8,  8,  8,  4,  4,  8,  4, # 1
      8, 12,  8,  8,  4,  4,  8,  4,  8,  8,  8,  8,  4,  4,  8,  4, # 2
      8, 12,  8,  8, 12, 12, 12,  4,  8,  8,  8,  8,  4,  4,  8,  4, # 3
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # 4
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # 5
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # 6
      8,  8,  8,  8,  8,  8,  4,  8,  4,  4,  4,  4,  4,  4,  8,  4, # 7
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # 8
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # 9
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # a
      4,  4,  4,  4,  4,  4,  8,  4,  4,  4,  4,  4,  4,  4,  8,  4, # b
      8, 12, 12, 16, 12, 16,  8, 16,  8, 16, 12,  0, 12, 24,  8, 16, # c
      8, 12, 12,  4, 12, 16,  8, 16,  8, 16, 12,  4, 12,  4,  8, 16, # d
     12, 12,  8,  4,  4, 16,  8, 16, 16,  4, 16,  4,  4,  4,  8, 16, # e
     12, 12,  8,  4,  4, 16,  8, 16, 12,  8, 16,  4,  0,  4,  8, 16  # f
    ]
    @sec_cycles = [
    # 0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # 0
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # 1
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # 2
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # 3
      8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8, # 4
      8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8, # 5
      8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8, # 6
      8,  8,  8,  8,  8,  8, 12,  8,  8,  8,  8,  8,  8,  8, 12,  8, # 7
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # 8
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # 9
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # a
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # b
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # c
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # d
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8, # e
      8,  8,  8,  8,  8,  8, 16,  8,  8,  8,  8,  8,  8,  8, 16,  8  # f
    ]

    @cbop = {}
    @cbop[0x00..0x07] = ([0..5].fill 'rlc_r').concat  ['rlc_hl', 'rlc_r']
    @cbop[0x08..0x0f] = ([0..5].fill 'rrc_r').concat ['rrc_hl', 'rrc_r']
    @cbop[0x10..0x17] = ([0..5].fill 'rl_r').concat ['rl_hl',  'rl_r']
    @cbop[0x18..0x1f] = ([0..5].fill 'rr_r').concat ['rr_hl',  'rr_r']
    @cbop[0x20..0x27] = ([0..5].fill 'sla_r').concat ['sla_hl', 'sla_r']
    @cbop[0x28..0x2f] = ([0..5].fill 'sra_r').concat ['sra_hl', 'sra_r']
    @cbop[0x30..0x37] = ([0..5].fill 'swap_r').concat ['swap_hl', 'swap_r']
    @cbop[0x38..0x3f] = ([0..5].fill 'srl_r').concat ['srl_hl', 'srl_r']
    @cbop[0x40+i*8..0x40+i*8+8] = ([0..5].fill 'bit_r').concat ['bit_hl', 'bit_r'] for i in [0..7]
    @cbop[0x80+i*8..0x40+i*8+8] = ([0..5].fill 'res_r').concat ['res_hl', 'res_r'] for i in [0..7]
    @cbop[0xc0+i*8..0xc0+i*8+8] = ([0..5].fill 'set_r').concat ['set_hl', 'set_r'] for i in [0..7]

    @reg_names = ['B', 'C', 'D', 'E', 'H', 'L', 'HL', 'A']

    @op =
      0x00: ['nop']
      0x01: ['ld_rr_nn', 'BC']
      0x02: ['ld_rri_r', 'BC', 'A']
      0x03: ['inc_rr', 'BC']
      0x04: ['inc_r', 'B']
      0x05: ['dec_r', 'B']
      0x06: ['ld_r_n', 'B']
      0x07: ['rlca']
      0x08: ['ld_nni_rr', 'SP']
      0x09: ['add_rr_rr', 'HL', 'BC']
      0x0a: ['ld_r_rri', 'A', 'BC']
      0x0b: ['dec_rr', 'BC']
      0x0c: ['inc_r', 'C']
      0x0d: ['dec_r', 'C']
      0x0e: ['ld_r_n', 'C']
      0x0f: ['rrca']
      0x10: ['stop']
      0x11: ['ld_rr_nn', 'DE']
      0x12: ['ld_rri_r', 'DE', 'A']
      0x13: ['inc_rr', 'DE']
      0x14: ['inc_r', 'D']
      0x15: ['dec_r', 'D']
      0x16: ['ld_r_n', 'D']
      0x17: ['rla']
      0x18: ['jr_n']
      0x19: ['add_rr_rr', 'HL', 'DE']
      0x1a: ['ld_r_rri', 'A', 'DE']
      0x1b: ['dec_rr', 'DE']
      0x1c: ['inc_r', 'E']
      0x1d: ['dec_r', 'E']
      0x1e: ['ld_r_n', 'E']
      0x1f: ['rra']
      0x20: ['jrnz_n']
      0x21: ['ld_rr_nn', 'HL']
      0x22: ['ldi_rri_r', 'HL', 'A']
      0x23: ['inc_rr', 'HL']
      0x24: ['inc_r', 'H']
      0x25: ['dec_r', 'H']
      0x26: ['ld_r_n', 'H']
      0x27: ['daa']
      0x28: ['jrz_n']
      0x29: ['add_hl_hl', 'HL', 'HL']
      0x2a: ['ldi_r_rri', 'A', 'HL']
      0x2b: ['dec_rr', 'HL']
      0x2c: ['inc_r', 'L']
      0x2d: ['dec_r', 'L']
      0x2e: ['ld_r_n', 'L']
      0x2f: ['cpl']
      0x30: ['jrnc_n']
      0x31: ['ld_rr_nn', 'SP']
      0x32: ['ldd_rri_r', 'HL', 'A']
      0x33: ['inc_rr', 'SP']
      0x34: ['inc_rri', 'HL']
      0x35: ['dec_rri', 'HL']
      0x36: ['ld_rri_n', 'HL']
      0x37: ['scf']
      0x38: ['jrc_n']
      0x39: ['add_rr_rr', 'HL', 'SP']
      0x3a: ['ldd_r_rri', 'A', 'HL']
      0x3b: ['dec_rr', 'SP']
      0x3c: ['inc_r', 'A']
      0x3d: ['dec_r', 'A']
      0x3e: ['ld_r_n', 'A']
      0x3f: ['ccf']
      0x40: ['ld_r_r', 'B', 'B']
      0x41: ['ld_r_r', 'B', 'C']
      0x42: ['ld_r_r', 'B', 'D']
      0x43: ['ld_r_r', 'B', 'E']
      0x44: ['ld_r_r', 'B', 'H']
      0x45: ['ld_r_r', 'B', 'L']
      0x46: ['ld_r_rri', 'B', 'HL']
      0x47: ['ld_r_r', 'B', 'A']
      0x48: ['ld_r_r', 'C', 'B']
      0x49: ['ld_r_r', 'C', 'C']
      0x4a: ['ld_r_r', 'C', 'D']
      0x4b: ['ld_r_r', 'C', 'E']
      0x4c: ['ld_r_r', 'C', 'H']
      0x4d: ['ld_r_r', 'C', 'L']
      0x4e: ['ld_r_rri', 'C', 'HL']
      0x4f: ['ld_r_r', 'C', 'A']
      0x50: ['ld_r_r', 'D', 'B']
      0x51: ['ld_r_r', 'D', 'C']
      0x52: ['ld_r_r', 'D', 'D']
      0x53: ['ld_r_r', 'D', 'E']
      0x54: ['ld_r_r', 'D', 'H']
      0x55: ['ld_r_r', 'D', 'L']
      0x56: ['ld_r_rri', 'D', 'HL']
      0x57: ['ld_r_r', 'D', 'A']
      0x58: ['ld_r_r', 'E', 'B']
      0x59: ['ld_r_r', 'E', 'C']
      0x5a: ['ld_r_r', 'E', 'D']
      0x5b: ['ld_r_r', 'E', 'E']
      0x5c: ['ld_r_r', 'E', 'H']
      0x5d: ['ld_r_r', 'E', 'L']
      0x5e: ['ld_r_rri', 'E', 'HL']
      0x5f: ['ld_r_r', 'E', 'A']
      0x60: ['ld_r_r', 'H', 'B']
      0x61: ['ld_r_r', 'H', 'C']
      0x62: ['ld_r_r', 'H', 'D']
      0x63: ['ld_r_r', 'H', 'E']
      0x64: ['ld_r_r', 'H', 'H']
      0x65: ['ld_r_r', 'H', 'L']
      0x66: ['ld_r_rri', 'H', 'HL']
      0x67: ['ld_r_r', 'H', 'A']
      0x68: ['ld_r_r', 'L', 'B']
      0x69: ['ld_r_r', 'L', 'C']
      0x6a: ['ld_r_r', 'L', 'D']
      0x6b: ['ld_r_r', 'L', 'E']
      0x6c: ['ld_r_r', 'L', 'H']
      0x6d: ['ld_r_r', 'L', 'L']
      0x6e: ['ld_r_rri', 'L', 'HL']
      0x6f: ['ld_r_r', 'L', 'A']
      0x70: ['ld_rri_r', 'HL', 'B']
      0x71: ['ld_rri_r', 'HL', 'C']
      0x72: ['ld_rri_r', 'HL', 'D']
      0x73: ['ld_rri_r', 'HL', 'E']
      0x74: ['ld_rri_r', 'HL', 'H']
      0x75: ['ld_rri_r', 'HL', 'L']
      0x76: ['halt']
      0x77: ['ld_rri_r', 'HL', 'A']
      0x78: ['ld_r_r', 'A', 'B']
      0x79: ['ld_r_r', 'A', 'C']
      0x7a: ['ld_r_r', 'A', 'D']
      0x7b: ['ld_r_r', 'A', 'E']
      0x7c: ['ld_r_r', 'A', 'H']
      0x7d: ['ld_r_r', 'A', 'L']
      0x7e: ['ld_r_rri', 'A', 'HL']
      0x7f: ['ld_r_r', 'A', 'A']
      0x80: ['add_r_r', 'A', 'B']
      0x81: ['add_r_r', 'A', 'C']
      0x82: ['add_r_r', 'A', 'D']
      0x83: ['add_r_r', 'A', 'E']
      0x84: ['add_r_r', 'A', 'H']
      0x85: ['add_r_r', 'A', 'L']
      0x86: ['add_r_rri', 'A', 'HL']
      0x87: ['add_r_r', 'A', 'A']
      0x88: ['adc_r_r', 'A', 'B']
      0x89: ['adc_r_r', 'A', 'C']
      0x8a: ['adc_r_r', 'A', 'D']
      0x8b: ['adc_r_r', 'A', 'E']
      0x8c: ['adc_r_r', 'A', 'H']
      0x8d: ['adc_r_r', 'A', 'L']
      0x8e: ['adc_r_rri', 'A', 'HL']
      0x8f: ['adc_r_r', 'A', 'A']
      0x90: ['sub_r_r', 'A', 'B']
      0x91: ['sub_r_r', 'A', 'C']
      0x92: ['sub_r_r', 'A', 'D']
      0x93: ['sub_r_r', 'A', 'E']
      0x94: ['sub_r_r', 'A', 'H']
      0x95: ['sub_r_r', 'A', 'L']
      0x96: ['sub_r_rri', 'A', 'HL']
      0x97: ['sub_r_r', 'A', 'A']
      0x98: ['sbc_r_r', 'A', 'B']
      0x99: ['sbc_r_r', 'A', 'C']
      0x9a: ['sbc_r_r', 'A', 'D']
      0x9b: ['sbc_r_r', 'A', 'E']
      0x9c: ['sbc_r_r', 'A', 'H']
      0x9d: ['sbc_r_r', 'A', 'L']
      0x9e: ['sbc_r_rri', 'A', 'HL']
      0x9f: ['sbc_r_r', 'A', 'A']
      0xa0: ['and_r', 'B']
      0xa1: ['and_r', 'C']
      0xa2: ['and_r', 'D']
      0xa3: ['and_r', 'E']
      0xa4: ['and_r', 'H']
      0xa5: ['and_r', 'L']
      0xa6: ['and_rri', 'HL']
      0xa7: ['and_r', 'A']
      0xa8: ['xor_r', 'B']
      0xa9: ['xor_r', 'C']
      0xaa: ['xor_r', 'D']
      0xab: ['xor_r', 'E']
      0xac: ['xor_r', 'H']
      0xad: ['xor_r', 'L']
      0xae: ['xor_rri', 'HL']
      0xaf: ['xor_r', 'A']
      0xb0: ['or_r', 'B']
      0xb1: ['or_r', 'C']
      0xb2: ['or_r', 'D']
      0xb3: ['or_r', 'E']
      0xb4: ['or_r', 'H']
      0xb5: ['or_r', 'L']
      0xb6: ['or_rri', 'HL']
      0xb7: ['or_r', 'A']
      0xb8: ['cp_r', 'B']
      0xb9: ['cp_r', 'C']
      0xba: ['cp_r', 'D']
      0xbb: ['cp_r', 'E']
      0xbc: ['cp_r', 'H']
      0xbd: ['cp_r', 'L']
      0xbe: ['cp_rri', 'HL']
      0xbf: ['cp_r', 'A']
      0xc0: ['retnz']
      0xc1: ['pop_rr', 'BC']
      0xc2: ['jnz_nn']
      0xc3: ['jp_nn']
      0xc4: ['callnz_nn']
      0xc5: ['push_rr', 'BC']
      0xc6: ['add_n']
      0xc7: ['rst', 0]
      0xc8: ['retz']
      0xc9: ['ret']
      0xca: ['jz_nn']
      0xcb: ['cb_n']
      0xcc: ['callz_nn']
      0xcd: ['call_nn']
      0xce: ['adc_r_n', 'A']
      0xcf: ['rst', 0x08]
      0xd0: ['retnc']
      0xd1: ['pop_rr', 'DE']
      0xd2: ['jnc_nn']
      0xd3: ['illegal']
      0xd4: ['callnc_nn']
      0xd5: ['push_rr', 'DE']
      0xd6: ['sub_r_n', 'A']
      0xd7: ['rst', 0x10]
      0xd8: ['retc']
      0xd9: ['reti']
      0xda: ['jc_nn']
      0xdb: ['illegal']
      0xdc: ['callc_nn']
      0xdd: ['illegal']
      0xde: ['sbc_r_n', 'A']
      0xdf: ['rst', 0x18]
      0xe0: ['ldh_ni_r', 'A']
      0xe1: ['pop_rr', 'HL']
      0xe2: ['ldh_ri_r', 'C', 'A']
      0xe3: ['illegal']
      0xe4: ['illegal']
      0xe5: ['push_rr', 'HL']
      0xe6: ['and_n']
      0xe7: ['rst', 0x20]
      0xe8: ['add_rr_n', 'SP']
      0xe9: ['jp_rri', 'HL']
      0xea: ['ld_nni_r', 'A']
      0xeb: ['illegal']
      0xec: ['illegal']
      0xed: ['illegal']
      0xee: ['xor_n']
      0xef: ['rst', 0x28]
      0xf0: ['ldh_r_ni', 'A']
      0xf1: ['pop_AF']
      0xf2: ['ldh_r_ri', 'A', 'C']
      0xf3: ['di']
      0xf4: ['illegal']
      0xf5: ['push_rr', 'AF']
      0xf6: ['or_n']
      0xf7: ['rst', 0x30]
      0xf8: ['ldhl_rr_n', 'SP']
      0xf9: ['ld_rr_rr', 'SP', 'HL']
      0xfa: ['ld_r_nni', 'A']
      0xfb: ['ei']
      0xfc: ['illegal']
      0xfd: ['illegal']
      0xfe: ['cp_n']
      0xff: ['rst', 0x38]


  @prop 'PC',
    get: -> @_PC
    set: (v) -> @_PC = v & 0xffff

  @prop 'AF',
    get: -> (@A << 8) | @F
    set: (v) ->
      @A = (v >> 8) & 0xff
      @F = v & 0xff

  @prop 'BC',
    get: -> (@B << 8) | @C
    set: (v) ->
      @B = (v >> 8) & 0xff
      @C = v & 0xff

  @prop 'DE',
    get: -> (@D << 8) | @E
    set: (v) ->
      @D = (v >> 8) & 0xff
      @E = v & 0xff

  @prop 'HL',
    get: -> (@H << 8) | @L
    set: (v) ->
      @H = (v >> 8) & 0xff
      @L = v & 0xff

	# 1111 0000
	# ||||
	# ||||__ y  - carry
	# |||___ h  - half carry
	# ||____ n  - sub
	# |_____ z  - zero

  @prop 'z',
    get: -> @F & 0b10000000

  @prop 'n',
    get: -> @F & 0b01000000

  @prop 'h',
    get: -> @F & 0b00100000

  @prop 'y',
    get: -> @F & 0b00010000

  szf: -> @F |=  0b10000000
  czf: -> @F &= ~0b10000000
  snf: -> @F |=  0b01000000
  cnf: -> @F &= ~0b01000000
  shf: -> @F |=  0b00100000
  chf: -> @F &= ~0b00100000
  syf: -> @F |=  0b00010000
  cyf: -> @F &= ~0b00010000

  zf: (v) -> @F = if v then do @szf else do @czf
  nf: (v) -> @F = if v then do @snf else do @cnf
  hf: (v) -> @F = if v then do @shf else do @chf
  yf: (v) -> @F = if v then do @syf else do @cyf

  # IRQ
  # Bit 0: V-Blank  Interrupt Request (INT 40h) (1=Request)
  # Bit 1: LCD STAT Interrupt Request (INT 48h) (1=Request)
  # Bit 2: Timer    Interrupt Request (INT 50h) (1=Request)
  # Bit 3: Serial   Interrupt Request (INT 58h) (1=Request)
  # Bit 4: Joypad   Interrupt Request (INT 60h) (1=Request)
  irq: (intid) ->
    irq = @mem.r 0xff0f
    irq |= (1 << intid)
    @mem.w 0xff0f, irq

  interrupt: (intid) ->
    @IME = false
    @mem.w 0xff0f, @mem.r 0xff0f & ~intid
    vectors =
      0b00001: 0x40
      0b00010: 0x48
      0b00100: 0x50
      0b01000: 0x58
      0b10000: 0x60
    @SP = (@SP - 2) & 0xffff
    @mem.w @SP, @PC & 0xff
    @mem.w @SP+1, (@PC>> 8) & 0xff
    @PC = vectors[intid]

  inc_r: (r) ->
    @[r] = @[r]+1 & 0xff
    @zf @[r] == 0
    @hf (@[r] & 0xf) == 0
    do @cnf

  dec_r: (r) ->
    @[r] = @[r]-1 & 0xff
    @zf @[r] == 0
    @hf (@[r] & 0xf) == 0xf
    do @snf

  inc_rr: (r) -> @[r]++

  dec_rr: (r) ->
    @[r] = (@[r] - 1) & 0xffff

  inc_rri: (r) ->
    v = ((@mem.r @[r]) + 1) & 0xff
    @zf v == 0
    @hf (v & 0xf) == 0
    @mem.w @[r], v
    do @cnf

  dec_rri: (r) ->
    v = (@mem.r @[r]) - 1
    @mem.w @[r], v & 0xff
    @zf v == 0
    @hf (v & 0xf) == 0xf
    do @snf

  ld_r_r: (r1, r2) -> @[r1] = @[r2]

  ld_rr_rr: (r1, r2) -> @[r1] = @[r2]

  ld_r_n: (r) ->
    @[r] = @mem.r @PC
    @PC++

  ld_r_rri: (r1, r2) -> @[r1] = @mem.r @[r2]

  ld_rri_n: (r) ->
    @mem.w @[r], @mem.r @PC
    @PC++

  ld_rr_nn: (r) ->
    @[r] = @mem.r @PC, 1
    @PC += 2

  ld_rri_r: (r1, r2) -> @mem.w @[r1], @[r2]

  ld_nni_rr: (r) ->
    a = @mem.r @PC, 1
    @mem.w a+1, (@[r] >> 8) & 0xff
    @mem.w a, @[r] & 0xff
    @PC += 2

  ld_nni_r: (r) ->
    @mem.w (@mem.r @PC, 1), @[r]
    @PC += 2

  ld_r_nni: (r) ->
    @[r] = @mem.r @mem.r @PC, 1
    @PC += 2

  ldi_rri_r: (r1, r2) ->
    @mem.w @[r1], @[r2]
    @[r1]++

  ldi_r_rri: (r1, r2) ->
    @[r1] = @mem.r @[r2]
    @[r2]++

  ldd_rri_r: (r1, r2) ->
    @mem.w @[r1], @[r2]
    @[r1]--

  ldd_r_rri: (r1, r2) ->
    @[r1] = @mem.r @[r2]
    @[r2]--

  ldh_ni_r: (r) ->
    @mem.w (0xff00 + @mem.r @PC), @[r]
    @PC++

  ldh_r_ri: (r1, r2) ->
    @[r1] = @mem.r 0xff00 + @[r2]

  ldh_ri_r: (r1, r2) ->
    @mem.w 0xff00 + @[r1], @[r2]

  ldh_r_ni: (r) ->
    @[r] = @mem.r 0xff00 + @mem.r @PC
    @PC++

  ldhl_rr_n: (r) ->
    n = ((@mem.r @PC) << 24) >> 24
    @PC++
    @HL = (@[r] + n) & 0xffff
    n = @[r] ^ n ^ @HL
    @F = 0
    @yf (n & 0x100) == 0x100
    @hf (n & 0x10) == 0x10

  rl_r: (r) ->
    c = if @y then 1 else 0
    @F = 0
    @yf @[r] > 0x7f
    @[r] = ((@[r] << 1) & 0xFF) | c
    @zf @[r] == 0

  rla: ->
    c = if @y then 1 else 0
    @F = 0
    @yf @A > 0x7f
    @A = ((@A << 1) & 0xff) | c

  rr_r: (r) ->
    v = @[r] & 1
    @[r] = (@[r] >> 1) | (if @y then 0x80 else 0)
    @F = 0
    @yf v
    @zf @[r] == 0

  rra: ->
    v = @y
    @F = 0
    @yf @A & 1
    @A = (if v then 0x80 else 0) | (@A >> 1)

  rl_hl: ->
    v = @mem.r @HL
    c = v > 0x7f
    v = ((v << 1) & 0xFF) | (if @y then 1 else 0)
    @F = 0
    @yf c
    @mem.w @HL, v
    @zf v == 0

  rr_hl: ->
    v = @mem.r @HL
    c = v & 1
    v = (v >> 1) | (if @y then 0x80 else 0)
    @F = 0
    @yf c
    @mem.w @HL, v
    @zf v == 0

  rrc_r: (r) ->
    @F = 0
    @yf @[r] & 1
    @[r] = (@[r] >> 1) | (if @y then 0x80 else 0)
    @zf @[r] == 0

  rrca: ->
    @A = (@A >> 1) | ((@A & 1) << 7)
    @F = 0
    @yf @A > 0x7f

  rrc_hl: ->
    @F = 0
    v = @mem.r @HL
    @yf (v & 1) == 1
    v = (v >> 1) | (if @y then 0x80 else 0)
    @mem.w @HL, v
    @zf v == 0

  rlc_r: (r) ->
    @F = 0
    @yf @[r] > 0x7f
    @[r] = ((@[r] << 1) & 0xff) | (if @y then 1 else 0)
    @zf @[r] == 0

  rlca: ->
    @F = 0
    @yf @A > 0x7f
    @A = ((@A << 1) & 0xff) | (@A >> 7)


  rlc_hl: (r) ->
    v = @mem.r @HL
    @yf v > 0x7f
    @mem.w @HL, (v << 1) & 0xff | (if @y then 1 else 0)
    @F &= ~0b01100000
    @zf v == 0

  sla_r: (r) ->
    @F = 0
    @yf @[r] > 0x7F
    @[r] = (@[r] << 1) & 0xff
    @zf @[r] == 0

  sla_hl: ->
    v = @mem.r @HL
    @F = 0
    @yf v > 0x7f
    v = (v << 1) & 0xFF
    @mem.w @HL, v
    @zf v == 0

  sra_r: (r) ->
    @F = 0
    @yf @[r] & 1
    @[r] = (@[r] >> 1) | (@[r] & 0x80)
    @zf @[r] == 0

  sra_hl: ->
    v = @mem.r @HL
    @F = 0
    @yf v & 1
    v = (v >> 1) | (v & 0x80)
    @mem.w @HL, v
    @zf v == 0

  srl_r: (r) ->
    @F = 0
    @yf @[r] & 1
    @[r] >>= 1
    @zf @[r] == 0

  srl_hl: ->
    v = @mem.r @HL
    @yf v & 1
    v >>= 1
    @mem.w @HL, v
    @F &= ~0b01100000
    @zf v == 0

  swap_r: (r) ->
    @[r] = ((@[r] & 0xf) << 4) | (@[r] >> 4)
    @zf @[r] == 0
    @F &= ~0b01110000

  swap_hl: ->
    v = @mem.r @HL
    @mem.w @HL, ((v & 0xf) << 4) | (v >> 4)
    @zf v == 0
    @F &= ~0b01110000

  bit_r: (r) ->
    b = (@mem.r @PC) >> 3
    do @shf
    do @cnf
    @zf (@[r] & (1 << (b-8))) == 0

  bit_hl: ->
    b = (@mem.r @PC) >> 3
    do @shf
    do @cnf
    @zf ((@mem.r @HL) & (1 << (b-8))) == 0

  res_r: (r) ->
    b = (@mem.r @PC) >> 3
    @[r] &= ~(1 << (b-0x10))

  res_hl: ->
    b = (@mem.r @PC) >> 3
    v = @mem.r @HL
    @mem.w @HL, v & ~(1 << (b-0x10))

  set_r: (r) ->
    b = (@mem.r @PC) >> 3
    @[r] |= 1 << (b-0x18)

  set_hl: ->
    b = (@mem.r @PC) >> 3
    v = @mem.r @HL
    @mem.w @HL, v | (1 << (b-0x18))

  add_n: ->
    v = @A + @mem.r @PC
    @hf (v & 0xf) < (@A & 0xf)
    @yf v > 0xff
    @A = v & 0xff
    @zf @A == 0
    do @cnf
    @PC++

  add_r_r: (r1, r2) ->
    v = @[r1] + @[r2]
    @hf (v & 0xf) < (@[r1] & 0xf)
    @yf v > 0xff
    do @cnf
    @[r1] = v & 0xff
    @zf @[r1] == 0

  add_r_rri: (r1, r2) ->
    @F = 0
    v = @[r1] + @mem.r @[r2]
    @hf (v & 0xf) < (@[r1] & 0xf)
    @yf v > 0xff
    @[r1] = v & 0xff
    @zf @[r1] == 0

  add_rr_rr: (r1, r2) ->
    v = @[r1] + @[r2]
    @hf (@[r1] & 0xfff) > (v & 0xfff)
    @yf v > 0xffff
    do @cnf
    @[r1] = v & 0xffff

  add_hl_hl: ->
    @hf (@HL & 0xfff) > 0x7ff
    @yf @HL > 0x7fff
    @HL = (@HL << 1) & 0xffff
    do @cnf

  add_rr_n: (r) ->
    a = ((@mem.r @PC) << 24) >> 24
    b = @[r]
    v = (a + b) & 0xffff
    a = b ^ a ^ v
    @hf (a & 0x10) == 0x10
    @yf (a & 0x100) == 0x100
    @F &= ~0b11000000
    @[r] = v
    @PC++

  adc_r_n: (r) ->
    a = @[r]
    b = @mem.r @PC
    c = if @y then 1 else 0
    v =  a + b + c
    @hf (a & 0xf) + (b & 0xf) + c > 0xf
    @yf v > 0xff
    v &= 0xff
    @zf v == 0
    do @cnf
    @[r] = v
    @PC++

  adc_r_r: (r1, r2) ->
    a = @[r1]
    b = @[r2]
    c = if @y then 1 else 0
    v =  a + b + c
    @hf (a & 0xf) + (b & 0xf) + c > 0xf
    @yf v > 0xff
    v &= 0xff
    @zf v == 0
    do @cnf
    @[r1] = v

  adc_r_rri: (r1, r2) ->
    a = @[r1]
    b = @mem.r @[r2]
    c = if @y then 1 else 0
    v =  a + b + c
    @hf (a & 0xf) + (b & 0xf) + c > 0xf
    @yf v > 0xff
    v &= 0xff
    @zf v == 0
    do @cnf
    @[r1] = v

  sub_r_n: (r) ->
    v = @[r] - (@mem.r @PC)
    @hf (@[r] & 0xf) < (v & 0xf)
    @yf v < 0
    @zf v == 0
    do @snf
    @[r] = v & 0xff
    @PC++

  sub_r_r: (r1, r2) ->
    v = @[r1] - @[r2]
    @hf (@[r1] & 0xf) < (v & 0xf)
    @yf v < 0
    @zf v == 0
    do @snf
    @[r1] = v & 0xff

  sub_r_rri: (r1, r2) ->
    v = @[r1] - @mem.r @[r2]
    @hf (@[r1] & 0xf) < (v & 0xf)
    @yf v < 0
    @zf v == 0
    do @snf
    @[r1] = v & 0xff

  sbc_r_n: (r) ->
    a = @[r]
    b = @mem.r @PC
    c = if @y then 1 else 0
    v =  a - b - c
    @hf ((a & 0xf) - (b & 0xf) - c) < 0
    @yf v < 0
    v &= 0xff
    @zf v == 0
    do @snf
    @[r] = v & 0xff
    @PC++

  sbc_r_r: (r1, r2) ->
    a = @[r1]
    b = @[r2]
    c = if @y then 1 else 0
    v =  a - b - c
    @hf ((a & 0xf) - (b & 0xf) - c) < 0
    @yf v < 0
    @[r1] = v & 0xff
    @zf @[r1] == 0
    do @snf

  sbc_r_rri: (r1, r2) ->
    a = @[r1]
    b = @mem.r @[r2]
    c = if @y then 1 else 0
    v =  a - b - c
    @hf ((a & 0xf) - (b & 0xf) - c) < 0
    @yf v < 0
    @[r1] = v & 0xff
    @zf @[r1] == 0
    do @snf

  and_n: ->
    @A &= @mem.r @PC
    @F = 0
    @zf @A == 0
    do @shf
    @PC++

  and_r: (r) ->
    @A &= @[r]
    @F = 0
    @zf @A == 0
    do @shf

  and_rri: (r) ->
    @A &= @mem.r @[r]
    @F = 0
    @zf @A == 0
    do @shf

  xor_n: ->
    @A ^= @mem.r @PC
    @F = 0
    @zf @A == 0
    @PC++

  xor_r: (r) ->
    @A ^= @[r]
    @F = 0
    @zf @A == 0

  xor_rri: (r) ->
    @A ^= @mem.r @[r]
    @F = 0
    @zf @A == 0

  or_n: ->
    @A |= @mem.r @PC
    @F = 0
    @zf @A == 0
    @PC++

  or_r: (r) ->
    @A |= @[r]
    @F = 0
    @zf @A == 0

  or_rri: (r) ->
    @A |= @mem.r @[r]
    @F = 0
    @zf @A == 0

  cp_n: ->
    n = @mem.r @PC
    v = @A - n
    @hf (v & 0xf) > (@A & 0xf)
    @yf v < 0
    @zf v == 0
    do @snf
    @PC++

  cp_r: (r) ->
    v = @A - @[r]
    @hf (v & 0xf) > (@A & 0xf)
    @yf v < 0
    @zf v == 0
    do @snf

  cp_rri: (r) ->
    v = @A - @mem.r @[r]
    @hf (v & 0xf) > (@A & 0xf)
    @yf v < 0
    @zf v == 0
    do @snf

  cpl: ->
    @A ^= 0xff
    @F |= 0b01100000

  jr_n: ->
    @PC += ((@mem.r @PC)+1 << 24) >> 24

  jrnz_n: ->
    if @z == 0 then do @jr_n
    else @PC++

  jrz_n: ->
    if @z then do @jr_n
    else @PC++

  jrc_n: ->
    if @y then do @jr_n
    else @PC++

  jrnc_n: ->
    if @y == 0 then do @jr_n
    else @PC++

  jp_nn: ->
    @PC = @mem.r @PC, 1

  jp_rri: (r) ->
    @PC = @[r]

  jc_nn: ->
    if @y then do @jp_nn
    else @PC += 2

  jnc_nn: ->
    if @y == 0 then do @jp_nn
    else @PC += 2

  jz_nn: ->
    if @z then do @jp_nn
    else @PC += 2

  jnz_nn: ->
    if @z == 0 then do @jp_nn
    else @PC += 2

  push_rr: (r) ->
    @SP -= 2
    @mem.w @SP, @[r] & 0xff
    @mem.w @SP+1, (@[r] >> 8) & 0xff

  pop_rr: (r) ->
    @[r] = ((@mem.r @SP+1) << 8) & 0xffff
    @[r] |= @mem.r @SP
    @SP += 2

  pop_AF: ->
    v = (@mem.r @SP) & 0xf0
    @nf (v & 0x40) == 0x40
    @hf (v & 0x20) == 0x20
    @yf (v & 0x10) == 0x10
    @zf (v > 0x7F)
    @A = @mem.r @SP+1
    @SP += 2

  call_nn: ->
    a = @mem.r @PC, 1
    @SP -= 2
    @mem.w @SP, (@PC+2) & 0xff
    @mem.w @SP+1, ((@PC+2) >> 8) & 0xff
    @PC = a

  callz_nn: ->
    if @z then do @call_nn
    else @PC += 2

  callnz_nn: ->
    if @z == 0 then do @call_nn
    else @PC += 2

  callc_nn: ->
    if @y then do @call_nn
    else @PC += 2

  callnc_nn: ->
    if @y == 0 then do @call_nn
    else @PC += 2

  ret: ->
    @PC = @mem.r @SP, 1
    @SP += 2

  reti: ->
    @PC = @mem.r @SP, 1
    @SP += 2
    # todo wait specific cyles before enabling int
    @IME = true

  retz: ->
    if @z then do @ret

  retnz: ->
    if @z == 0 then do @ret

  retc: ->
    if @y then do @ret

  retnc: ->
    if @y == 0 then do @ret

  scf: ->
    do @syf
    @F &= ~0b01100000

  ccf: ->
    if @y then do @cyf else do @syf
    @F &= ~0b01100000

  rst: (n) ->
    @SP -= 2
    @mem.w @SP, @PC & 0xff
    @mem.w @SP+1, (@PC >> 8) & 0xff
    @PC = n

  di: -> @IME = false

  ei: -> @IME = true

  daa: ->
    v = @A

    if @n == 0
      if @h || ((@A & 0xf) > 9)
        v = (v + 6) & 0xff
        do @chf

      if @y || (@A > 0x99)
        v = (v + 0x60) & 0xff
        do @syf

    else
      if @h
        v = (v + 0xfa) & 0xff
        do @chf

      if @y
        v = (v + 0xa0) & 0xff
        do @syf

    @A = v & 0xff
    @zf @A == 0

  cb_n: ->
    opc = @mem.r @PC
    reg = @reg_names[opc & 0x7]
    @[@cbop[opc]] reg
    @cc += @sec_cycles[opc]
    @PC++

  nop: ->

  halt: ->
    IF = @mem.r 0xff0f
    IE = @mem.r 0xffff
    if @IME
      if IF & IE & 0x1f
        @cc += 16
      else
        @PC--
    else
      if IF & IE & 0x1f
        @halt_bug = true
      @cc += 16


  stop: ->
  	# TODO, speed change if gbc

  illegal: ->
    console.log 'Illegal opcode'
    @gb.running = false

  update: ->
    @cc = 0
    opc = @mem.r @PC
    [func, p1, p2] = @op[opc]

    if @halt_bug
     @halt_bug = false
    else
      @PC++

    @[func] p1, p2

    @cc += @cycles[opc]
    @cc

