
###
 very basic sound emulation
 to do: 
   - remove concrete audio implementation (AudioContext)
   - implement sweep, length & envelope
   - fix choppy sound
   - implement wave channel
   - implement noise channel
 so for now it is safer for ears to turn sound off!
###

class audio

  @prop 'status',
    get: -> @gb.mem.r 0xff26
    set: (v) -> @gb.mem.w 0xff26, v
    
  constructor: (gb) ->
    @gb = gb
    @frame_clk = 0
    @sample_clk = 0
    
    @sqr1_duty = 0
    @sqr2_duty = 0
    @sqr1_tracker = 0
    @sqr2_tracker = 0
    @sqr1_vol = 0
    @sqr1_vol = 0
    @sqr1_frequency = 0
    @sqr2_frequency = 0
    @sqr1_clk = 0
    @sqr2_clk = 0
    @sqr1_sample = 0
    @sqr2_sample = 0
    
    @context = new AudioContext
    @sample_rate = @context.sampleRate
    @sampling_rate = 4194304 / @sample_rate
    @max_samples = 8192
    @sample_count = 0
    @buffer = @context.createBuffer 2, @max_samples, @sample_rate
    @sched = 0

  update: (cpu_cycles) ->
    
    if (@gb.mem.r 0xff26) == 0 then return
    
    @sqr1_clk += cpu_cycles
    @sqr2_clk += cpu_cycles
    @sample_clk += cpu_cycles
    @frame_clk += cpu_cycles
    
    if @sqr1_clk >= @sqr1_frequency
      @sqr1_clk -= @sqr1_frequency  
      @sqr1_sample = @sqr1_duty[@sqr1_tracker]
      @sqr1_tracker = (@sqr1_tracker + 1) & 0x7

    if @sqr2_clk >= @sqr2_frequency
      @sqr2_clk -= @sqr2_frequency  
      @sqr2_sample = @sqr2_duty[@sqr2_tracker]
      @sqr2_tracker = (@sqr2_tracker + 1) & 0x7


    if @sample_clk >= @sampling_rate
      @sample_clk -= @sampling_rate
      
      if @sample_count < @max_samples
        ch0 = @buffer.getChannelData 0
        ch1 = @buffer.getChannelData 1
        ch0[@sample_count] = @sqr1_sample * (@sqr1_vol * 0x800)
        ch1[@sample_count] = @sqr2_sample * (@sqr2_vol * 0x800)
        @sample_count += 2
      else
        @sample_count = 0
        @queue @buffer
        @buffer = @context.createBuffer 2, @max_samples, @sample_rate
 
    # frame sequencer 512Hz
    if @frame_clk >= 8192
      @frame_clk -= 8192
      switch (@timer >> 13) & 7
        when 0, 4
          do @clock_length
        when 2, 6
          do @clock_length
          do @clock_sweep
        when 7
          do @clock_env
       
  queue: (buffer) ->
      source = do @context.createBufferSource
      source.onended = ->
        src = source
        do src.disconnect
        src = null
      source.loop = false
      source.buffer = buffer
      source.connect @context.destination
      if @sched == 0
        @sched = @context.currentTime
      source.start @sched
      @ched += buffer.duration
 
  clock_sweep: -> # todo
  clock_length: -> # todo
  clock_env: -> # todo
