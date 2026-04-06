--[[
    SmartNPC :: SmartNPCController
    Main entry point. Drop-in AI-powered NPCs for Roblox.
    
    Usage:
        local SmartNPC = require(path.to.SmartNPCController)
        SmartNPC.configure({ provider = "openai", apiKey = "sk-..." })
        local npc = SmartNPC.new(workspace.MyNPC, { personality = "A wise wizard..." })
]]

local Players = game:GetService("Players")

-- Module imports (adjust paths based on your project structure)
local BehaviorTree = require(script.Parent.core.BehaviorTree)
local StateMachine = require(script.Parent.core.StateMachine)
local ProximityManager = require(script.Parent.core.ProximityManager)
local LLMBridge = require(script.Parent.ai.LLMBridge)
local PromptBuilder = require(script.Parent.ai.PromptBuilder)
local ResponseParser = require(script.Parent.ai.ResponseParser)
local ConversationLog = require(script.Parent.memory.ConversationLog)
local MemoryStore = require(script.Parent.memory.MemoryStore)
local RateLimiter = require(script.Parent.utils.RateLimiter)
local TokenCounter = require(script.Parent.utils.TokenCounter)
local Logger = require(script.Parent.utils.Logger)
local Templates = require(script.Parent.templates.Templates)

local SmartNPC = {}
SmartNPC.__index = SmartNPC

-- Global configuration
local globalConfig = {
    provider = "openai" :: string,
    apiKey = "" :: string,
    model = nil :: string?,
    rateLimits = nil,
    debug = false,
    fallbackResponse = "Hmm, let me think about that...",
    maxConversationLength = 30,
}

local globalBridge: any = nil
local globalMemoryStore: any = nil
local globalConversationLog: any = nil

-- Templates exposed on the module
SmartNPC.Templates = Templates

---------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------

function SmartNPC.configure(config: {
    provider: string?,
    apiKey: string?,
    model: string?,
    rateLimits: any?,
    debug: boolean?,
    fallbackResponse: string?,
    maxConversationLength: number?,
})
    if config.provider then globalConfig.provider = config.provider end
    if config.apiKey then globalConfig.apiKey = config.apiKey end
    if config.model then globalConfig.model = config.model end
    if config.rateLimits then globalConfig.rateLimits = config.rateLimits end
    if config.debug ~= nil then globalConfig.debug = config.debug end
    if config.fallbackResponse then globalConfig.fallbackResponse = config.fallbackResponse end
    if config.maxConversationLength then globalConfig.maxConversationLength = config.maxConversationLength end
    
    -- Set log level
    if globalConfig.debug then
        Logger.setLevel(Logger.LEVELS.DEBUG)
    else
        Logger.setLevel(Logger.LEVELS.WARN)
    end
    
    -- Initialize shared resources
    globalBridge = LLMBridge.new({
        provider = globalConfig.provider,
        apiKey = globalConfig.apiKey,
        model = globalConfig.model,
    })
    
    globalMemoryStore = MemoryStore.new()
    globalConversationLog = ConversationLog.new()
    
    Logger.info("SmartNPC configured with provider:", globalConfig.provider)
end

---------------------------------------------------------------------
-- NPC INSTANCE CREATION
---------------------------------------------------------------------

export type NPCConfig = {
    name: string?,
    personality: string,
    memory: boolean?,
    memoryLength: number?,
    memoryPersist: boolean?,
    maxTokensPerReply: number?,
    conversationRules: {string}?,
    conversationTimeout: number?,
    proximityRadius: number?,
    behaviorTree: any?,
    gameContextProvider: ((player: Player) -> string)?,
    playerDataProvider: ((player: Player) -> {[string]: any})?,
    onConversationStart: ((player: Player) -> ())?,
    onConversationEnd: ((player: Player) -> ())?,
    onNPCResponse: ((player: Player, response: string) -> ())?,
    onAction: ((player: Player, action: string) -> ())?,
}

