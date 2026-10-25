# bb-plugin-quota-bar

Two sidebar-footer icons showing the five-hour usage window for Claude Code and Codex as a ring with the used percentage. Clicking one opens its plan, window and reset time. The numbers come from the builtin `bb--provider-usage` plugin, which must stay enabled; the icons refresh every minute while the window is visible.

Opening either panel also shows the OpenRouter dollar credits remaining, read from the same credential pi uses (the `openrouter` entry in `~/.pi/agent/auth.json`, or `OPENROUTER_API_KEY`). OpenRouter has no sidebar icon.

```
bb plugin install .
```
