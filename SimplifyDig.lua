-- Digging utility to dig things because epic

--[[
  Planned arguments:
    dig <room|tunnel|quarry|help>
    dig room <forward distance> <up/down distance> <left/right distance>
    dig tunnel <length> [width=1]
    dig quarry <forward distance> <left/right distance>
    dig help [room/tunnel/quarry/flags]

  All distances are excluding the current block, the turtle assumes the current
  block is "behind" where it is meant to dig.

  Flags:
    -l or --left
      * Dig to the left of the starting point.
    -r or --right
      * Dig to the right of the starting point. This is the default, but can be
        specified anyways.
    -u or --up
      * Dig upwards from the starting point. This is the default, but can be
        specified anyways.
    -d or --down
      * Dig downards from the starting point.
    -n or --nofuel
      * Ignore fuel requirements. Useful for quarrying as the turtle will eat coal
        it finds, make sure to use -f in tandem with this!
    -f or --fuel
      * Eat coal and other fuels the turtle finds along its way while mining.
    -c or --craft
      * Acts as -f, but if a crafting table is installed the turtle will use that
        to craft coal blocks out of the coal it finds, as it is more fuel
        efficient to do so.
    -d or --drop
      * When the turtle is full, the turtle will return home and drop off items.
        Otherwise, the turtle will return home and try to wait until it is
        emptied.
    --overwrite
      * Creates a startup folder and copies the startup file into it (if one
        exists). Registers a program as the first to run which will run this file
        in an attempt to keep it running from where it left off.
    --save=filename
      * Denotes the save location of the resume file. By default, will save to
        ".dig_data.dat".
    --file=filename
      * Attempt to resume from where we left off by using the data in the given
        file.
    --gps
      * For use with --file, will use gps to aid in determining where we left off
        when the turtle rebooted.

  Save files will contain the following information:
    * The arguments used to run the program
    * The amount of steps completed as of the last savepoint
    * The last known position and facing of the turtle (x y z f)
    * The starting position (If GPS is enabled, it will be the global position).
      (x y z f)

  Save files look like the following:
    args -flags --flags --flags=flags
    32
    3 8 -14 2
    0 0 0 3
]]

-- CC requires
local expect = require "cc.expect" .expect

local steps = 0
local skips = 0
local pos = {
  x = 0,
  y = 0,
  z = 0,
  facing = 0
}
local start = {
  x = 0,
  y = 0,
  z = 0,
  facing = 0
}

local function makeInfo(func, result)
  return {
    f = func,
    result = result
  }
end

-- digging is NOT a part of the simulator. Gravel and sand will cause the step
-- counter to be off when multiple pieces of gravel fall in front of the turtle.
local turtleSim = {
  turnLeft = makeInfo(turtle.turnLeft, function()
    pos.facing = (pos.facing - 1) % 4
    steps = steps + 1
  end),
  turnRight = makeInfo(turtle.turnRight, function()
    pos.facing = (pos.facing + 1) % 4
    steps = steps + 1
  end),
  forward = makeInfo(turtle.forward, function()
    if pos.facing == 0 then -- facing -Z
      pos.z = pos.z - 1
    elseif pos.facing == 1 then -- facing +X
      pos.x = pos.x + 1
    elseif pos.facing == 2 then -- facing +Z
      pos.z = pos.z + 1
    else -- facing -X
      pos.x = pos.x - 1
    end
    steps = steps + 1
  end),
  back = makeInfo(turtle.back, function()
    if pos.facing == 0 then -- facing -Z
      pos.z = pos.z + 1
    elseif pos.facing == 1 then -- facing +X
      pos.x = pos.x - 1
    elseif pos.facing == 2 then -- facing +Z
      pos.z = pos.z - 1
    else -- facing -X
      pos.x = pos.x + 1
    end
    steps = steps + 1
  end),
  up = makeInfo(turtle.up, function()
    pos.y = pos.y + 1
    steps = steps + 1
  end),
  down = makeInfo(turtle.down, function()
    pos.y = pos.y - 1
    steps = steps + 1
  end)
}