function SmartNPC.new(npcModel: Model, config: NPCConfig)
    assert(globalBridge, "[SmartNPC] Call SmartNPC.configure() before creating NPCs")
    assert(config.personality, "[SmartNPC] 'personality' is required in config")
    
    local self = setmetatable({}, SmartNPC)
    
    -- Config
    self._model = npcModel
    self._npcId = npcModel:GetFullName()
    self._name = config.name or npcModel.Name
    self._personality = config.personality
    self._useMemory = config.memory or false
    self._memoryLength = config.memoryLength or 10
    self._memoryPersist = config.memoryPersist or false
    self._maxTokens = config.maxTokensPerReply or 200
    self._rules = config.conversationRules or {}
    self._timeout = config.conversationTimeout or 30
    self._gameContextProvider = config.gameContextProvider
    self._playerDataProvider = config.playerDataProvider
    
    -- Callbacks
    self._onConversationStart = config.onConversationStart
    self._onConversationEnd = config.onConversationEnd
    self._onNPCResponse = config.onNPCResponse
    self._onAction = config.onAction
    
    -- Internal state
    self._promptBuilder = PromptBuilder.new()
    self._rateLimiter = RateLimiter.new(globalConfig.rateLimits)
    self._activePlayer = nil :: Player?
    self._conversationCount = 0
    self._destroyed = false
    
    -- Proximity detection
    self._proximity = ProximityManager.new(npcModel, {
        radius = config.proximityRadius or 15,
    })
    
    -- State machine
    self._stateMachine = StateMachine.new(
        StateMachine.createNPCStates({
            onIdle = function() Logger.debug(self._name, "is idle") end,
            onApproach = function(_, data)
                Logger.debug(self._name, "approaching player")
            end,
            onStartTalking = function(_, data)
                if data and data.player then
                    self._activePlayer = data.player
                    self._conversationCount = 0
                    self._proximity:registerConversation(data.player)
                    if self._onConversationStart then
                        self._onConversationStart(data.player)
                    end
                end
            end,
            onStopTalking = function()
                if self._activePlayer then
                    self._proximity:endConversation(self._activePlayer)
                    if self._onConversationEnd then
                        self._onConversationEnd(self._activePlayer)
                    end
                    
                    -- Save memory if persistent
                    if self._useMemory and self._memoryPersist and self._activePlayer then
                        self:_saveMemory(self._activePlayer)
                    end
                    
                    self._activePlayer = nil
                end
            end,
            onTalkingUpdate = function(_, dt)
                -- Check for conversation timeout
            end,
            onAct = function() end,
            onCooldown = function() Logger.debug(self._name, "cooling down") end,
        }),
        "Idle"
    )
    
    -- Set up proximity callbacks
    self._proximity.onPlayerEnter = function(player: Player)
        if self._stateMachine:getState() == "Idle" then
            self._stateMachine:transition("startConversation", { player = player })
            self:_sendGreeting(player)
        end
    end
    
    self._proximity.onPlayerExit = function(player: Player)
        if self._activePlayer == player then
            self._stateMachine:transition("playerLeft")
        end
    end
    
    -- Start proximity scanning
    self._proximity:start()
    
    Logger.info("SmartNPC created:", self._name)
    return self
end

---------------------------------------------------------------------
-- CHAT INTERFACE
---------------------------------------------------------------------

