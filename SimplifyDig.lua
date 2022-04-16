-- Digging utility to dig things because epic

--[[
  Planned arguments:
  dig <room|tunnel|quarry|help>
  dig room [up/down=down] [left/right=right] <forward distance> <up/down distance> <left/right distance>
  dig tunnel <length> [width=1]
  dig quarry [left/right=right] <forward distance> <left/right distance>
  dig help [room/tunnel/quarry]

  All distances are excluding the current block, the turtle assumes the current
  block is "behind" where it is meant to dig.
]]

--- Dig a room.
-- @tparam number forward The distsance forward to dig.
-- @tparam number udDistance The distance up/down to dig.
-- @tparam number lrdistance The distance left/right to dig.
-- @tparam boolean|nil ud Whether the turtle moves up or down. true = down, false/nil = up (default up)
-- @tparam boolean|nil lr Whether the turtle moves left or right. true = right, false/nil = left (default left)
local function room(forward, udDistance, lrDistance, ud, lr)

end

--- Dig a tunnel.
-- @tparam number l The length to dig the tunnel.
-- @tparam number|nil w The width of the tunnel (default 1)
local function tunnel(l, w)

end

--- Dig a quarry to bedrock.
-- @tparam boolean|nil lr Whether the turtle moves left or right. true = right, false/nil = left (default left)
-- @tparam number l The length of the quarry (forwards).
-- @tparam number w The width of the quarry (left or right).
local function quarry(lr, l, w)

end

-- extremely basic parser, will parse the following:
-- program arg -f --flag -qwe arg2
-- into the following:
--[[
  {
    args = {"arg", "arg2"},
    flags = {
      ["f"] = true,
      ["flag"] = true,
      ["q"] = true,
      ["w"] = true,
      ["e"] = true
    }
  }

]]

-- these are actual parsers, each one takes the input from the parsed string, and the argument table.
local parsers = {
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
      local m = args[i]:match(parsers[j][1]) -- try parsing the string
      if m then -- if successful
        parsers[j][2](m, arguments) -- run the parser.
        break -- then go to the next argument.
      end
    end
  end

  return arguments
end

-- Parse arguments.
local args = parse(...)
if args[1] == "room" then

elseif args[1] == "tunnel" then

elseif args[1] == "quarry" then

end
