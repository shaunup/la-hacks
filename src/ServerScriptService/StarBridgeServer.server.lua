-- StarBridgeServer: matchmaking + real-time star sync for the 2-player
-- constellation co-op game.
--
-- Protocol:
--   Client → Server  StarBridge_Join(player)         → sessionId or "waiting"
--   Client → Server  StarBridge_PlaceStar(sessionId, x, y, color)  → ok
--   Client → Server  StarBridge_Leave(sessionId)     → ok
--   Server → Client  StarBridge_StarPlaced (RemoteEvent) fires to partner
--   Server → Client  StarBridge_PartnerJoined fires to waiting player
--   Server → Client  StarBridge_PartnerLeft  fires to remaining player

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- ─── Remotes ────────────────────────────────────────────────────────────────

local function makeFunc(name)
	local r = Instance.new("RemoteFunction")
	r.Name   = name
	r.Parent = ReplicatedStorage
	return r
end

local function makeEvent(name)
	local r = Instance.new("RemoteEvent")
	r.Name   = name
	r.Parent = ReplicatedStorage
	return r
end

local JoinFunc      = makeFunc("StarBridge_Join")
local PlaceStarFunc = makeFunc("StarBridge_PlaceStar")
local LeaveFunc     = makeFunc("StarBridge_Leave")

local PartnerJoinedEvent = makeEvent("StarBridge_PartnerJoined")
local StarPlacedEvent    = makeEvent("StarBridge_StarPlaced")
local PartnerLeftEvent   = makeEvent("StarBridge_PartnerLeft")
local ConstellationDoneEvent = makeEvent("StarBridge_ConstellationDone")

-- ─── State ───────────────────────────────────────────────────────────────────

local waitingPlayer  = nil   -- player waiting for a match
local sessions       = {}    -- sessionId → { p1, p2, stars }
local playerSession  = {}    -- player → sessionId

local function makeSessionId()
	return tostring(math.random(100000, 999999))
end

-- ─── Join ─────────────────────────────────────────────────────────────────────

JoinFunc.OnServerInvoke = function(player)
	-- Already in a session?
	if playerSession[player] then
		return playerSession[player]
	end

	if waitingPlayer and waitingPlayer ~= player and waitingPlayer.Parent then
		-- Match!
		local id = makeSessionId()
		local session = {
			p1    = waitingPlayer,
			p2    = player,
			stars = {},  -- { playerId, x, y, colorIdx }
		}
		sessions[id]              = session
		playerSession[waitingPlayer] = id
		playerSession[player]        = id
		waitingPlayer                = nil

		-- Notify both
		PartnerJoinedEvent:FireClient(session.p1, player.Name, id)
		PartnerJoinedEvent:FireClient(session.p2, session.p1.Name, id)

		print("[StarBridgeServer] Matched:", session.p1.Name, "+", player.Name, "→ session", id)
		return id
	else
		-- Wait
		waitingPlayer = player
		print("[StarBridgeServer]", player.Name, "waiting for partner…")
		return "waiting"
	end
end

-- ─── Place Star ───────────────────────────────────────────────────────────────

PlaceStarFunc.OnServerInvoke = function(player, sessionId, x, y, colorIdx)
	local session = sessions[sessionId]
	if not session then return false end

	local star = { playerId = player.UserId, x = x, y = y, colorIdx = colorIdx }
	table.insert(session.stars, star)

	-- Fire to both players
	StarPlacedEvent:FireClient(session.p1, player.Name, x, y, colorIdx)
	StarPlacedEvent:FireClient(session.p2, player.Name, x, y, colorIdx)

	-- Check constellation complete (10 stars total)
	if #session.stars >= 10 then
		ConstellationDoneEvent:FireClient(session.p1)
		ConstellationDoneEvent:FireClient(session.p2)
	end

	return true
end

-- ─── Leave ────────────────────────────────────────────────────────────────────

LeaveFunc.OnServerInvoke = function(player, sessionId)
	local session = sessions[sessionId]
	if session then
		local partner = session.p1 == player and session.p2 or session.p1
		if partner and partner.Parent then
			PartnerLeftEvent:FireClient(partner)
		end
		sessions[sessionId] = nil
		playerSession[session.p1] = nil
		playerSession[session.p2] = nil
	end

	-- If still waiting
	if waitingPlayer == player then
		waitingPlayer = nil
	end

	playerSession[player] = nil
	return true
end

-- ─── Cleanup on disconnect ────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
	local sessionId = playerSession[player]
	if sessionId then
		LeaveFunc.OnServerInvoke(player, sessionId)
	elseif waitingPlayer == player then
		waitingPlayer = nil
	end
	playerSession[player] = nil
end)

print("[StarBridgeServer] Ready.")
