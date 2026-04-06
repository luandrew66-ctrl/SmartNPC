--[[
    SmartNPC :: ProximityManager
    Detects nearby players and manages conversation initiation/ending.
    Uses spatial queries instead of per-frame distance checks.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProximityManager = {}
ProximityManager.__index = ProximityManager

export type ProximityConfig = {
    radius: number?,
    checkInterval: number?,
    maxSimultaneous: number?,
}

function ProximityManager.new(npcModel: Model, config: ProximityConfig?)
    local self = setmetatable({}, ProximityManager)
    
    self._npcModel = npcModel
    self._radius = (config and config.radius) or 15
    self._checkInterval = (config and config.checkInterval) or 0.5
    self._maxSimultaneous = (config and config.maxSimultaneous) or 1
    
    self._nearbyPlayers = {} :: {[Player]: boolean}
    self._activeConversations = {} :: {[Player]: boolean}
    self._timeSinceCheck = 0
    self._connection = nil
    
    -- Callbacks
    self.onPlayerEnter = nil :: ((player: Player) -> ())?
    self.onPlayerExit = nil :: ((player: Player) -> ())?
    
    return self
end

function ProximityManager:start()
    if self._connection then return end
    
    self._connection = RunService.Heartbeat:Connect(function(dt)
        self._timeSinceCheck += dt
        if self._timeSinceCheck >= self._checkInterval then
            self._timeSinceCheck = 0
            self:_scan()
        end
    end)
end

function ProximityManager:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end

function ProximityManager:_scan()
    local npcRoot = self._npcModel:FindFirstChild("HumanoidRootPart")
        or self._npcModel.PrimaryPart
    if not npcRoot then return end
    
    local npcPos = npcRoot.Position
    local currentNearby = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - npcPos).Magnitude
                if dist <= self._radius then
                    currentNearby[player] = true
                end
            end
        end
    end
    
    -- Check for newly entered players
    for player in pairs(currentNearby) do
        if not self._nearbyPlayers[player] then
            if self.onPlayerEnter then
                self.onPlayerEnter(player)
            end
        end
    end
    
    -- Check for players who left
    for player in pairs(self._nearbyPlayers) do
        if not currentNearby[player] then
            self._activeConversations[player] = nil
            if self.onPlayerExit then
                self.onPlayerExit(player)
            end
        end
    end
    
    self._nearbyPlayers = currentNearby
end

function ProximityManager:isPlayerNearby(player: Player): boolean
    return self._nearbyPlayers[player] == true
end

function ProximityManager:getNearbyPlayers(): {Player}
    local list = {}
    for player in pairs(self._nearbyPlayers) do
        table.insert(list, player)
    end
    return list
end

function ProximityManager:canStartConversation(player: Player): boolean
    if not self._nearbyPlayers[player] then return false end
    
    local activeCount = 0
    for _ in pairs(self._activeConversations) do
        activeCount += 1
    end
    
    return activeCount < self._maxSimultaneous
end

function ProximityManager:registerConversation(player: Player)
    self._activeConversations[player] = true
end

function ProximityManager:endConversation(player: Player)
    self._activeConversations[player] = nil
end

function ProximityManager:getActiveConversations(): {Player}
    local list = {}
    for player in pairs(self._activeConversations) do
        table.insert(list, player)
    end
    return list
end

function ProximityManager:setRadius(radius: number)
    self._radius = radius
end

function ProximityManager:destroy()
    self:stop()
    self._nearbyPlayers = {}
    self._activeConversations = {}
end

return ProximityManager
