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
    --save="filename"
      * Denotes the save location of the resume file. By default, will save to
        ".dig_data.dat"
    --file="filename"
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
  {"^%-%-(.-)=\"?\'?(.-)\"?\'?$", function(matched, matched2, arguments)
    arguments.flags[matched:lower()] = true
  end},
  {"^%-%-(.+)$", function(matched, arguments)
    arguments.flags[matched:lower()] = true
  end},
  {"^%-(.+)$", function(matched, arguments)
    for char in matched:lower():gmatch(".") do
      arguments.flags[char] = true
    end
  end},
  {".+", function(matched, arguments)
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
    for j = 1, parsers.n do
      local m = table.pack(args[i]:match(parsers[j][1])) -- try parsing the string
      if m.n > 0 then -- if successful
        parsers[j][2](m, arguments) -- run the parser.
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
    stepsTaken = stepsTaken
    posSaved = posSaved,
    startSaved = startSaved
  }
end

local function save(filename, args)
  local h = io.open(filename, 'w')

  -- write the arguments.
  h:write(table.concat(args.args, ' '))
  h:write(' ')

  -- determine the flags
  local oneflags = {}
  local longflags = {}
  local equalflags = {}
  for k, v in pairs(args.flags) do
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

  -- write short flags
  h:write(table.format("-%s ", table.concat(oneflags)))

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

--- Dig a room.
-- @tparam {args = {string,...}, flags = {[string] = boolean|string}} The table of arguments.
local function room(args)

end

--- Dig a tunnel.
-- @tparam {args = {string,...}, flags = {[string] = boolean|string}} The table of arguments.
local function tunnel(args)

end

--- Dig a quarry to bedrock.
-- @tparam {args = {string,...}, flags = {[string] = boolean|string}} The table of arguments.
local function quarry(args)

end

-- Load from file if given.
if args.flags.file then
  local loaded = load(args.flags.file)
  args = loaded.args
  skips = loaded.stepsTaken
  pos = loaded.posSaved
  start = loaded.startSaved
end

if args[1] == "room" then
  room(args)
elseif args[1] == "tunnel" then
  tunnel(args)
elseif args[1] == "quarry" then
  quarry(args)
end
