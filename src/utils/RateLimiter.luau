--[[
    SmartNPC :: RateLimiter
    Token bucket algorithm for per-NPC and global rate limiting.
    Prevents runaway API costs and HTTPService throttling.
]]

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimitConfig = {
    requestsPerMinute: number?,
    globalRequestsPerMinute: number?,
    tokensPerMinute: number?,
}

-- Global counters shared across all NPC instances
local globalState = {
    requestCount = 0,
    tokenCount = 0,
    lastReset = os.clock(),
}

function RateLimiter.new(config: RateLimitConfig?)
    local self = setmetatable({}, RateLimiter)
    
    self._maxRequestsPerMin = (config and config.requestsPerMinute) or 20
    self._globalMaxRequestsPerMin = (config and config.globalRequestsPerMinute) or 60
    self._maxTokensPerMin = (config and config.tokensPerMinute) or 10000
    
    self._requestCount = 0
    self._tokenCount = 0
    self._lastReset = os.clock()
    
    return self
end

function RateLimiter:_resetIfNeeded()
    local now = os.clock()
    
    -- Reset per-NPC counters
    if now - self._lastReset >= 60 then
        self._requestCount = 0
        self._tokenCount = 0
        self._lastReset = now
    end
    
    -- Reset global counters
    if now - globalState.lastReset >= 60 then
        globalState.requestCount = 0
        globalState.tokenCount = 0
        globalState.lastReset = now
    end
end

function RateLimiter:canMakeRequest(): (boolean, string?)
    self:_resetIfNeeded()
    
    if self._requestCount >= self._maxRequestsPerMin then
        return false, "Per-NPC rate limit reached (" .. self._maxRequestsPerMin .. "/min)"
    end
    
    if globalState.requestCount >= self._globalMaxRequestsPerMin then
        return false, "Global rate limit reached (" .. self._globalMaxRequestsPerMin .. "/min)"
    end
    
    if self._tokenCount >= self._maxTokensPerMin then
        return false, "Token budget exhausted (" .. self._maxTokensPerMin .. "/min)"
    end
    
    return true, nil
end

function RateLimiter:recordRequest(tokensUsed: number?)
    self._requestCount += 1
    globalState.requestCount += 1
    
    if tokensUsed then
        self._tokenCount += tokensUsed
        globalState.tokenCount += tokensUsed
    end
end

function RateLimiter:getUsage(): {requests: number, tokens: number, globalRequests: number}
    self:_resetIfNeeded()
    return {
        requests = self._requestCount,
        tokens = self._tokenCount,
        globalRequests = globalState.requestCount,
    }
end

function RateLimiter:getTimeUntilReset(): number
    return math.max(0, 60 - (os.clock() - self._lastReset))
end

function RateLimiter.resetGlobal()
    globalState.requestCount = 0
    globalState.tokenCount = 0
    globalState.lastReset = os.clock()
end

return RateLimiter
