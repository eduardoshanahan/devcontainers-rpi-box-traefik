# tmux – 1‑Page Quick Reference (Infra & Raspberry Pi)

This guide covers **everything the team needs** to use tmux effectively on servers, Raspberry Pi boxes, and workstations.

> **Scope**: window (tab) management, SSH safety, zero plugins

---

## What is tmux?

`tmux` is a **terminal multiplexer**:

- One SSH session → many named tabs (called *windows*)
- Sessions survive network drops
- Same behavior everywhere (Pi, VM, laptop)

---

## Starting tmux

```bash
tmux
```

Attach to an existing session:

```bash
tmux attach
```

List sessions:

```bash
tmux ls
```

---

## Key Concept: the Prefix Key

All tmux commands start with the **prefix key**:

> **Prefix:** `Ctrl + a`

Press **Ctrl**, hold it, press **a**, release — then press the command key.

---

## Core Commands (90% of usage)

| Action | Keys |
| ------ | ---- |
| New tab (window) | `Ctrl+a` → `c` |
| Rename tab | `Ctrl+a` → `r` |
| Switch to tab | `Ctrl+a` → `1–9` |
| List all tabs | `Ctrl+a` → `w` |
| Detach (safe logout) | `Ctrl+a` → `d` |

---

## SSH Safety (VERY IMPORTANT)

### Correct way to leave a tmux session

```text
Ctrl+a → d
```

This **keeps everything running** on the server.

### Reconnect later

```bash
tmux attach
```

---

## Mouse Support

Mouse is enabled by default:

- Click to switch tabs
- Scroll history with mouse wheel
- Resize panes (if used)

Works locally **and** over SSH.

---

## Scrolling Output (no mouse)

- Enter scroll mode:

```text
Ctrl+a → [
```

- Scroll with arrow keys or PageUp/PageDown
- Exit scroll mode:

```text
q
```

---

## Session Naming (optional but recommended)

Create a named session:

```bash
tmux new -s infra
```

Attach to it later:

```bash
tmux attach -t infra
```

---

## When to Use tmux

Use tmux when:

- Running long commands
- Managing multiple services
- Working over SSH
- Switching between tasks often

---

## When NOT to Use tmux

Probably unnecessary for:

- One-off local commands
- Short-lived interactive shells

---

## Golden Rules

- One tmux session per server is usually enough
- Rename windows clearly (`logs`, `docker`, `ansible`)
- Detach, don’t logout
- Avoid nesting tmux inside tmux unless you know why

---

## Common Mistakes (and How to Avoid Them)

### 1. Starting tmux *inside* tmux (nested tmux)

**Symptom**:

- Keybindings stop working
- Prefix key feels inconsistent
- Confusing status bars

**Cause**:
You ran `tmux` while already inside a tmux session.

**How to avoid**:

- If you already see a tmux status bar, you are *inside tmux*
- Use **new windows** instead of starting a new tmux

```text
Ctrl+a → c
```

**If it already happened**:

- Detach twice:

```text
Ctrl+a → d
Ctrl+a → d
```

---

### 2. Killing the SSH session instead of detaching

**Symptom**:

- All running commands stop
- Long-running tasks are lost

**Cause**:
Using `exit`, closing the terminal, or killing SSH **without detaching**.

**Correct way to leave**:

```text
Ctrl+a → d
```

This keeps everything running safely on the server.

---

### 3. Closing terminals instead of reattaching

**Symptom**:

- "I lost my work"

**Fix**:

```bash
tmux ls
tmux attach
```

tmux sessions persist until explicitly killed.

---

### 4. Forgetting to rename windows

**Symptom**:

- Many tabs named `bash`
- Hard to know what is running where

**Best practice**:
Rename windows immediately:

```text
Ctrl+a → r
```

Examples:

- `logs`
- `docker`
- `ansible`
- `traefik`

---

### 5. Killing tmux sessions accidentally

**Symptom**:

- Everything disappears at once

**Safer approach**:

- Close individual windows instead of the whole session
- Confirm before killing sessions (already enforced in infra config)

---

### 6. Using tmux when it is not needed

tmux is great, but not mandatory for:

- One-off local commands
- Short interactive shells

Use it where it adds value: **long-running, multi-task, or SSH work**.

---

## Troubleshooting

### "I lost my session"

```bash
tmux ls
tmux attach
```

### "My terminal froze"

Try:

```text
Ctrl+a → d
```

Then reattach.

---

## Session Management (Rename & Conventions)

### Rename the current session (inside tmux)

```text
Ctrl+a → $
```

You will be prompted for a new session name.

This is safe and does **not** interrupt running commands.

---

### Rename a session from the shell (outside tmux)

```bash
tmux ls
tmux rename-session -t old_name new_name
```

Example:

```bash
tmux rename-session -t 0 infra
```

---

### Recommended session naming conventions

Use **purpose-based**, not personal names:

Good examples:

- `infra`
- `maintenance`
- `upgrade`
- `debug`
- `prod-check`

Avoid:

- Leaving default numeric names
- Using usernames
- Mixing unrelated work in one session

---

## Cheat Memory

> **Create – Rename – Switch – Detach**

> **Rename window:** `Ctrl+a r`  
> **Rename session:** `Ctrl+a $`

That’s all you need to remember.

---

*Standardized tmux configuration is deployed via Ansible to `/etc/tmux.conf`.**
