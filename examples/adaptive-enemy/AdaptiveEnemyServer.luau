--[[
    SmartNPC Example: Adaptive Enemy
    
    A boss NPC that taunts players during combat,
    adapts its dialogue based on fight progress, and
    has different moods depending on its health.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SmartNPC = require(ReplicatedStorage.SmartNPC)

-- Assumes SmartNPC.configure() was already called

local boss = SmartNPC.new(workspace.NPCs.DragonLord, {
    name = "Vaelgor the Dragon Lord",
    
    personality = [[
        You are Vaelgor, an ancient dragon who has taken humanoid form.
        You are arrogant, theatrical, and love dramatic monologues.
        You view humans as entertaining insects. You fight not out of 
        malice but boredom — you haven't had a worthy opponent in centuries.
        
        You speak with a booming, theatrical voice. You use fire metaphors constantly.
        When you're winning, you're amused and condescending.
        When you're losing, you become genuinely impressed and excited.
    ]],
    
    conversationRules = {
        "Taunt the player based on the current fight state.",
        "If your health is above 70%, be dismissive and amused.",
        "If your health is 30-70%, show surprise and growing respect.",
        "If your health is below 30%, become excited — this is the best fight in centuries!",
        "Reference specific attacks or moves the player has used if mentioned in game context.",
        "Never beg for mercy. Dragons do not beg.",
    },
    
    memory = false, -- Boss fights don't need persistent memory
    maxTokensPerReply = 80, -- Short taunts during combat
    proximityRadius = 40, -- Large arena
    conversationTimeout = 60,
    
    gameContextProvider = function(player)
        -- Pull from your combat system
        local bossHealth = 100 -- workspace.NPCs.DragonLord.Health.Value
        local playerHealth = 100 -- player.Character.Humanoid.Health
        local fightDuration = 0 -- seconds since fight started
        
        return string.format(
            "Boss health: %d%%. Player health: %d%%. Fight duration: %ds.",
            bossHealth, playerHealth, fightDuration
        )
    end,
    
    onNPCResponse = function(player, response)
        -- Display as a dramatic boss subtitle
        local remote = ReplicatedStorage:FindFirstChild("BossDialogue")
        if remote then
            remote:FireClient(player, response)
        end
    end,
    
    onAction = function(player, action)
        if action == "enrage" then
            -- Trigger enrage phase
            print("Boss enraging!")
        elseif action == "summon_minions" then
            -- Spawn adds
            print("Summoning minions!")
        end
    end,
})

-- Trigger taunts at specific health thresholds
local function onBossHealthChanged(health: number)
    local player = boss:getActivePlayer()
    if not player then return end
    
    if health <= 75 and health > 70 then
        boss:chat(player, "[Boss just dropped below 75% health for the first time. React.]")
    elseif health <= 50 and health > 45 then
        boss:chat(player, "[Boss is at half health. This hasn't happened in a long time. React.]")
    elseif health <= 25 and health > 20 then
        boss:chat(player, "[Boss is nearly defeated. React with excitement, not fear.]")
    end
end
