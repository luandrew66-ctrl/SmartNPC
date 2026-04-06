--[[
    SmartNPC Example: Shop NPC
    
    A merchant that negotiates prices, recommends items,
    and remembers what each player has purchased before.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SmartNPC = require(ReplicatedStorage.SmartNPC)

-- Assumes SmartNPC.configure() was already called

local merchant = SmartNPC.new(workspace.NPCs.Merchant, 
    SmartNPC.Templates.Shopkeeper({
        shopName = "Ye Olde Potions & Provisions",
        inventory = {
            "Health Potion (50 gold)",
            "Mana Elixir (75 gold)",
            "Speed Brew (100 gold)",
            "Phoenix Feather (500 gold)",
            "Mystery Box (200 gold)",
        },
        priceRange = "50-500 gold",
        currency = "gold coins",
    })
)

-- Add extra customization on top of the template
merchant:addRule("If a player has bought 3+ items, offer them a 10% loyalty discount.")
merchant:addRule("The Mystery Box contains a random item. Build excitement about it.")

-- Handle purchase actions
merchant._onAction = function(player, action)
    if action:match("^sell_") then
        local item = action:gsub("sell_", "")
        print(player.Name, "wants to buy:", item)
        -- Hook into your game's economy system here
    end
end

merchant._onNPCResponse = function(player, response)
    local head = workspace.NPCs.Merchant:FindFirstChild("Head")
    if head then
        game:GetService("Chat"):Chat(head, response, Enum.ChatColor.Blue)
    end
end
