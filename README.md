# 🧠 SmartNPC

**Drop-in AI-powered NPCs for Roblox.** Give any NPC a personality, memory, and the ability to hold real conversations with players — in under 10 lines of code.

SmartNPC connects Roblox's Luau environment to large language models (OpenAI, Anthropic) through a clean behavior tree architecture, so your NPCs can:

- 💬 Hold natural conversations with players
- 🧠 Remember past interactions across sessions
- 🎭 Follow personality templates you define in simple Lua tables
- 🌳 Make decisions using behavior trees and finite state machines
- ⚡ Handle rate limiting, token budgets, and error recovery automatically

## Quick Start

```lua
local SmartNPC = require(game.ReplicatedStorage.SmartNPC)

-- Configure your API key (store in a Secret or environment variable!)
SmartNPC.configure({
    provider = "openai",          -- or "anthropic"
    apiKey = "YOUR_API_KEY",      -- use Roblox Secrets in production
    model = "gpt-4o-mini",        -- cost-effective default
})

-- Create an AI-powered NPC
local questGiver = SmartNPC.new(workspace.NPCs.QuestGiver, {
    name = "Elder Mira",
    personality = "A wise village elder who speaks in short, cryptic sentences. "
                .. "She knows the location of the Lost Temple but only reveals it "
                .. "to players who have proven their worth.",
    memory = true,                -- remember past conversations
    maxTokensPerReply = 150,      -- keep responses game-appropriate
})

-- That's it. Players can now walk up and chat with Elder Mira.
```

## Installation

### Method 1: Roblox Creator Marketplace
Search **"SmartNPC"** in the Creator Marketplace and install directly into your experience.

### Method 2: Manual
1. Download the latest release from [Releases](../../releases)
2. Import the `SmartNPC.rbxm` file into `ReplicatedStorage`
3. Place the `SmartNPC_Server` script into `ServerScriptService`

