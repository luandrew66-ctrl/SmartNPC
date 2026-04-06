# SmartNPC Templates

Templates are pre-built personality configurations for common NPC types. They return a config table you can pass directly to `SmartNPC.new()`.

## Built-in Templates

### QuestGiver

A wise, mysterious NPC who gives quests and tracks progress.

```lua
local npc = SmartNPC.new(model, SmartNPC.Templates.QuestGiver({
    questName = "The Lost Amulet",
    questDescription = "Find the amulet in the Shadowmere Caves",
    requiredItem = "Blue Amulet",
    reward = "500 gold and a legendary sword",
}))
```

**Options:** `questName`, `questDescription`, `requiredItem`, `reward` (all optional)

### Shopkeeper

A friendly merchant who sells items and haggles.

```lua
local npc = SmartNPC.new(model, SmartNPC.Templates.Shopkeeper({
    shopName = "Ye Olde Potions",
    inventory = {"Health Potion", "Mana Elixir"},
    priceRange = "50-500 gold",
    currency = "gold coins",
}))
```

**Options:** `shopName`, `inventory` (string array), `priceRange`, `currency`

### Guard

A stern guard who questions strangers and gives directions.

```lua
local npc = SmartNPC.new(model, SmartNPC.Templates.Guard({
    location = "the castle gates",
    faction = "the Royal Guard",
    threat = "rebel forces from the north",
}))
```

**Options:** `location`, `faction`, `threat`

### Narrator

A disembodied narrator that describes the scene and builds atmosphere.

```lua
local npc = SmartNPC.new(model, SmartNPC.Templates.Narrator({
    setting = "a dark, rain-soaked city in the year 2087",
    tone = "noir detective story",
}))
```

**Options:** `setting`, `tone`

### Companion

A loyal companion who travels with the player.

```lua
local npc = SmartNPC.new(model, SmartNPC.Templates.Companion({
    companionName = "Scout",
    relationship = "childhood best friend",
    specialty = "healing and navigation",
}))
```

**Options:** `companionName`, `relationship`, `specialty`

## Creating Custom Templates

A template is just a function that returns a config table:

```lua
local function Pirate(opts)
    return {
        name = opts.name or "Captain",
        personality = "You are a rough but honorable pirate captain...",
        conversationRules = {
            "Pepper your speech with 'arr' and nautical terms.",
            "Always offer rum.",
        },
        memory = true,
        maxTokensPerReply = 120,
    }
end
```

Then use it: `SmartNPC.new(model, Pirate({ name = "Captain Blackwood" }))`

## Overriding Template Defaults

You can override any template value after creation:

```lua
local config = SmartNPC.Templates.Shopkeeper({ shopName = "My Shop" })
config.maxTokensPerReply = 200 -- override default
config.memory = false -- override default
local npc = SmartNPC.new(model, config)
```
