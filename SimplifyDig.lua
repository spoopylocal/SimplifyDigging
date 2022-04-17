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

  Save files look like the following:
    args -flags --flags --flags=flags
    32
    3 8 -14 2
]]

local pos = {
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

local turtleSim = {
  turnLeft = makeInfo(turtle.turnLeft, function() pos.facing = (pos.facing - 1) % 4 end),
  turnRight = makeInfo(turtle.turnRight, function() pos.facing = (pos.facing + 1) % 4 end),
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
  end),
  up = makeInfo(turtle.up, function() pos.y = pos.y + 1 end),
  down = makeInfo(turtle.down, function() pos.y = pos.y - 1 end)
}

--- Simulate a certain  movement, or actually do the movement.
-- @tparam boolean ok Whether the movement is to be applied.
-- @tparam table info The information about the movement to be made.
local function simulate(ok, info)
  if ok then
    info.f()
  end
  info.result()
end

--- Dig a room.
-- @tparam number forward The distsance forward to dig.
-- @tparam number udDistance The distance up/down to dig.
-- @tparam number lrdistance The distance left/right to dig.
-- @tparam boolean|nil ud Whether the turtle moves up or down. true = down, false/nil = up (default up)
-- @tparam boolean|nil lr Whether the turtle moves left or right. true = left, false/nil = right (default right)
local function room(forward, udDistance, lrDistance, ud, lr)

end

--- Dig a tunnel.
-- @tparam number l The length to dig the tunnel.
-- @tparam number|nil w The width of the tunnel (default 1)
-- @tparam boolean|nil ud Whether the turtle moves up or down. true = down, false/nil = up (default up)
-- @tparam boolean|nil lr Whether the turtle moves left or right. true = left, false/nil = right (default right)
local function tunnel(l, w, ud, lr)

end

--- Dig a quarry to bedrock.
-- @tparam boolean|nil lr Whether the turtle moves left or right. true = left, false/nil = right (default right)
-- @tparam number l The length of the quarry (forwards).
-- @tparam number w The width of the quarry (left or right).
local function quarry(lr, l, w)

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

require"cc.pretty".print(require"cc.pretty".pretty(args))
if args[1] == "room" then

elseif args[1] == "tunnel" then

elseif args[1] == "quarry" then

end
