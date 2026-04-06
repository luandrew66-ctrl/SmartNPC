--[[
    SmartNPC :: TokenCounter
    Approximate token counting for cost estimation.
    Uses the ~4 chars per token heuristic for English text.
]]

local TokenCounter = {}

-- Approximate token count (English text averages ~4 chars per token)
function TokenCounter.estimate(text: string): number
    if not text or text == "" then return 0 end
    return math.ceil(#text / 4)
end

-- Estimate tokens for an array of messages
function TokenCounter.estimateMessages(messages: {{role: string, content: string}}): number
    local total = 0
    for _, msg in ipairs(messages) do
        total += TokenCounter.estimate(msg.content)
        total += 4 -- overhead per message (role, formatting)
    end
    total += 3 -- conversation overhead
    return total
end

-- Estimate cost in USD (rough)
function TokenCounter.estimateCost(inputTokens: number, outputTokens: number, model: string): number
    local pricing = {
        ["gpt-4o-mini"] = { input = 0.15, output = 0.60 }, -- per 1M tokens
        ["gpt-4o"] = { input = 2.50, output = 10.00 },
        ["claude-sonnet-4-20250514"] = { input = 3.00, output = 15.00 },
        ["claude-haiku-4-5-20251001"] = { input = 0.80, output = 4.00 },
    }
    
    local p = pricing[model] or { input = 1.0, output = 3.0 }
    return (inputTokens * p.input + outputTokens * p.output) / 1000000
end

-- Truncate conversation history to fit within a token budget
function TokenCounter.truncateHistory(
    history: {{role: string, content: string}},
    maxTokens: number
): {{role: string, content: string}}
    local total = 0
    local result = {}
    
    -- Walk backwards from most recent, keeping messages until budget is hit
    for i = #history, 1, -1 do
        local msgTokens = TokenCounter.estimate(history[i].content) + 4
        if total + msgTokens > maxTokens then
            break
        end
        total += msgTokens
        table.insert(result, 1, history[i])
    end
    
    return result
end

return TokenCounter
