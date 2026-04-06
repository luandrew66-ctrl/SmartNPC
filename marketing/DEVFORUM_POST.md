# SmartNPC — Drop-in AI-Powered NPCs for Your Roblox Game

**Give any NPC a personality, memory, and real conversations with players — in under 10 lines of code.**

---

## What is SmartNPC?

SmartNPC is a free, open-source Luau framework that connects your Roblox NPCs to AI language models (OpenAI, Anthropic). Instead of scripting hundreds of dialogue trees, you describe who the NPC *is* — and SmartNPC handles the rest.

Your NPCs can:
- Hold natural, unique conversations with every player
- Remember past interactions (even across sessions)
- Make decisions using behavior trees
- Follow personality rules and stay in character
- Handle rate limiting and cost control automatically

## Quick Example

```lua
local SmartNPC = require(game.ReplicatedStorage.SmartNPC)

SmartNPC.configure({
    provider = "openai",
    apiKey = "YOUR_KEY",
    model = "gpt-4o-mini",
})

local npc = SmartNPC.new(workspace.NPCs.Blacksmith, {
    name = "Grimjaw",
    personality = "A gruff dwarven blacksmith who loves metallurgy and secretly has a soft spot for beginners.",
    memory = true,
})
-- Done. Players can now talk to Grimjaw.
```

That's the entire setup. No dialogue trees. No branching logic. Just a personality description.

## Features

**🌳 Behavior Trees** — NPCs don't just talk, they *decide*. Built-in behavior tree system for complex decision logic (patrol → detect player → greet → converse → return to patrol).

**🧠 Persistent Memory** — NPCs remember individual players across sessions using DataStores. Elder Mira remembers that you already found the sword — she won't ask again.

**🎭 Personality Templates** — Pre-built templates for common archetypes: Quest Giver, Shopkeeper, Guard, Narrator, Companion. Use them as-is or customize.

**⚡ Cost Control** — Built-in rate limiting (per-NPC and global), token budgets, and approximate cost tracking. A typical conversation costs ~$0.001 with gpt-4o-mini.

**🔌 Multi-Provider** — Switch between OpenAI and Anthropic with one config change.

**🛡️ Graceful Degradation** — If the API is unavailable, NPCs fall back to configurable scripted responses instead of breaking.

## Built-in Templates

```lua
-- One-liner quest giver
local npc = SmartNPC.new(model, SmartNPC.Templates.QuestGiver({
    questName = "The Lost Amulet",
    reward = "500 gold",
}))

-- Shopkeeper that haggles
local shop = SmartNPC.new(model, SmartNPC.Templates.Shopkeeper({
    shopName = "Ye Olde Potions",
    inventory = {"Health Potion", "Mana Elixir", "Speed Brew"},
}))
```

## Architecture

SmartNPC is modular — use the pieces you need:

- **BehaviorTree** — Decision-making framework (usable standalone)
- **StateMachine** — NPC state management (Idle → Talking → Acting → Cooldown)
- **ProximityManager** — Spatial player detection without per-frame distance checks
- **LLMBridge** — Clean HTTPService wrapper with retries and error handling
- **ConversationLog** — Per-player history with automatic pruning
- **MemoryStore** — DataStore-backed persistent memory
- **RateLimiter** — Token bucket algorithm for cost control
- **TokenCounter** — Approximate token estimation for budget tracking

## Examples Included

The repo includes three complete example scripts:

1. **Quest Giver** — RPG NPC that tracks quest progress, gives contextual hints, and remembers player history
2. **Shop NPC** — Merchant that negotiates prices and recommends items based on conversation
3. **Adaptive Enemy** — Boss that taunts players differently based on fight progress and health percentage

## Installation

**Creator Marketplace:** Search "SmartNPC" and install.

**Manual:** Download from [GitHub](https://github.com/YOUR_USERNAME/SmartNPC), import the `.rbxm` into `ReplicatedStorage`.

**Rojo:** Clone the repo and `rojo serve default.project.json`.

## Cost Breakdown

Using `gpt-4o-mini` (the recommended default):
- 10-message conversation ≈ $0.001
- 100 players × 5 conversations/session ≈ $0.50/day
- Built-in rate limits prevent runaway costs

## Open Source

SmartNPC is MIT licensed. Use it in any game, commercial or otherwise. Contributions welcome — especially new templates!

**GitHub:** [github.com/YOUR_USERNAME/SmartNPC](https://github.com/YOUR_USERNAME/SmartNPC)
**Discord:** [discord.gg/smartnpc](https://discord.gg/smartnpc)

---

I built this because every Roblox game I played had NPCs with the same 5 canned responses. I wanted NPCs that actually *talk*. If you've felt the same way, give SmartNPC a try and let me know what you think.

Feedback, bug reports, and feature requests are all welcome. Drop a reply here or open a GitHub issue.
