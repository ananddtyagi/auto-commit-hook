#!/bin/bash

# Auto-commit hook for Claude Code
# This script automatically commits changes when Claude Code modifies files

# Read input from stdin
INPUT=$(cat)

# Parse the JSON input to extract information
HOOK_EVENT=$(echo "$INPUT" | grep -o '"hook_event_name":"[^"]*"' | sed 's/"hook_event_name":"\([^"]*\)"/\1/')
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | sed 's/"tool_name":"\([^"]*\)"/\1/')

# Only proceed for PostToolUse events
if [ "$HOOK_EVENT" != "PostToolUse" ]; then
    exit 0
fi

# Only commit for file modification tools
case "$TOOL_NAME" in
    Write|Edit|MultiEdit|NotebookEdit)
        # Extract file path from tool input
        FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"\([^"]*\)"/\1/')
        
        # Check if we're in a git repository
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "Not in a git repository, skipping commit" >&2
            exit 0
        fi
        
        # Get the relative file path
        if [ -n "$FILE_PATH" ]; then
            RELATIVE_PATH=$(realpath --relative-to="$(git rev-parse --show-toplevel)" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
            
            # Stage the specific file
            git add "$FILE_PATH" 2>/dev/null
            
            # Create commit message
            COMMIT_MSG="Auto-commit: Claude Code modified $RELATIVE_PATH

Tool: $TOOL_NAME
Timestamp: $(date)

This commit was automatically created by a Claude Code hook
to allow easy reversion of changes if needed."
            
            # Make the commit
            git commit -m "$COMMIT_MSG" > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                echo "Successfully created auto-commit for $RELATIVE_PATH"
            fi
        fi
        ;;
    *)
        # Not a file modification tool, skip
        exit 0
        ;;
esac

exit 0