### Method 3: From Source
1. Clone this repo
2. Use [Rojo](https://rojo.space/) to sync into Roblox Studio:
   ```bash
   rojo serve default.project.json
   ```

## Architecture

```
SmartNPC/
├── SmartNPCController    -- Main API / entry point
├── Core/
│   ├── BehaviorTree      -- Decision-making framework
│   ├── StateMachine      -- NPC state management (Idle, Talking, Acting)
│   └── ProximityManager  -- Detects nearby players, manages conversations
├── AI/
│   ├── LLMBridge         -- HTTPService wrapper for OpenAI/Anthropic APIs
│   ├── PromptBuilder     -- Constructs system + context prompts
│   └── ResponseParser    -- Extracts actions/dialogue from LLM responses
├── Memory/
│   ├── ConversationLog   -- Per-player conversation history
│   └── MemoryStore       -- DataStore-backed persistent memory
├── Templates/
│   ├── QuestGiver        -- Pre-built personality template
│   ├── Shopkeeper        -- Pre-built personality template
│   └── Guard             -- Pre-built personality template
└── Utils/
    ├── RateLimiter       -- Token bucket rate limiting
    ├── TokenCounter      -- Approximate token counting for budgets
    └── Logger            -- Debug logging with levels
```

## Features

### 🌳 Behavior Trees
NPCs don't just talk — they *decide*. The built-in behavior tree system lets you define complex decision logic:

```lua
local tree = BehaviorTree.new({
    type = "selector",
    children = {
        { type = "sequence", children = {
            { type = "condition", check = "isPlayerNearby" },
            { type = "condition", check = "hasNotGreeted" },
            { type = "action", run = "greetPlayer" },
        }},
        { type = "sequence", children = {
            { type = "condition", check = "isInConversation" },
            { type = "action", run = "continueConversation" },
        }},
        { type = "action", run = "patrol" },
    },
})
```

### 🧠 Persistent Memory
NPCs remember individual players across sessions using Roblox DataStores:

```lua
-- Elder Mira remembers that Player1 already found the sword
-- Next time Player1 visits, she picks up where they left off
local npc = SmartNPC.new(model, {
    memory = true,
    memoryLength = 20,    -- remember last 20 exchanges per player
    memoryPersist = true, -- save to DataStore across sessions
})
```

### 🎭 Personality Templates
Use built-in templates or create your own:

```lua
-- Built-in template
local shopkeeper = SmartNPC.new(model, SmartNPC.Templates.Shopkeeper({
    shopName = "Ye Olde Potions",
    inventory = {"Health Potion", "Mana Elixir", "Speed Brew"},
    priceRange = "10-500 gold",
}))

-- Custom template
local custom = SmartNPC.new(model, {
    personality = "A grumpy dwarf blacksmith...",
    conversationRules = {
        "Never reveal prices until asked twice",
        "Insult the player's weapon at least once",
        "Offer a discount if the player compliments your beard",
    },
})
```

### ⚡ Rate Limiting & Cost Control
Built-in protections prevent runaway API costs:

```lua
SmartNPC.configure({
    rateLimits = {
        requestsPerMinute = 20,       -- per-NPC limit
        globalRequestsPerMinute = 60, -- server-wide limit
        tokensPerMinute = 10000,      -- token budget
    },
    fallbackResponse = "Hmm, let me think about that...",
    maxConversationLength = 30,       -- auto-end long conversations
})
```

### 🔌 Multi-Provider Support
Switch between AI providers with one line:

```lua
-- OpenAI
SmartNPC.configure({ provider = "openai", model = "gpt-4o-mini" })

-- Anthropic
SmartNPC.configure({ provider = "anthropic", model = "claude-sonnet-4-20250514" })
```

## API Reference

### `SmartNPC.configure(options)`
Set global configuration. Call once in a server script.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | string | `"openai"` | AI provider: `"openai"` or `"anthropic"` |
| `apiKey` | string | required | API key for the provider |
| `model` | string | `"gpt-4o-mini"` | Model identifier |
| `rateLimits` | table | see above | Rate limiting configuration |
| `debug` | boolean | `false` | Enable debug logging |

### `SmartNPC.new(npcModel, config)`
Create an AI-powered NPC.

| Config | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | Model name | Display name for the NPC |
| `personality` | string | required | Personality description / system prompt |
| `memory` | boolean | `false` | Enable conversation memory |
| `memoryLength` | number | `10` | Max exchanges to remember |
| `memoryPersist` | boolean | `false` | Persist memory to DataStore |
| `maxTokensPerReply` | number | `200` | Max tokens in NPC responses |
| `conversationRules` | table | `{}` | List of behavioral rules |
| `conversationTimeout` | number | `30` | Seconds of silence before ending conversation |
| `proximityRadius` | number | `15` | Studs radius for player detection |

### `SmartNPC.Templates`
Pre-built personality templates. See [Templates documentation](docs/TEMPLATES.md).

## Examples

- **[Quest Giver](examples/quest-giver/)** — RPG NPC that tracks quest progress and gives contextual hints
- **[Shop NPC](examples/shop-npc/)** — Merchant that negotiates prices and recommends items
- **[Adaptive Enemy](examples/adaptive-enemy/)** — Boss that taunts players and adapts dialogue to the fight

## Performance

SmartNPC is designed for production Roblox games:

- **Queued requests** — Never overwhelms HTTPService limits
- **Approximate token counting** — Tracks costs before sending requests
- **Graceful degradation** — Falls back to scripted responses if API is unavailable
- **Minimal memory footprint** — Conversation history is pruned automatically

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. All contributions welcome — bug fixes, new templates, documentation, and features.

## License

MIT License. See [LICENSE](LICENSE).

## Links

- [📖 Full Documentation](docs/)
- [🐛 Report a Bug](../../issues)
- [💡 Request a Feature](../../issues)
- [💬 Discord Community](https://discord.gg/smartnpc)
