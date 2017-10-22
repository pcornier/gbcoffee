
fs = require 'fs'
{exec} = require 'child_process'

files = [
  'src/z80'
  'src/lcd'
  'src/timer'
  'src/mbc1'
  'src/mbc2'
  'src/mem'
  'src/audio'
  'src/gb'
]

option '-d', '--debug', 'enable debugger'
task 'build', 'Building', (options) ->
  if options['debug']
    files.push 'debug'
  else
    files.push 'main'
  appContents = new Array remaining = files.length
  for file, index in files then do (file, index) ->
    fs.readFile "#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0

  process = ->
    fs.writeFile 'merged/gb.coffee', appContents.join('\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee -c -o js merged', (err, stdout, stderr) ->
        throw err if err
        fs.unlink 'merged/gb.coffee'