--- Simulate a certain  movement, or actually do the movement.
-- @tparam boolean ok Whether the movement is to be applied.
-- @tparam table info The information about the movement to be made.
local function simulate(ok, info)
  expect(1, ok, "boolean", "nil")
  expect(2, info, "table")

  -- If we want to do the move, attempt to do it
  if ok then
    -- if it succeeds, run the result.
    if info.f() then
      info.result()
      return true
    end
    -- otherwise note to the caller that we failed
    return false
  end

  -- if we are just simulating the movement, simulate its result.
  info.result()
  -- also decrease the amount of items we are skipping.
  skips = skips - 1
  return true
end

-- extremely basic parser, will parse the following:
-- program arg -f --flag -qwe arg2 --thing="thing2"
-- into the following:
--[[
  {
    args = {"arg", "arg2"},
    flags = {
      ["f"] = true,
      ["flag"] = true,
      ["q"] = true,
      ["w"] = true,
      ["e"] = true,
      thing = "thing2"
    }
  }

]]
-- these are actual parsers, each one takes the input from the parsed string, and the argument table.
local parsers = {
  {"^%-%-(.-)=\"?\'?(.-)\"?\'?$", function(arguments, matched, matched2)
    arguments.flags[matched:lower()] = matched2
  end},
  {"^%-%-(.+)$", function(arguments, matched)
    arguments.flags[matched:lower()] = true
  end},
  {"^%-(%a+)$", function(arguments, matched)
    for char in matched:lower():gmatch(".") do
      arguments.flags[char] = true
    end
  end},
  {".+", function(arguments, matched)
    arguments.args.n = arguments.args.n + 1
    arguments.args[arguments.args.n] = matched:lower()
  end},
}
parsers.n = #parsers

-- Parser function which runs all the parsers on each argument.
local function parse(...)
  local args = table.pack(...)
  local arguments = {args = {n = 0}, flags = {}}
  for i = 1, args.n do
    print(args[i])
    for j = 1, parsers.n do
      local m = table.pack(args[i]:match(parsers[j][1])) -- try parsing the string
      if m[1] then -- if successful
        print("Parser selected:", parsers[j][1])
        parsers[j][2](arguments, table.unpack(m, 1, m.n)) -- run the parser.
        break -- then go to the next argument.
      end
    end
  end

  return arguments
end

-- Parse arguments.
local args = parse(...)

-- Shell tokenizer.
local function tokenize(...)
    local line = table.concat({ ... }, " ")
    local tokens = {}
    local quoted = false
    for match in string.gmatch(line .. "\"", "(.-)\"") do
        if quoted then
            table.insert(tokens, match)
        else
            for _match in string.gmatch(match, "[^ \t]+") do
                table.insert(tokens, _match)
            end
        end
        quoted = not quoted
    end
    return table.unpack(tokens)
end

--[[
  Save files look like the following:
    args -flags --flags --flags=flags
    32
    3 8 -14 2
    0 0 0 3
]]
local function load(filename)
  if not fs.exists(filename) then
    error(string.format("Failed to load file '%s' as it does not exist.", filename), 0)
  end
  -- read lines
  local lines = {}
  for line in io.lines(filename) do
    table.insert(lines, line)
  end

  -- parse the arguments
  local args = parse(tokenize(lines[1]))

  -- get number of steps taken
  local stepsTaken = tonumber(lines[2])

  -- get position and facing
  local posSaved = {}
  posSaved.x, posSaved.y, posSaved.z, posSaved.facing = string.match(lines[3], "(%d+) (%d+) (%d+) (%d+)")

  -- get the starting position and facing.
  local startSaved = {}
  startSaved.x, startSaved.y, startSaved.z, startSaved.facing = string.match(lines[4], "(%d+) (%d+) (%d+) (%d+)")

  -- return all data
  return {
    args = args,
    stepsTaken = stepsTaken,
    posSaved = posSaved,
    startSaved = startSaved
  }
end

