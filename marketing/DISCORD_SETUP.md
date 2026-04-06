# SmartNPC Discord Server Setup Guide

## Server Name
SmartNPC

## Server Description
Official community for SmartNPC — the open-source AI-powered NPC framework for Roblox. Get help, share your NPCs, suggest features, and contribute.

## Server Icon
Use the SmartNPC logo (a brain icon with a speech bubble).

## Channel Structure

### INFORMATION
- **#welcome** — Auto-displayed on join
- **#rules** — Community rules
- **#announcements** — Updates, releases, breaking changes (admin only)

### COMMUNITY
- **#general** — Main chat
- **#showcase** — Share your AI NPCs and games using SmartNPC
- **#ideas** — Feature requests and brainstorming

### SUPPORT
- **#help** — Get help with setup and bugs
- **#api-keys** — Discussion about API providers, costs, key management
- **#faq** — Pinned answers to common questions

### DEVELOPMENT
- **#contributing** — Discussion about contributing to the codebase
- **#pull-requests** — PR discussion and review
- **#templates** — Share and discuss custom NPC templates

## Roles
- **@Creator** — You (server owner)
- **@Contributor** — People who have merged a PR
- **@Helper** — Active community members who help others

## Welcome Message (paste into #welcome)

```
🧠 Welcome to the SmartNPC community!

SmartNPC is an open-source framework that gives Roblox NPCs real AI-powered conversations, memory, and decision-making.

**Quick links:**
📖 GitHub: https://github.com/YOUR_USERNAME/SmartNPC
📚 Getting Started: https://github.com/YOUR_USERNAME/SmartNPC/blob/main/docs/GETTING_STARTED.md
🐛 Report a bug: https://github.com/YOUR_USERNAME/SmartNPC/issues

**Getting help:**
→ Post in #help with your issue + code snippet
→ Check #faq first — your question might already be answered

**Want to contribute?**
→ Read CONTRIBUTING.md on GitHub
→ Chat in #contributing
```

## Rules (paste into #rules)

```
1. Be respectful. No harassment, discrimination, or personal attacks.
2. Keep discussions relevant to SmartNPC, Roblox development, or AI.
3. Don't share API keys. Ever. Not even expired ones.
4. Use #help for support questions, not #general.
5. No spam, self-promotion, or advertising unrelated projects.
6. Share code and examples freely — that's what we're here for.
```

## FAQ Pins (paste into #faq)

```
**Q: Is SmartNPC free?**
A: Yes. MIT license. Use it in any game.

**Q: How much does it cost to run?**
A: Using gpt-4o-mini, a 10-message conversation costs ~$0.001. For most games, you're looking at $0.50-5/day.

**Q: Do I need my own API key?**
A: Yes. Get one from OpenAI (platform.openai.com) or Anthropic (console.anthropic.com).

**Q: Will players see my API key?**
A: No. SmartNPC runs on the server (ServerScriptService). Players never see server-side code. But don't put keys in LocalScripts or ReplicatedStorage.

**Q: Can NPCs do things besides talk?**
A: Yes. NPCs can trigger game actions via [ACTION: action_name] tags. Your server script handles the actions.

**Q: Does it work in published games?**
A: Yes, but make sure HTTPService is enabled and your API key is secured (use Roblox Secrets or a proxy server).
```
