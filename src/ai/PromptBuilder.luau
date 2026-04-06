--[[
    SmartNPC :: PromptBuilder
    Constructs system + context prompts for LLM calls.
    Handles personality injection, memory context, conversation rules, and game state.
]]

local PromptBuilder = {}
PromptBuilder.__index = PromptBuilder

export type NPCContext = {
    name: string,
    personality: string,
    conversationRules: {string}?,
    playerName: string?,
    playerData: {[string]: any}?,
    memoryContext: string?,
    gameContext: string?,
    maxResponseLength: number?,
}

function PromptBuilder.new()
    local self = setmetatable({}, PromptBuilder)
    return self
end

function PromptBuilder:buildSystemPrompt(context: NPCContext): string
    local parts = {}
    
    -- Core identity
    table.insert(parts, "You are " .. context.name .. ", an NPC in a Roblox game.")
    table.insert(parts, "")
    
    -- Personality
    table.insert(parts, "PERSONALITY:")
    table.insert(parts, context.personality)
    table.insert(parts, "")
    
    -- Conversation rules
    if context.conversationRules and #context.conversationRules > 0 then
        table.insert(parts, "RULES YOU MUST FOLLOW:")
        for i, rule in ipairs(context.conversationRules) do
            table.insert(parts, tostring(i) .. ". " .. rule)
        end
        table.insert(parts, "")
    end
    
    -- Memory context
    if context.memoryContext and context.memoryContext ~= "" then
        table.insert(parts, "MEMORY OF PAST INTERACTIONS WITH THIS PLAYER:")
        table.insert(parts, context.memoryContext)
        table.insert(parts, "")
    end
    
    -- Game context
    if context.gameContext and context.gameContext ~= "" then
        table.insert(parts, "CURRENT GAME STATE:")
        table.insert(parts, context.gameContext)
        table.insert(parts, "")
    end
    
    -- Player info
    if context.playerName then
        table.insert(parts, "The player you are talking to is named: " .. context.playerName)
    end
    
    if context.playerData then
        local dataLines = {}
        for key, value in pairs(context.playerData) do
            table.insert(dataLines, key .. ": " .. tostring(value))
        end
        if #dataLines > 0 then
            table.insert(parts, "Player data: " .. table.concat(dataLines, ", "))
        end
    end
    
    table.insert(parts, "")
    
    -- Response constraints
    table.insert(parts, "RESPONSE FORMAT:")
    table.insert(parts, "- Stay in character at all times.")
    table.insert(parts, "- Respond conversationally as this character would speak.")
    table.insert(parts, "- Keep responses concise (1-3 sentences unless the situation requires more).")
    table.insert(parts, "- Never break character or mention that you are an AI.")
    table.insert(parts, "- Never use markdown formatting, asterisks, or special characters.")
    table.insert(parts, "- If you want to perform a game action, prefix it with [ACTION: action_name].")
    
    if context.maxResponseLength then
        table.insert(parts, "- Keep your response under " .. tostring(context.maxResponseLength) .. " characters.")
    end
    
    return table.concat(parts, "\n")
end

function PromptBuilder:buildConversationMessages(
    systemPrompt: string,
    history: {{role: string, content: string}},
    playerMessage: string
): {{role: string, content: string}}
    local messages = {}
    
    -- System prompt
    table.insert(messages, {
        role = "system",
        content = systemPrompt,
    })
    
    -- Conversation history
    for _, msg in ipairs(history) do
        table.insert(messages, {
            role = msg.role,
            content = msg.content,
        })
    end
    
    -- Current player message
    table.insert(messages, {
        role = "user",
        content = playerMessage,
    })
    
    return messages
end

-- Build a memory summary prompt to compress long conversation histories
function PromptBuilder:buildSummaryPrompt(history: {{role: string, content: string}}): string
    local lines = {}
    table.insert(lines, "Summarize the following conversation between an NPC and a player in 2-3 sentences.")
    table.insert(lines, "Focus on: key topics discussed, any promises or quests given, the player's emotional tone, and important facts revealed.")
    table.insert(lines, "Respond with ONLY the summary, no preamble.")
    table.insert(lines, "")
    table.insert(lines, "CONVERSATION:")
    
    for _, msg in ipairs(history) do
        local speaker = msg.role == "user" and "Player" or "NPC"
        table.insert(lines, speaker .. ": " .. msg.content)
    end
    
    return table.concat(lines, "\n")
end

return PromptBuilder
