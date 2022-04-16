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

local args = table.pack(...)
for i = 1, args.n do args[i] = args[i]:lower() end

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

-- Parse arguments.
if args[1] == "room" then
  local ud, lr, last
  for i = 2, args.n do
    last = i
    local nextArg = args[i]

    if nextArg == "up" then
      ud = true
    elseif nextArg == "down" then
      ud = false
    elseif nextArg == "left" then
      lr = true
    elseif nextArg == "right" then
      lr = false
    elseif type(nextArg) == "number" then
      break
    end
  end

  -- forward is arg[last]
  args[last] = tonumber(args[last])
  -- up/down is arg[last + 1]
  args[last + 1] = tonumber(args[last + 1])
  -- left/right is arg[last + 2]
  args[last + 2] = tonumber(args[last + 2])

  if args[last]) and args[last + 1]) and args[last + 2]) then
    -- Here we can allow numbers which are negative to dictate direction as well.
    -- most useful for up/down
    -- "dig room 5 -10 4" would dig a 5 length, 4 width, 10 block down room.
    if args[last + 1] < 0 then
      ud = not ud
    end
    if args[last + 2] < 0 then
      lr = not lr
    end

    -- dig the room.
    return room(args[last], args[last + 1], args[last + 2], ud, lr)
  end
  error("Expected three numbers for forward distance, up/down distance, and left/right distance.", 0)
elseif args[1] == "tunnel" then

elseif args[1] == "quarry" then

end
