# SmartNPC

AI-powered NPCs for Roblox. They talk, they remember you, they don't say the same 5 lines forever.

SmartNPC hooks your NPCs up to AI (OpenAI or Anthropic) so they can hold real conversations with players. You describe who the NPC is, and they just... talk. No dialogue trees, no branching scripts.

## what it does

- NPCs have actual conversations with players (not pre-written lines)
- they remember past interactions, even across sessions
- behavior trees so they can make decisions, not just stand there
- built-in rate limiting so you don't accidentally burn $500 on API calls
- pre-built templates for common NPCs (quest giver, shopkeeper, guard, etc.)
- works with OpenAI and Anthropic

## quick start

```lua
local SmartNPC = require(game.ReplicatedStorage.SmartNPC)

SmartNPC.configure({
    provider = "openai",
    apiKey = "YOUR_API_KEY",
    model = "gpt-4o-mini",
})

local npc = SmartNPC.new(workspace.NPCs.QuestGiver, {
    name = "Elder Mira",
    personality = "A wise village elder with a sharp tongue. Helpful if you're polite, roasts you if you're not.",
    memory = true,
})

-- thats it. players walk up and talk to her.
```

## install

**Creator Marketplace:** search "SmartNPC" and add it to your game.

**Manual:** grab the latest release from [releases](../../releases), drop the `.rbxm` into ReplicatedStorage.

**From source (with Rojo):**
```bash
git clone https://github.com/luandrew66-ctrl/SmartNPC.git
rojo serve default.project.json
```

## how it works

the framework has a few main pieces:

**SmartNPCController** — the main module. you interact with this.

**BehaviorTree** — lets NPCs make decisions. patrol, detect player, greet, talk, go back to patrolling. customizable.

**StateMachine** — manages what the NPC is doing (idle, talking, acting, cooldown).

**LLMBridge** — handles the HTTP requests to OpenAI/Anthropic. retries, error handling, all that.

**ConversationLog** — stores chat history per player so the NPC remembers what you talked about.

**MemoryStore** — saves memories to Roblox DataStores so NPCs remember players even after they leave and come back.

**RateLimiter** — prevents your game from sending too many API requests. configurable per-NPC and globally.

## templates

don't want to write a personality from scratch? use a template:

```lua
-- quest giver that tracks progress
local npc = SmartNPC.new(model, SmartNPC.Templates.QuestGiver({
    questName = "The Lost Amulet",
    reward = "500 gold",
}))

-- shopkeeper that haggles
local shop = SmartNPC.new(model, SmartNPC.Templates.Shopkeeper({
    shopName = "Ye Olde Potions",
    inventory = {"Health Potion", "Mana Elixir", "Speed Brew"},
}))

-- guard that questions strangers
local guard = SmartNPC.new(model, SmartNPC.Templates.Guard({
    location = "the castle gates",
    faction = "the Royal Guard",
}))
```

there's also Narrator and Companion templates. check [the docs](docs/TEMPLATES.md) for all of them.

## config options

`SmartNPC.configure()` — call once per server:

- `provider` — "openai" or "anthropic"
- `apiKey` — your API key
- `model` — which model to use (default: gpt-4o-mini)
- `rateLimits` — requests per minute, token budgets, etc
- `debug` — true/false for logging

`SmartNPC.new(model, config)` — create an NPC:

- `name` — what the NPC is called
- `personality` — describe who they are (this is the system prompt basically)
- `memory` — true/false, remember past conversations
- `memoryLength` — how many exchanges to remember (default 10)
- `memoryPersist` — save to DataStore across sessions
- `maxTokensPerReply` — keep responses short (default 200)
- `conversationRules` — list of rules the NPC has to follow
- `proximityRadius` — how close a player needs to be (default 15 studs)

## cost

gpt-4o-mini is cheap. like $0.001 per conversation. if you have 100 players each having 5 conversations, thats maybe $0.50/day. the rate limiter is there so it never runs away on you.

## examples

check the [examples folder](examples/) for full working scripts:

- **quest giver** — gives quests, tracks progress, remembers what hints they already gave you
- **shop npc** — negotiates prices, recommends items
- **adaptive enemy** — boss that taunts you differently based on how the fight is going

## contributing

PRs welcome. especially new templates — if you make a cool NPC archetype, submit it. see [CONTRIBUTING.md](CONTRIBUTING.md).

## license

MIT. do whatever you want with it.
