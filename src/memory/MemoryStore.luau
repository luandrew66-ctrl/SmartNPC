--[[
    SmartNPC :: MemoryStore
    Persistent memory using Roblox DataStores.
    Stores conversation summaries per NPC-player pair.
]]

local DataStoreService = game:GetService("DataStoreService")

local MemoryStore = {}
MemoryStore.__index = MemoryStore

local DATASTORE_NAME = "SmartNPC_Memory_v1"
local MAX_SUMMARY_LENGTH = 1000

function MemoryStore.new()
    local self = setmetatable({}, MemoryStore)
    self._store = nil
    self._cache = {} :: {[string]: string}
    self._pendingSaves = {} :: {[string]: boolean}
    
    local ok, store = pcall(function()
        return DataStoreService:GetDataStore(DATASTORE_NAME)
    end)
    
    if ok then
        self._store = store
    else
        warn("[SmartNPC] MemoryStore: Could not access DataStore - memory will be session-only")
    end
    
    return self
end

function MemoryStore:_key(npcId: string, playerId: string): string
    return "mem_" .. npcId .. "_" .. playerId
end

function MemoryStore:load(npcId: string, playerId: string): string?
    local key = self:_key(npcId, playerId)
    
    -- Check cache first
    if self._cache[key] then
        return self._cache[key]
    end
    
    -- Load from DataStore
    if not self._store then return nil end
    
    local ok, data = pcall(function()
        return self._store:GetAsync(key)
    end)
    
    if ok and data then
        self._cache[key] = data
        return data
    end
    
    return nil
end

function MemoryStore:save(npcId: string, playerId: string, summary: string)
    local key = self:_key(npcId, playerId)
    
    -- Truncate if too long
    if #summary > MAX_SUMMARY_LENGTH then
        summary = summary:sub(1, MAX_SUMMARY_LENGTH)
    end
    
    -- Update cache immediately
    self._cache[key] = summary
    
    -- Async save to DataStore
    if not self._store then return end
    if self._pendingSaves[key] then return end -- debounce
    
    self._pendingSaves[key] = true
    
    task.spawn(function()
        task.wait(2) -- batch saves
        self._pendingSaves[key] = nil
        
        local ok, err = pcall(function()
            self._store:SetAsync(key, summary)
        end)
        
        if not ok then
            warn("[SmartNPC] MemoryStore: Failed to save - " .. tostring(err))
        end
    end)
end

function MemoryStore:clear(npcId: string, playerId: string)
    local key = self:_key(npcId, playerId)
    self._cache[key] = nil
    
    if self._store then
        pcall(function()
            self._store:RemoveAsync(key)
        end)
    end
end

function MemoryStore:getCached(npcId: string, playerId: string): string?
    return self._cache[self:_key(npcId, playerId)]
end

return MemoryStore
