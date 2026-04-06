--[[
    SmartNPC :: ConversationLog
    Per-player conversation history with automatic pruning.
]]

local ConversationLog = {}
ConversationLog.__index = ConversationLog

export type LogEntry = {
    role: "user" | "assistant",
    content: string,
    timestamp: number,
}

function ConversationLog.new(maxLength: number?)
    local self = setmetatable({}, ConversationLog)
    self._logs = {} :: {[string]: {LogEntry}} -- keyed by npcId:playerId
    self._maxLength = maxLength or 10
    return self
end

function ConversationLog:_key(npcId: string, playerId: string): string
    return npcId .. ":" .. playerId
end

function ConversationLog:add(npcId: string, playerId: string, role: "user" | "assistant", content: string)
    local key = self:_key(npcId, playerId)
    if not self._logs[key] then
        self._logs[key] = {}
    end
    
    table.insert(self._logs[key], {
        role = role,
        content = content,
        timestamp = os.time(),
    })
    
    -- Prune if over max length (keep most recent)
    while #self._logs[key] > self._maxLength * 2 do
        table.remove(self._logs[key], 1)
    end
end

function ConversationLog:getHistory(npcId: string, playerId: string): {{role: string, content: string}}
    local key = self:_key(npcId, playerId)
    local log = self._logs[key]
    if not log then return {} end
    
    local history = {}
    -- Return the most recent entries up to maxLength
    local start = math.max(1, #log - self._maxLength + 1)
    for i = start, #log do
        table.insert(history, {
            role = log[i].role,
            content = log[i].content,
        })
    end
    return history
end

function ConversationLog:clear(npcId: string, playerId: string)
    local key = self:_key(npcId, playerId)
    self._logs[key] = nil
end

function ConversationLog:clearAll(npcId: string)
    local prefix = npcId .. ":"
    for key in pairs(self._logs) do
        if key:sub(1, #prefix) == prefix then
            self._logs[key] = nil
        end
    end
end

function ConversationLog:getFormattedSummary(npcId: string, playerId: string): string
    local history = self:getHistory(npcId, playerId)
    if #history == 0 then return "" end
    
    local lines = {}
    for _, entry in ipairs(history) do
        local speaker = entry.role == "user" and "Player" or "NPC"
        table.insert(lines, speaker .. ": " .. entry.content)
    end
    return table.concat(lines, "\n")
end

return ConversationLog
