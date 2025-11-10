# GitHub browser utility
function ghb
    if test (count $argv) -eq 0
        echo "Usage: ghb <tab>  # e.g., ghb actions, ghb pulls, ghb issues"
        return 1
    end

    set tab $argv[1]
    set valid_tabs actions pulls issues wiki security releases projects discussions packages

    if not string match -q $tab $valid_tabs
        echo "Invalid tab: $tab. Valid options: $valid_tabs"
        return 1
    end

    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Not in a Git repository."
        return 1
    end

    set remote (git remote get-url origin 2>/dev/null)
    if test $status -ne 0
        echo "Could not fetch origin remote."
        return 1
    end

    if string match -q 'git@github.com:*' $remote
        set repo_url (string replace 'git@github.com:' 'https://github.com/' $remote)
    else if string match -q 'https://github.com/*' $remote
        set repo_url $remote
    else
        echo "Origin remote is not a GitHub repo: $remote"
        return 1
    end

    set repo_url (string replace '.git' '' $repo_url)
    set target_url $repo_url/$tab

    if test (uname) = "Darwin"  # macOS
        open $target_url
    else if test (uname) = "Linux"
        xdg-open $target_url
    else if string match -q "MINGW*" (uname -s)  # Windows/WSL
        explorer.exe $target_url
    else
        echo "Open in browser: $target_url"
    end
end

# GitHub Workflow List - List runs for a selected workflow
function ghwl
    # Check if fzf is installed
    if not command -v fzf >/dev/null 2>&1
        echo "Error: fzf is not installed. Please install it first."
        echo "  macOS: brew install fzf"
        echo "  Linux: sudo apt install fzf (or use your package manager)"
        return 1
    end

    # Check if gh CLI is installed
    if not command -v gh >/dev/null 2>&1
        echo "Error: gh CLI is not installed. Please install it first."
        echo "  macOS: brew install gh"
        echo "  Linux: Follow instructions at https://cli.github.com/"
        return 1
    end

    # Check if in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a Git repository."
        return 1
    end

    # Check if gh is authenticated
    if not gh auth status >/dev/null 2>&1
        echo "Error: gh CLI is not authenticated. Run 'gh auth login' first."
        return 1
    end

    # Fetch workflows with error handling
    echo "Fetching workflows..."
    set workflows (gh workflow list --all 2>&1)
    if test $status -ne 0
        echo "Error: Failed to fetch workflows."
        echo $workflows
        return 1
    end

    # Select workflow using fzf (printf to preserve newlines)
    set selected_workflow (printf '%s\n' $workflows | fzf --height=40% --reverse --header="Select a workflow to view runs" --ansi)
    if test -z "$selected_workflow"
        echo "No workflow selected. Exiting."
        return 0
    end

    # Extract workflow name using tab delimiter (gh workflow list uses tabs)
    # The format is: NAME\tSTATE\tID
    set workflow_name (echo $selected_workflow | cut -f1)

    # Display workflow runs
    echo ""
    echo "Workflow runs for: $workflow_name"
    echo ""
    
    # List runs for the selected workflow with customizable limit
    set limit 20
    if test (count $argv) -gt 0
        set limit $argv[1]
    end
    
    gh run list --workflow="$workflow_name" --limit=$limit
    
    if test $status -eq 0
        echo ""
        echo "Tip: Use 'ghwl <number>' to change the limit (default: 20)"
        echo "     Use 'gh run view <run-id>' to see details of a specific run"
        echo "     Use 'gh run watch <run-id>' to watch a run in progress"
    else
        echo ""
        echo "✗ Failed to fetch workflow runs."
        return 1
    end
end

# GitHub Workflow Runner - Interactive workflow and branch selector
function ghwr
    # Check if fzf is installed
    if not command -v fzf >/dev/null 2>&1
        echo "Error: fzf is not installed. Please install it first."
        echo "  macOS: brew install fzf"
        echo "  Linux: sudo apt install fzf (or use your package manager)"
        return 1
    end

    # Check if gh CLI is installed
    if not command -v gh >/dev/null 2>&1
        echo "Error: gh CLI is not installed. Please install it first."
        echo "  macOS: brew install gh"
        echo "  Linux: Follow instructions at https://cli.github.com/"
        return 1
    end

    # Check if in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a Git repository."
        return 1
    end

    # Check if gh is authenticated
    if not gh auth status >/dev/null 2>&1
        echo "Error: gh CLI is not authenticated. Run 'gh auth login' first."
        return 1
    end

    # Fetch workflows with error handling
    echo "Fetching workflows..."
    set workflows (gh workflow list --all 2>&1)
    if test $status -ne 0
        echo "Error: Failed to fetch workflows."
        echo $workflows
        return 1
    end

    # Select workflow using fzf (printf to preserve newlines)
    set selected_workflow (printf '%s\n' $workflows | fzf --height=40% --reverse --header="Select a workflow" --ansi)
    if test -z "$selected_workflow"
        echo "No workflow selected. Exiting."
        return 0
    end

    # Extract workflow name using tab delimiter (gh workflow list uses tabs)
    # The format is: NAME\tSTATE\tID
    set workflow_name (echo $selected_workflow | cut -f1)

    # Fetch remote branches
    echo "Fetching remote branches..."
    git fetch --quiet 2>/dev/null
    set branches (git branch -r | grep -v HEAD | sed 's/origin\///' | string trim)
    if test -z "$branches"
        echo "Error: No remote branches found."
        return 1
    end

    # Select branch using fzf (printf to preserve newlines)
    set selected_branch (printf '%s\n' $branches | fzf --height=40% --reverse --header="Select a branch" --ansi)
    if test -z "$selected_branch"
        echo "No branch selected. Exiting."
        return 0
    end

    # Display confirmation
    echo ""
    echo "Running workflow:"
    echo "  Workflow: $workflow_name"
    echo "  Branch: $selected_branch"
    echo ""

    # Run the workflow
    gh workflow run "$workflow_name" --ref "$selected_branch"
    
    if test $status -eq 0
        echo ""
        echo "✓ Workflow triggered successfully!"
        echo ""
        echo "View workflow runs with: gh run list --workflow=\"$workflow_name\""
        echo "Or open in browser: ghb actions"
    else
        echo ""
        echo "✗ Failed to trigger workflow."
        return 1
    end
end

