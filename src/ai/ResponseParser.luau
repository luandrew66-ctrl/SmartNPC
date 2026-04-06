--[[
    SmartNPC :: ResponseParser
    Extracts dialogue text and action commands from LLM responses.
    Actions are prefixed with [ACTION: action_name] in the LLM output.
]]

local ResponseParser = {}

export type ParsedResponse = {
    dialogue: string,
    actions: {string},
    metadata: {[string]: string}?,
}

function ResponseParser.parse(rawText: string): ParsedResponse
    local actions = {}
    local dialogue = rawText
    
    -- Extract [ACTION: xxx] tags
    dialogue = string.gsub(dialogue, "%[ACTION:%s*(.-)%]", function(action)
        table.insert(actions, action:match("^%s*(.-)%s*$")) -- trim
        return ""
    end)
    
    -- Extract [EMOTE: xxx] tags
    local emotes = {}
    dialogue = string.gsub(dialogue, "%[EMOTE:%s*(.-)%]", function(emote)
        table.insert(emotes, emote:match("^%s*(.-)%s*$"))
        return ""
    end)
    
    -- Clean up extra whitespace and newlines
    dialogue = dialogue:match("^%s*(.-)%s*$") or ""
    dialogue = dialogue:gsub("\n+", " ")
    dialogue = dialogue:gsub("%s+", " ")
    
    -- Remove any remaining markdown artifacts
    dialogue = dialogue:gsub("%*%*(.-)%*%*", "%1")
    dialogue = dialogue:gsub("%*(.-)%*", "%1")
    dialogue = dialogue:gsub("```.-```", "")
    
    local metadata = nil
    if #emotes > 0 then
        metadata = { emotes = table.concat(emotes, ",") }
    end
    
    return {
        dialogue = dialogue,
        actions = actions,
        metadata = metadata,
    }
end

-- Sanitize text for display in Roblox chat/billboardgui
function ResponseParser.sanitize(text: string): string
    -- Remove potentially problematic characters
    local clean = text:gsub("[<>]", "")
    
    -- Enforce max length for display
    if #clean > 500 then
        clean = clean:sub(1, 497) .. "..."
    end
    
    return clean
end

-- Check if response indicates the NPC wants to end the conversation
function ResponseParser.isConversationEnder(text: string): boolean
    local lower = text:lower()
    local endings = {
        "farewell", "goodbye", "safe travels", "be on your way",
        "come back", "until next time", "off you go",
    }
    for _, phrase in ipairs(endings) do
        if lower:find(phrase, 1, true) then
            return true
        end
    end
    return false
end

return ResponseParser