-- Process a message from a player and return the NPC's response
function SmartNPC:chat(player: Player, message: string): string
    if self._destroyed then
        return globalConfig.fallbackResponse
    end
    
    -- Rate limit check
    local canProceed, reason = self._rateLimiter:canMakeRequest()
    if not canProceed then
        Logger.warn(self._name, "rate limited:", reason)
        return globalConfig.fallbackResponse
    end
    
    -- Conversation length check
    self._conversationCount += 1
    if self._conversationCount > globalConfig.maxConversationLength then
        self._stateMachine:transition("conversationEnd")
        return "I've enjoyed our conversation, but I must attend to other matters. Come back anytime!"
    end
    
    -- Ensure we're in talking state
    if self._stateMachine:getState() ~= "Talking" then
        self._stateMachine:forceState("Talking", { player = player })
    end
    
    -- Build context
    local memoryContext = ""
    if self._useMemory then
        -- Load persistent memory
        if self._memoryPersist then
            local saved = globalMemoryStore:load(self._npcId, tostring(player.UserId))
            if saved then
                memoryContext = saved
            end
        end
    end
    
    local gameContext = ""
    if self._gameContextProvider then
        local ok, ctx = pcall(self._gameContextProvider, player)
        if ok and ctx then
            gameContext = ctx
        end
    end
    
    local playerData = nil
    if self._playerDataProvider then
        local ok, data = pcall(self._playerDataProvider, player)
        if ok and data then
            playerData = data
        end
    end
    
    -- Build system prompt
    local systemPrompt = self._promptBuilder:buildSystemPrompt({
        name = self._name,
        personality = self._personality,
        conversationRules = self._rules,
        playerName = player.DisplayName or player.Name,
        playerData = playerData,
        memoryContext = memoryContext,
        gameContext = gameContext,
        maxResponseLength = self._maxTokens * 4, -- rough char estimate
    })
    
    -- Get conversation history
    local history = globalConversationLog:getHistory(self._npcId, tostring(player.UserId))
    
    -- Truncate history to fit token budget (reserve tokens for system prompt + reply)
    local systemTokens = TokenCounter.estimate(systemPrompt)
    local budgetForHistory = math.max(0, 2000 - systemTokens - self._maxTokens)
    history = TokenCounter.truncateHistory(history, budgetForHistory)
    
    -- Build messages
    local messages = self._promptBuilder:buildConversationMessages(systemPrompt, history, message)
    
    -- Log player message
    globalConversationLog:add(self._npcId, tostring(player.UserId), "user", message)
    
    -- Call LLM
    Logger.debug(self._name, "sending request to", globalConfig.provider)
    local response = globalBridge:chat(messages)
    
    if not response.success then
        Logger.error(self._name, "LLM error:", response.error)
        return globalConfig.fallbackResponse
    end
    
    -- Record rate limit usage
    self._rateLimiter:recordRequest(response.tokensUsed)
    
    -- Parse response
    local parsed = ResponseParser.parse(response.text or "")
    local dialogue = ResponseParser.sanitize(parsed.dialogue)
    
    if dialogue == "" then
        dialogue = globalConfig.fallbackResponse
    end
    
    -- Log NPC response
    globalConversationLog:add(self._npcId, tostring(player.UserId), "assistant", dialogue)
    
    -- Fire action callbacks
    for _, action in ipairs(parsed.actions) do
        if self._onAction then
            self._onAction(player, action)
        end
    end
    
    -- Fire response callback
    if self._onNPCResponse then
        self._onNPCResponse(player, dialogue)
    end
    
    -- Check if conversation should end
    if ResponseParser.isConversationEnder(dialogue) then
        task.delay(2, function()
            self._stateMachine:transition("conversationEnd")
        end)
    end
    
    Logger.debug(self._name, "responded in", response.latencyMs, "ms using", response.tokensUsed, "tokens")
    
    return dialogue
end

---------------------------------------------------------------------
-- GREETING
---------------------------------------------------------------------

function SmartNPC:_sendGreeting(player: Player)
    task.spawn(function()
        local greeting = self:chat(player, "[Player has approached " .. self._name .. ". Greet them in character.]")
        -- The greeting is delivered via the onNPCResponse callback
        -- Game developers can display it however they want (chat bubble, GUI, etc.)
    end)
end

---------------------------------------------------------------------
-- MEMORY MANAGEMENT
---------------------------------------------------------------------

function SmartNPC:_saveMemory(player: Player)
    local history = globalConversationLog:getHistory(self._npcId, tostring(player.UserId))
    if #history == 0 then return end
    
    -- Build a summary of the conversation for persistent storage
    local summary = globalConversationLog:getFormattedSummary(self._npcId, tostring(player.UserId))
    
    -- For a more sophisticated approach, you could call the LLM to summarize
    -- But for cost efficiency, we just store the raw history truncated
    if #summary > 800 then
        summary = summary:sub(1, 800)
    end
    
    globalMemoryStore:save(self._npcId, tostring(player.UserId), summary)
    Logger.debug(self._name, "saved memory for player", player.Name)
end

---------------------------------------------------------------------
-- PUBLIC METHODS
---------------------------------------------------------------------

function SmartNPC:getState(): string
    return self._stateMachine:getState()
end

function SmartNPC:isInConversation(): boolean
    return self._stateMachine:getState() == "Talking"
end

function SmartNPC:getActivePlayer(): Player?
    return self._activePlayer
end

function SmartNPC:endConversation()
    self._stateMachine:transition("conversationEnd")
end

function SmartNPC:setPersonality(personality: string)
    self._personality = personality
end

function SmartNPC:addRule(rule: string)
    table.insert(self._rules, rule)
end

function SmartNPC:clearMemory(player: Player)
    globalConversationLog:clear(self._npcId, tostring(player.UserId))
    globalMemoryStore:clear(self._npcId, tostring(player.UserId))
end

function SmartNPC:destroy()
    self._destroyed = true
    self._proximity:destroy()
    if self._activePlayer then
        self._stateMachine:transition("playerLeft")
    end
    Logger.info(self._name, "destroyed")
end

---------------------------------------------------------------------
-- STATIC UTILITIES
---------------------------------------------------------------------

function SmartNPC.getUsage(): {requests: number, tokens: number}
    if not globalBridge then return { requests = 0, tokens = 0 } end
    return { requests = 0, tokens = 0 } -- simplified
end

return SmartNPC