local function makeflags(flags)
  -- determine the flags
  local oneflags = {}
  local longflags = {}
  local equalflags = {}
  for k, v in pairs(flags) do
    if type(v) == "boolean" then
      if #k == 1 then
        table.insert(oneflags, k)
      else
        table.insert(longflags, string.format("--%s", k))
      end
    else
      table.insert(equalflags, string.format("--%s='%s'", k, v))
    end
  end

  return oneflags, longflags, equalflags
end

local function save(args)
  local filename = ".dig_data.dat"

  if args.flags.save then
    filename = args.flags.save
  end

  local h = io.open(filename, 'w')

  -- write the arguments.
  h:write(table.concat(args.args, ' '))
  h:write(' ')

  local oneflags, longflags, equalflags = makeflags(args.flags)

  -- write short flags
  if #oneflags > 0 then
    h:write(string.format("-%s ", table.concat(oneflags)))
  end

  -- write long flags
  for i = 1, #longflags do
    local f = longflags[i]
    h:write(f .. ' ')
  end

  -- write equal flags
  for i = 1, #equalflags do
    local f = equalflags[i]
    h:write(f .. ' ')
  end

  -- write the number of steps completed.
  h:write('\n' .. tostring(steps) .. '\n')

  -- write the position and facing
  h:write(string.format("%d %d %d %d\n", pos.x, pos.y, pos.z, pos.facing))

  -- write the starting position
  h:write(string.format("%d %d %d %d", start.x, start.y, start.z, start.facing))

  h:close()
end

-- Ensure function to ensure a movement was completed.
local function _ensure(movement, ...)
  local funcs = table.pack(...)
  while not simulate(skips <= 0, movement) do
    for i = 1, funcs.n do
      funcs[i]()
    end
    os.sleep()
  end
end

-- can turns fail? I don't think they can, but for some reason I recall it happening
-- eh, if someone reports it I'll add it to this.
local ensure = {
  forward = function(args)
    _ensure(turtleSim.forward, turtle.dig, turtle.attack)
    save(args)
  end,
  up = function(args)
    _ensure(turtleSim.up, turtle.digUp, turtle.attackUp)
    save(args)
  end,
  down = function(args)
    _ensure(turtleSim.down, turtle.digDown, turtle.attackDown)
    save(args)
  end,
  turnLeft = function(args)
    _ensure(turtleSim.turnLeft, turtle.attackUp, turtle.attack, turtle.attackDown)
    save(args)
  end,
  turnRight = function(args)
    _ensure(turtleSim.turnRight, turtle.attackUp, turtle.attack, turtle.attackDown)
    save(args)
  end
}

