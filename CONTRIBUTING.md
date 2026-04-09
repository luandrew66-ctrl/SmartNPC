this project is early — there's a lot to improve and i'd rather get feedback than build in a vacuum.

# Contributing to SmartNPC

Thanks for your interest in contributing! Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/SmartNPC.git`
3. Install [Rojo](https://rojo.space/) for syncing to Roblox Studio
4. Create a feature branch: `git checkout -b feature/my-feature`

## Development Setup

1. Open Roblox Studio and create a new baseplate
2. Run `rojo serve default.project.json` in the project root
3. Connect Rojo in Studio via the Rojo plugin
4. Make your changes in the `src/` directory — they'll sync live

## What We're Looking For

### New Templates
The easiest way to contribute! Create a new personality template in `src/templates/`:
- Follow the existing pattern in `Templates.luau`
- Include sensible defaults for all config options
- Add an example script in `examples/`

### Bug Fixes
- Open an issue first describing the bug
- Include reproduction steps
- Reference the issue in your PR

### Features
- Open an issue to discuss the feature before building
- Keep PRs focused — one feature per PR
- Add tests if applicable
- Update documentation

### Documentation
- Fix typos, improve examples, add tutorials
- Documentation PRs are always welcome

## Code Style

- Use Luau type annotations where possible
- Follow existing naming conventions (PascalCase for modules, camelCase for methods)
- Add comments for non-obvious logic
- Keep functions under 50 lines when possible

## Pull Request Process

1. Update the README if you've changed the API
2. Add your changes to the changelog
3. Ensure your code works in Roblox Studio
4. Submit a PR with a clear description of what changed and why

## Code of Conduct

Be respectful. We're all here to build cool things for the Roblox community.

## Questions?

Open an issue or join our [Discord](https://discord.gg/smartnpc).
