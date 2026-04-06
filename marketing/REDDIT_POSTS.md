# Reddit Post Drafts

---

## r/robloxgamedev Post

**Title:** I built an open-source framework that gives Roblox NPCs real AI conversations, memory, and personalities — SmartNPC

**Body:**

Every Roblox game I played had NPCs with the same 5 canned responses. So I built SmartNPC — a free, open-source Luau framework that connects NPCs to AI models (OpenAI/Anthropic) and gives them actual personalities, persistent memory, and real conversations.

**What it does:**
- NPCs hold unique conversations with every player
- They remember past interactions (even across sessions via DataStores)
- Behavior trees for decision-making (not just talking)
- Pre-built templates: Quest Giver, Shopkeeper, Guard, Companion, Narrator
- Built-in rate limiting and cost control (~$0.001 per conversation with gpt-4o-mini)

**Setup is 10 lines of code:**

```lua
local SmartNPC = require(game.ReplicatedStorage.SmartNPC)
SmartNPC.configure({ provider = "openai", apiKey = "YOUR_KEY" })

local npc = SmartNPC.new(workspace.NPCs.Blacksmith, {
    name = "Grimjaw",
    personality = "A gruff dwarven blacksmith who loves metallurgy.",
    memory = true,
})
```

GitHub: [link]
DevForum post: [link]

MIT licensed. Contributions welcome — especially new templates.

Would love feedback from anyone who tries it out.

---

## r/gamedev Post

**Title:** Open-sourced a framework for AI-powered NPCs in Roblox — behavior trees, persistent memory, multi-provider LLM support

**Body:**

I've been working on SmartNPC, an open-source Luau framework that bridges Roblox's sandboxed environment with LLM APIs to create NPCs with real conversational AI.

**Technical highlights:**
- Behavior tree implementation for NPC decision logic (selector, sequence, condition, action, inverter, repeater nodes)
- Finite state machine for NPC states (Idle → Approaching → Talking → Acting → Cooldown)
- HTTPService bridge with retry logic, error recovery, and multi-provider support (OpenAI, Anthropic)
- Persistent conversation memory via Roblox DataStores with automatic pruning
- Token bucket rate limiting (per-NPC and global) with approximate token counting for cost tracking
- Prompt engineering layer that handles system prompts, conversation history truncation, context injection, and action parsing

The main challenge was working within Roblox's constraints — sandboxed Luau environment, HTTPService rate limits, DataStore throttling — while keeping the API dead simple for developers who just want "NPC that talks."

Cost breakdown: gpt-4o-mini runs about $0.001 per 10-message conversation. Built-in rate limiters prevent runaway costs.

GitHub: [link]

MIT licensed. Feedback on the architecture appreciated.