--- Dig a room.
-- @tparam {args = {string,...}, flags = {[string] = boolean|string}} The table of arguments.
local function room(args)
  -- check arguments for correctness
  for i = 2, 4 do
    print("b", args.args[i])
    args.args[i] = tonumber(args.args[i])
    if not args.args[i] then
      print("a", args.args[i])
      error(string.format("Bad argument #%d: Should be a number.", i), 0)
    end
  end
  local l, h, w = table.unpack(args.args, 2, 4)

  local argWrapper = {}
  for k, v in pairs(ensure) do
    argWrapper[k] = function()
      return v(args)
    end
  end

  local turn = argWrapper.turnRight
  local vertical = argWrapper.up
  local vertDig1, vertDig2 = turtle.digUp, turtle.digDown
  local fuel = not (args.n or args.nofuel)
  -- set up directions
  if args.flags.l or args.flags.left then
    turn = argWrapper.turnLeft
  elseif args.flags.r or args.flags.right then
    turn = argWrapper.turnRight
  end
  -- toggle direction if negative.
  if w < 0 then
    turn = turn == argWrapper.turnLeft and argWrapper.turnRight or argWrapper.turnLeft
    w = math.abs(w)
  end
  if args.flags.u or args.flags.up then
    vertical = argWrapper.up
    vertDig1, vertDig2 = turtle.digUp, turtle.digDown
  elseif args.flags.d or args.flags.down then
    vertical = argWrapper.down
    vertDig1, vertDig2 = turtle.digDown, turtle.digUp
  end
  -- toggle direction if negative.
  if h < 0 then
    vertical = vertical == argWrapper.up and argWrapper.down or argWrapper.up
    vertDig1, vertDig2 = vertDig1 == turtle.digUp and turtle.digDown or turtle.digUp,
                         vertDig2 == turtle.digUp and turtle.digDown or turtle.digUp
    h = math.abs(h)
  end
  if l <= 0 then
    error("Length cannot be less than or equal to zero.", 0)
  end
  local verticalInverse = vertical == argWrapper.up and argWrapper.down or argWrapper.up

  -- calculate fuel requirements if needed
  if fuel then

  end

  print("Initial forward.")
  -- start the movement/dig logic.
  argWrapper.forward() -- move forward so we are inside the dig zone.
  -- and if we are digging 2 or more, go down/up one block.
  if h > 2 then
    vertical()
  end
  local dig1, dig2 = false, h > 2
  local lastY = 1

  local function digPlane(_l, _w)
    for x = 1, _w do
      -- dig a line
      for z = 1, _l do
        if dig1 then
          vertDig1()
        end
        if dig2 then
          vertDig2()
        end

        if z ~= _l then
          argWrapper.forward() -- digging forwards is assumed in this function
        end
      end

      -- turn around and go to the next line
      if x ~= _w then
        turn()
        argWrapper.forward()
        turn()
        -- and invert the direction we are turning
        turn = turn == argWrapper.turnLeft and argWrapper.turnRight or argWrapper.turnLeft
      end
    end
  end

  for y = 2, h, 3 do
    -- store information about where we ended.
    lastY = y

    -- Determine if we need to dig in the vertical direction
    dig1 = y + 1 <= h

    -- actually dig the plane
    digPlane(l, w)

    -- determine if we can move another three blocks upwards
    if y + 3 <= h then
      for i = 1, 3 do -- actually do that
        vertical()
      end
      -- then turn around
    end
    argWrapper.turnLeft()
    argWrapper.turnLeft()
  end

  -- handle final rows
  if lastY + 2 == h then
    vertical()
    dig2 = false
    dig1 = true
    digPlane(l, w)
  end
end

--- Dig a tunnel.
-- @tparam {args = {string,...}, flags = {[string] = boolean|string}} The table of arguments.
local function tunnel(args)
  -- check arguments for correctness
end

--- Dig a quarry to bedrock.
-- @tparam {args = {string,...}, flags = {[string] = boolean|string}} The table of arguments.
local function quarry(args)
  -- check arguments for correctness
end

-- Load from file if given.
if args.flags.file then
  local loaded = load(args.flags.file)
  args = loaded.args
  skips = loaded.stepsTaken
  pos = loaded.posSaved
  start = loaded.startSaved
end

-- handle the "overwrite" flag.
if args.flags.overwrite then
  if fs.exists("startup") then
    if fs.isDir("startup") then
      if fs.exists("startup/!_resume_dig.lua") then
        -- it is safe to assume no other program creates a startup file with this name
        fs.delete("startup/!_resume_dig.lua")
      end
    else
      local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      local tempname = ""
      for i = 1, 10 do
        tempname = tempname .. chars[math.random(1, #chars)]
      end
      fs.move("startup", tempname)
      fs.makeDir("startup")
      fs.move(tempname, "startup/999_startup.lua")
    end
  else
    fs.makeDir("startup")
  end

  local runningProgram = shell.getRunningProgram()
  local savefile = args.flags.save and args.flags.save or ".dig_data.dat"

  local h = io.open("startup/!_resume_dig.lua")
  h:write("shell.run('")
  h:write(runningProgram)

  h:write(string.format(" --save=\"%s\"')", savefile))

  h:close()
end

if args.args[1] == "room" then
  print("Room.")
  room(args)
elseif args.args[1] == "tunnel" then
  tunnel(args)
elseif args.args[1] == "quarry" then
  quarry(args)
end

-- clean up the temporary resume file.
fs.delete("startup/!_resume_dig.lua")
