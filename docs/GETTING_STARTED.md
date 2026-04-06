# Getting Started with SmartNPC

This guide walks you through adding your first AI-powered NPC to a Roblox game in under 5 minutes.

## Prerequisites

- Roblox Studio
- An API key from [OpenAI](https://platform.openai.com/) or [Anthropic](https://console.anthropic.com/)
- HTTPService enabled in your game (Game Settings → Security → Allow HTTP Requests)

## Step 1: Install SmartNPC

**Option A: Creator Marketplace**
Search "SmartNPC" in the Creator Marketplace toolbox and insert it into `ReplicatedStorage`.

**Option B: Manual**
Download the latest `.rbxm` from the GitHub releases page and drag it into `ReplicatedStorage`.

## Step 2: Create an NPC Model

1. In Workspace, create a new folder called `NPCs`
2. Insert an R6 or R15 character model (or use any Model with a `HumanoidRootPart`)
3. Name it something descriptive, like `Blacksmith`
4. Anchor the HumanoidRootPart so the NPC doesn't fall

## Step 3: Write the Server Script

Create a new **Script** (not LocalScript) in `ServerScriptService`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SmartNPC = require(ReplicatedStorage.SmartNPC)

-- Configure once per server
SmartNPC.configure({
    provider = "openai",
    apiKey = "sk-your-key-here",
    model = "gpt-4o-mini",
})

-- Create your NPC
local blacksmith = SmartNPC.new(workspace.NPCs.Blacksmith, {
    name = "Grimjaw",
    personality = "A gruff dwarven blacksmith who takes pride in his work. "
        .. "He's blunt, loves talking about metallurgy, and secretly has a soft spot for beginners.",
    memory = true,
    maxTokensPerReply = 120,
})
```

## Step 4: Add a Chat UI (Optional)

SmartNPC handles the AI logic on the server. To let players type messages, you need a simple chat UI. Here's a minimal example:

**LocalScript** in `StarterPlayerScripts`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for the RemoteEvent (create it on the server or manually)
local chatRemote = ReplicatedStorage:WaitForChild("SmartNPC_Chat")

-- Simple proximity-based chat prompt
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.E then
        -- Prompt the player for input (you'd use a TextBox GUI in practice)
        local message = "Hello there!" -- replace with actual GUI input
        chatRemote:FireServer("Blacksmith", message)
    end
end)

chatRemote.OnClientEvent:Connect(function(npcName, response)
    print("[" .. npcName .. "]:", response)
    -- Display in your chat GUI
end)
```

## Step 5: Test

1. Hit Play in Roblox Studio
2. Walk your character near the NPC
3. The NPC will automatically greet you
4. Check the Output window for conversation logs

## API Key Security

**Never hardcode API keys in production games.** Use one of these approaches:

1. **Roblox Secrets** (recommended): Store the key as a Secret in Game Settings
2. **Environment variables**: Use a proxy server that holds the key
3. **Backend proxy**: Route requests through your own server that injects the key

## Cost Management

`gpt-4o-mini` costs roughly $0.15 per million input tokens. A typical NPC conversation (10 exchanges) costs about $0.001. For a game with 100 concurrent players each having 5 conversations per session, that's approximately $0.50/day.

Use the built-in rate limiter to cap costs:

```lua
SmartNPC.configure({
    rateLimits = {
        requestsPerMinute = 10,
        globalRequestsPerMinute = 50,
        tokensPerMinute = 5000,
    },
})
```

## Next Steps

- Check out the [Templates documentation](TEMPLATES.md) for pre-built NPC types
- Browse the [examples](../examples/) for complete working games
- Read the full API reference in the [README](../README.md)
