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

elseif args[1] == "tunnel" then

elseif args[1] == "quarry" then

end
