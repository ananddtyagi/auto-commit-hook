#!/bin/bash

# Auto-commit hook for Claude Code - runs after assistant response
# This creates a single commit after Claude Code finishes all operations

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not in a git repository, skipping commit" >&2
    exit 0
fi

# Check if there are changes to commit
if ! git diff --quiet || ! git diff --cached --quiet; then
    # Get list of modified files
    MODIFIED_FILES=$(git status --porcelain | grep -E "^[ M]M|^A|^[ ?]?" | awk '{print $2}' | sort | uniq)
    FILE_COUNT=$(echo "$MODIFIED_FILES" | grep -v "^$" | wc -l | tr -d ' ')
    
    if [ "$FILE_COUNT" -gt 0 ]; then
        # Stage all changes
        git add -A
        
        # Get first 5 files for commit message (or all if less than 5)
        if [ "$FILE_COUNT" -le 5 ]; then
            FILE_LIST=$(echo "$MODIFIED_FILES" | sed 's/^/  - /')
        else
            FILE_LIST=$(echo "$MODIFIED_FILES" | head -5 | sed 's/^/  - /')
            FILE_LIST="$FILE_LIST
  ... and $((FILE_COUNT - 5)) more files"
        fi
        
        # Create a descriptive commit message
        COMMIT_MSG="[auto-commit-hook] Changes from Claude Code interaction

Modified $FILE_COUNT file(s):
$FILE_LIST"
        
        # Make the commit
        git commit -m "$COMMIT_MSG" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "Successfully created auto-commit for $FILE_COUNT file(s)"
            COMMIT_HASH=$(git rev-parse --short HEAD)
            echo "Commit: $COMMIT_HASH"
        else
            echo "Failed to create auto-commit" >&2
        fi
    fi
else
    echo "No changes to commit"
fi

exit 0