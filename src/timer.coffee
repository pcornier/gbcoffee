
class timer

  @prop 'TAC',
    get: -> @gb.mem.r 0xff07
    set: (v) -> @gb.mem.w 0xff07, v

  @prop 'enable',
    get: -> @TAC & 4

  @prop 'frequency',
    get: -> [1024, 16, 64, 256][@TAC & 3]

  @prop 'TIMA',
    get: -> @gb.mem.r 0xff05
    set: (v) -> @gb.mem.ram_write 0xff05, v

  @prop 'TMA',
    get: -> @gb.mem.r 0xff06
    set: (v) -> @gb.mem.w 0xff06, v

  @prop 'DIV',
    get: -> @gb.mem.r 0xff04
    set: (v) -> @gb.mem.ram_write 0xff04, v

  constructor: (gb) ->
    @gb = gb
    @DIV = 0x1e
    @TAC = 0xf8
    @TTIC = 0
    @DTIC = 0

  update: (cpu_cycles) ->

    @DTIC += cpu_cycles

    if @enable

      @TTIC += cpu_cycles
      freq = @frequency

      while @TTIC >= freq
        @TTIC -= freq

        if ++@TIMA == 0x100
          @TIMA = @TMA
          @gb.cpu.irq 2

