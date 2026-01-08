#!/bin/bash

# Setup worktree for TapResolver-verbose-debugger
cd /Users/cgelles/Documents/GitHub/TapResolver

# Create worktree with the specified branch
git worktree add ../TapResolver-verbose-debugger building-mulitple-relocalization-strategy-options

# Verify it was created
echo ""
echo "✅ Worktree created!"
echo ""
git worktree list
echo ""
echo "📁 New worktree location: /Users/cgelles/Documents/GitHub/TapResolver-verbose-debugger"
echo "🌿 Branch: building-mulitple-relocalization-strategy-options"

