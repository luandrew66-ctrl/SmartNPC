--[[
    SmartNPC Example: Quest Giver
    
    An RPG NPC that gives players a quest to find the Lost Amulet,
    remembers their progress, and gives contextual hints.
    
    Setup:
    1. Place this script in ServerScriptService
    2. Create an NPC model in workspace.NPCs.QuestGiver with a HumanoidRootPart
    3. Add your API key
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SmartNPC = require(ReplicatedStorage.SmartNPC)

-- Configure (do this once per server)
SmartNPC.configure({
    provider = "openai",
    apiKey = "YOUR_API_KEY_HERE", -- Use Roblox Secrets in production!
    model = "gpt-4o-mini",
    debug = true,
})

-- Create the Quest Giver NPC
local elderMira = SmartNPC.new(workspace.NPCs.QuestGiver, {
    name = "Elder Mira",
    
    personality = [[
        You are Elder Mira, the oldest and wisest resident of Thornwood Village. 
        You speak in a warm but slightly cryptic manner, often using metaphors about nature.
        You have lived for over 200 years and have seen kingdoms rise and fall.
        
        THE QUEST: You need a brave adventurer to find the Lost Amulet of Thornwood, 
        which was stolen by goblins and taken to the Shadowmere Caves east of the village.
        The amulet protects the village from dark magic. Without it, the barrier weakens daily.
        
        HINTS (reveal gradually, not all at once):
        - The caves have three levels. The amulet is on the deepest level.
        - Goblins fear fire. A torch will keep most of them at bay.
        - There is a secret passage behind the waterfall on level 2.
        - The goblin king guards the amulet. He can be reasoned with if you bring mushrooms.
    ]],
    
    conversationRules = {
        "Never reveal all hints at once. Give one hint per conversation.",
        "If the player asks about the village history, share a brief anecdote.",
        "If the player claims to have the amulet, ask them to describe it (it glows blue).",
        "Always end by encouraging the player.",
    },
    
    memory = true,
    memoryPersist = true,
    memoryLength = 20,
    maxTokensPerReply = 150,
    proximityRadius = 20,
    
    -- Provide game context to the NPC
    gameContextProvider = function(player)
        -- You would pull this from your game's data systems
        local hasAmulet = false -- player.leaderstats.HasAmulet.Value
        local level = 1 -- player.leaderstats.Level.Value
        
        local ctx = "Player level: " .. level
        if hasAmulet then
            ctx = ctx .. ". Player HAS the Lost Amulet!"
        end
        return ctx
    end,
    
    -- React to NPC responses
    onNPCResponse = function(player, response)
        -- Display as a chat bubble above the NPC
        local npcHead = workspace.NPCs.QuestGiver:FindFirstChild("Head")
        if npcHead then
            game:GetService("Chat"):Chat(npcHead, response, Enum.ChatColor.Green)
        end
        print("[Elder Mira to " .. player.Name .. "]:", response)
    end,
    
    -- Handle NPC actions
    onAction = function(player, action)
        if action == "give_quest" then
            -- Add quest to player's quest log
            print("Quest given to", player.Name)
        elseif action == "give_reward" then
            -- Award the player
            print("Reward given to", player.Name)
        end
    end,
    
    onConversationStart = function(player)
        print(player.Name, "started talking to Elder Mira")
    end,
    
    onConversationEnd = function(player)
        print(player.Name, "stopped talking to Elder Mira")
    end,
})

-- You can also manually send messages via a RemoteEvent
local chatRemote = Instance.new("RemoteEvent")
chatRemote.Name = "SmartNPC_Chat"
chatRemote.Parent = ReplicatedStorage

chatRemote.OnServerEvent:Connect(function(player, npcName, message)
    if npcName == "QuestGiver" then
        local response = elderMira:chat(player, message)
        chatRemote:FireClient(player, "QuestGiver", response)
    end
end)
