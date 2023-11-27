local addOnName, ICT = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local AceComm = LibStub("AceComm-3.0")
local log = ICT.log
local Comms = {
    prefix = "ICT"
}
ICT.Comms = Comms

function Comms:Init()
    AceComm:Embed(self)
    self:RegisterComm(self.prefix)
    self.version = GetAddOnMetadata(addOnName, "Version")
    self.ticker = C_Timer.NewTicker(30, function() Comms:pingPlayers() end)
end

function Comms:transmitPlayer(target, player)
    log.info("Sending: %s to %s", player:getFullName(), target)
    local data = { callback = "receivePlayer", version = self.version, player = player }
    self:transmit(target, data)
end

function Comms:transmit(target, data)
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    self:SendCommMessage("ICT", encoded, "WHISPER", target)
end

function Comms:transmitPlayers(target, data)
    for k, player in pairs(ICT.db.players) do
        -- If the player is unknown or out of date, send it.
        if data.timestamps[k] and data.timestamps[k] >= player.timestamp then
            log.info("Player up to date: %s for %s", player:getFullName(), target)
        else
            self:transmitPlayer(target, player)
        end
    end
end

function Comms:forceTransmitPlayers(target)
    for _, player in pairs(ICT.db.players) do
        self:transmitPlayer(target, player)
    end
end

-- Transmit timestamps to receive which players are out of date or missing.
function Comms:transmitPlayerMetadata(target)
    local data = { callback = "transmitPlayers", version = self.version, timestamps = {} }
    for k, player in pairs(ICT.db.players) do
        data.timestamps[k] = player.timestamp
    end
    self:transmit(target, data)
end

function Comms:receivePlayer(sender, data)
    local player = ICT.Players:load(data.player)
    local prev = ICT.db.players[player:getFullName()]
    if prev and prev.timestamp >= player.timestamp then
        log.info("Ignoring up to date player: %s from %s", player:getFullName(), sender)
    else
        ICT:print("Received: %s from %s", player:getName(), sender)
        ICT.db.players[player:getFullName()] = player
        ICT.UpdateDisplay()
    end
end

function Comms:transmitMismatchVersion(target, targetVersion)
    local data = { callback = "mismatchVersion", version = targetVersion, otherVersion = self.version }
    self:transmit(target, data)
end

function Comms:mismatchVersion(sender, data)
    log.info("Mismatch versions from %s, expected %s but was %s", sender, self.version or "nil", data.version or "nil")
end

function Comms:pingPlayers()
    log.info("Pinging other accounts.")
    local allowed = ICT.db.options.comms.players or {}
    local seen = {}

    local numFriends = BNGetNumFriends()
    for i=1,numFriends do
        local friend = C_BattleNet.GetFriendAccountInfo(i)
        if ICT.db.options.comms.players[friend.battleTag] then
            local info = friend.gameAccountInfo
            if info.characterName and info.realmID == GetRealmID() then
                log.info("Pinging: %s", info.characterName)
                self:transmitPlayerMetadata(info.characterName)
            end
            seen[friend.battleTag] = true
        end
    end
    for _, v in pairs(allowed) do
        if not seen[v] then
            allowed[v] = nil
        end
    end
end

function Comms:OnCommReceived(prefix, payload, distribution, sender)
    if prefix ~= self.prefix then
        return
    end
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then
        return
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return
    end
    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then
        return
    end
    if self.version ~= data.version and data.callback ~= "mismatchVersion" then
        Comms:mismatchVersion(sender, data)
        return
    end
    if data.callback then
        self[data.callback](self, sender, data)
    end
end