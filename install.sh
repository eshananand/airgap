#!/bin/bash
# Native Superpowers Installer
# Copies command and agent files to ~/.claude/ for Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"
AGENTS_SRC="$SCRIPT_DIR/agents"
COMMANDS_DST="$HOME/.claude/commands"
AGENTS_DST="$HOME/.claude/agents"

echo "Installing native superpowers..."

# Create target directories
mkdir -p "$COMMANDS_DST"
mkdir -p "$AGENTS_DST"

# Copy commands
count=0
for f in "$COMMANDS_SRC"/*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$COMMANDS_DST/"
  count=$((count + 1))
done
echo "  Installed $count commands to $COMMANDS_DST/"

# Copy agents
agent_count=0
for f in "$AGENTS_SRC"/*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$AGENTS_DST/"
  agent_count=$((agent_count + 1))
done
echo "  Installed $agent_count agents to $AGENTS_DST/"

echo ""
echo "Done! $count commands and $agent_count agents installed."
echo "Changes are live on next Claude Code session."
echo ""
echo "Available commands:"
for f in "$COMMANDS_SRC"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  echo "  /$name"
done
