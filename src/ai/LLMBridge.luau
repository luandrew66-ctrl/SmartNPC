--[[
    SmartNPC :: LLMBridge
    HTTPService wrapper for OpenAI and Anthropic APIs.
    Handles request formatting, response parsing, error recovery, and retries.
]]

local HttpService = game:GetService("HttpService")

local LLMBridge = {}
LLMBridge.__index = LLMBridge

export type Provider = "openai" | "anthropic"

export type LLMConfig = {
    provider: Provider,
    apiKey: string,
    model: string?,
    maxTokens: number?,
    temperature: number?,
    baseUrl: string?,
}

export type Message = {
    role: "system" | "user" | "assistant",
    content: string,
}

export type LLMResponse = {
    success: boolean,
    text: string?,
    tokensUsed: number?,
    error: string?,
    latencyMs: number?,
}

local ENDPOINTS = {
    openai = "https://api.openai.com/v1/chat/completions",
    anthropic = "https://api.anthropic.com/v1/messages",
}

local DEFAULT_MODELS = {
    openai = "gpt-4o-mini",
    anthropic = "claude-sonnet-4-20250514",
}

function LLMBridge.new(config: LLMConfig)
    local self = setmetatable({}, LLMBridge)
    
    self._provider = config.provider or "openai"
    self._apiKey = config.apiKey
    self._model = config.model or DEFAULT_MODELS[self._provider]
    self._maxTokens = config.maxTokens or 200
    self._temperature = config.temperature or 0.7
    self._baseUrl = config.baseUrl or ENDPOINTS[self._provider]
    self._retries = 2
    self._retryDelay = 1
    
    return self
end

function LLMBridge:chat(messages: {Message}): LLMResponse
    local startTime = tick()
    
    for attempt = 1, self._retries + 1 do
        local ok, result = pcall(function()
            if self._provider == "openai" then
                return self:_callOpenAI(messages)
            elseif self._provider == "anthropic" then
                return self:_callAnthropic(messages)
            else
                error("Unknown provider: " .. tostring(self._provider))
            end
        end)
        
        if ok and result.success then
            result.latencyMs = math.floor((tick() - startTime) * 1000)
            return result
        end
        
        if attempt <= self._retries then
            task.wait(self._retryDelay * attempt)
        else
            return {
                success = false,
                error = ok and (result.error or "Unknown error") or tostring(result),
                latencyMs = math.floor((tick() - startTime) * 1000),
            }
        end
    end
    
    -- Should not reach here
    return { success = false, error = "Exhausted retries" }
end

function LLMBridge:_callOpenAI(messages: {Message}): LLMResponse
    local body = HttpService:JSONEncode({
        model = self._model,
        messages = messages,
        max_tokens = self._maxTokens,
        temperature = self._temperature,
    })
    
    local response = HttpService:RequestAsync({
        Url = self._baseUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. self._apiKey,
        },
        Body = body,
    })
    
    if not response.Success then
        return {
            success = false,
            error = "HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.Body),
        }
    end
    
    local data = HttpService:JSONDecode(response.Body)
    
    if data.error then
        return {
            success = false,
            error = data.error.message or "OpenAI API error",
        }
    end
    
    local choice = data.choices and data.choices[1]
    if not choice then
        return { success = false, error = "No choices in response" }
    end
    
    local tokensUsed = 0
    if data.usage then
        tokensUsed = (data.usage.prompt_tokens or 0) + (data.usage.completion_tokens or 0)
    end
    
    return {
        success = true,
        text = choice.message.content,
        tokensUsed = tokensUsed,
    }
end

function LLMBridge:_callAnthropic(messages: {Message}): LLMResponse
    -- Anthropic uses a separate system parameter
    local systemPrompt = nil
    local chatMessages = {}
    
    for _, msg in ipairs(messages) do
        if msg.role == "system" then
            systemPrompt = msg.content
        else
            table.insert(chatMessages, {
                role = msg.role,
                content = msg.content,
            })
        end
    end
    
    local requestBody: any = {
        model = self._model,
        max_tokens = self._maxTokens,
        messages = chatMessages,
        temperature = self._temperature,
    }
    
    if systemPrompt then
        requestBody.system = systemPrompt
    end
    
    local body = HttpService:JSONEncode(requestBody)
    
    local response = HttpService:RequestAsync({
        Url = self._baseUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["x-api-key"] = self._apiKey,
            ["anthropic-version"] = "2023-06-01",
        },
        Body = body,
    })
    
    if not response.Success then
        return {
            success = false,
            error = "HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.Body),
        }
    end
    
    local data = HttpService:JSONDecode(response.Body)
    
    if data.error then
        return {
            success = false,
            error = data.error.message or "Anthropic API error",
        }
    end
    
    local text = ""
    if data.content and data.content[1] then
        text = data.content[1].text or ""
    end
    
    local tokensUsed = 0
    if data.usage then
        tokensUsed = (data.usage.input_tokens or 0) + (data.usage.output_tokens or 0)
    end
    
    return {
        success = true,
        text = text,
        tokensUsed = tokensUsed,
    }
end

function LLMBridge:setModel(model: string)
    self._model = model
end

function LLMBridge:setTemperature(temp: number)
    self._temperature = math.clamp(temp, 0, 2)
end

function LLMBridge:setMaxTokens(tokens: number)
    self._maxTokens = tokens
end

return LLMBridge
