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

# GitHub Workflow Status - Monitor latest workflow run with real-time progress
function ghws
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

    # Select workflow using fzf
    set selected_workflow (printf '%s\n' $workflows | fzf --height=40% --reverse --header="Select a workflow to monitor" --ansi)
    if test -z "$selected_workflow"
        echo "No workflow selected. Exiting."
        return 0
    end

    # Extract workflow name (tab-delimited format: NAME\tSTATE\tID)
    set workflow_name (echo $selected_workflow | cut -f1)

    # Fetch the latest run for the selected workflow
    echo "Fetching latest run for: $workflow_name"
    set latest_run_json (gh run list --workflow="$workflow_name" --limit=1 --json databaseId,status,conclusion,displayTitle,createdAt,headBranch 2>&1)
    
    if test $status -ne 0
        echo "Error: Failed to fetch workflow runs."
        echo $latest_run_json
        return 1
    end

    # Parse the run ID from JSON (it's an array, so we need the first element)
    set run_id (echo $latest_run_json | jq -r '.[0].databaseId // empty' 2>/dev/null)
    
    if test -z "$run_id"
        echo "Error: No runs found for workflow '$workflow_name'"
        return 1
    end

    # Start monitoring loop
    set monitoring true
    
    while test "$monitoring" = "true"
        # Fetch detailed run information
        set run_data (gh run view $run_id --json status,conclusion,jobs,createdAt,updatedAt,displayTitle,headBranch,url 2>&1)
        
        if test $status -ne 0
            echo "Error: Failed to fetch run details."
            echo $run_data
            return 1
        end

        # Parse run data
        set status_value (echo $run_data | jq -r '.status // "unknown"')
        set conclusion_value (echo $run_data | jq -r '.conclusion // "none"')
        set display_title (echo $run_data | jq -r '.displayTitle // "N/A"')
        set head_branch (echo $run_data | jq -r '.headBranch // "N/A"')
        set run_url (echo $run_data | jq -r '.url // ""')
        set created_at (echo $run_data | jq -r '.createdAt // ""')
        set updated_at (echo $run_data | jq -r '.updatedAt // ""')
        
        # Calculate elapsed time
        set current_time (date -u +%s)
        set created_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s 2>/dev/null)
        if test -n "$created_time"
            set elapsed_seconds (math "$current_time - $created_time")
            set elapsed_minutes (math "floor($elapsed_seconds / 60)")
            set elapsed_secs (math "$elapsed_seconds % 60")
            if test $elapsed_minutes -gt 0
                set elapsed_display "$elapsed_minutes"m" $elapsed_secs"s
            else
                set elapsed_display "$elapsed_secs"s
            end
        else
            set elapsed_display "N/A"
        end

        # Clear screen and display header
        clear
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Show status indicator
        if test "$status_value" = "completed"
            if test "$conclusion_value" = "success"
                echo "✓ Workflow Completed: $workflow_name"
            else if test "$conclusion_value" = "failure"
                echo "✗ Workflow Failed: $workflow_name"
            else if test "$conclusion_value" = "cancelled"
                echo "⊘ Workflow Cancelled: $workflow_name"
            else
                echo "◆ Workflow $conclusion_value: $workflow_name"
            end
        else if test "$status_value" = "in_progress"
            echo "🔄 Workflow Running: $workflow_name"
        else if test "$status_value" = "queued"
            echo "⏳ Workflow Queued: $workflow_name"
        else
            echo "◆ Workflow Status: $status_value - $workflow_name"
        end
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Commit: $display_title"
        echo "Branch: $head_branch | Run ID: $run_id | Elapsed: $elapsed_display"
        echo "URL: $run_url"
        echo ""
        echo "Jobs:"
        echo "─────────────────────────────────────────────────────"
        
        # Parse and display jobs
        set jobs_count (echo $run_data | jq -r '.jobs | length')
        set job_index 0
        
        while test $job_index -lt $jobs_count
            set job_name (echo $run_data | jq -r ".jobs[$job_index].name // \"Job $job_index\"")
            set job_status (echo $run_data | jq -r ".jobs[$job_index].status // \"unknown\"")
            set job_conclusion (echo $run_data | jq -r ".jobs[$job_index].conclusion // \"none\"")
            set job_started_at (echo $run_data | jq -r ".jobs[$job_index].startedAt // \"\"")
            set job_completed_at (echo $run_data | jq -r ".jobs[$job_index].completedAt // \"\"")
            
            # Calculate job duration
            if test -n "$job_completed_at" -a "$job_completed_at" != "null"
                set job_start_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$job_started_at" +%s 2>/dev/null)
                set job_end_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$job_completed_at" +%s 2>/dev/null)
                if test -n "$job_start_time" -a -n "$job_end_time"
                    set job_duration (math "$job_end_time - $job_start_time")
                    set job_duration_display " - $job_duration"s
                else
                    set job_duration_display ""
                end
            else if test -n "$job_started_at" -a "$job_started_at" != "null"
                set job_start_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$job_started_at" +%s 2>/dev/null)
                if test -n "$job_start_time"
                    set job_elapsed (math "$current_time - $job_start_time")
                    set job_duration_display " - $job_elapsed"s
                else
                    set job_duration_display ""
                end
            else
                set job_duration_display ""
            end
            
            # Display job with appropriate icon
            if test "$job_status" = "completed"
                if test "$job_conclusion" = "success"
                    echo "  ✓ $job_name (success)$job_duration_display"
                else if test "$job_conclusion" = "failure"
                    echo "  ✗ $job_name (failure)$job_duration_display"
                else if test "$job_conclusion" = "cancelled"
                    echo "  ⊘ $job_name (cancelled)$job_duration_display"
                else if test "$job_conclusion" = "skipped"
                    echo "  ⊙ $job_name (skipped)$job_duration_display"
                else
                    echo "  ◆ $job_name ($job_conclusion)$job_duration_display"
                end
            else if test "$job_status" = "in_progress"
                echo "  🔄 $job_name (running)$job_duration_display"
            else if test "$job_status" = "queued"
                echo "  ⏳ $job_name (queued)"
            else
                echo "  ◆ $job_name ($job_status)"
            end
            
            set job_index (math "$job_index + 1")
        end
        
        echo ""
        
        # Check if workflow is completed
        if test "$status_value" = "completed"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            
            # Show summary statistics
            set total_jobs $jobs_count
            set passed_jobs (echo $run_data | jq -r '[.jobs[] | select(.conclusion == "success")] | length')
            set failed_jobs (echo $run_data | jq -r '[.jobs[] | select(.conclusion == "failure")] | length')
            set skipped_jobs (echo $run_data | jq -r '[.jobs[] | select(.conclusion == "skipped")] | length')
            
            echo "Summary:"
            echo "  Total Jobs: $total_jobs"
            echo "  Passed: $passed_jobs"
            if test $failed_jobs -gt 0
                echo "  Failed: $failed_jobs"
            end
            if test $skipped_jobs -gt 0
                echo "  Skipped: $skipped_jobs"
            end
            echo "  Duration: $elapsed_display"
            echo ""
            echo "Next Steps:"
            if test "$conclusion_value" = "failure"
                echo "  • View logs: gh run view $run_id --log-failed"
                echo "  • Rerun failed jobs: gh run rerun $run_id --failed"
            end
            echo "  • View full details: gh run view $run_id"
            echo "  • Open in browser: open $run_url"
            echo ""
            
            set monitoring false
        else
            echo "Refreshing in 5 seconds... (Ctrl+C to stop)"
            sleep 5
        end
    end
end

