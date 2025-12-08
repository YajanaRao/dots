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
# Modern design with native Ghostty progress bar support
function ghws
    # ANSI color codes
    set -l reset "\033[0m"
    set -l bold "\033[1m"
    set -l dim "\033[2m"
    set -l green "\033[32m"
    set -l red "\033[31m"
    set -l yellow "\033[33m"
    set -l blue "\033[34m"
    set -l cyan "\033[36m"
    set -l magenta "\033[35m"
    set -l white "\033[97m"
    set -l gray "\033[90m"

    # Spinner frames (modern, minimal)
    set -l spinner_frames "◐" "◓" "◑" "◒"
    set -l queued_frames "◜" "◠" "◝" "◞" "◡" "◟"
    set -l spinner_index 1
    
    # Ghostty native progress bar control sequences
    # OSC 9;4;state;value (state: 0=off, 1=progress, 2=error, 3=indeterminate)
    set -l ghostty_progress_start "\033]9;4;1;"
    set -l ghostty_progress_end "\033\\"
    set -l ghostty_progress_off "\033]9;4;0\033\\"
    set -l ghostty_progress_error "\033]9;4;2;100\033\\"
    set -l ghostty_progress_indeterminate "\033]9;4;3\033\\"

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
    printf "%b%s%b\n" $cyan "Fetching workflows..." $reset
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
    printf "%b%s%b %s\n" $cyan "Fetching latest run for:" $reset $workflow_name
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
    set refresh_count 0
    set last_progress_update 0
    
    while test "$monitoring" = "true"
        # Update spinner (4 frames instead of 10)
        set spinner_index (math "($spinner_index % 4) + 1")
        set queued_index (math "($spinner_index % 6) + 1")
        set current_spinner $spinner_frames[$spinner_index]
        set current_queued $queued_frames[$queued_index]
        
        # Fetch detailed run information including steps
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

        # Calculate job progress
        set jobs_count (echo $run_data | jq -r '.jobs | length')
        set completed_jobs (echo $run_data | jq -r '[.jobs[] | select(.status == "completed")] | length')
        set in_progress_jobs (echo $run_data | jq -r '[.jobs[] | select(.status == "in_progress")] | length')
        
        # Build progress bar (simplified, modern style)
        if test $jobs_count -gt 0
            set progress_percent (math "floor($completed_jobs * 100 / $jobs_count)")
            set bar_width 40
            set filled_width (math "floor($completed_jobs * $bar_width / $jobs_count)")
            set empty_width (math "$bar_width - $filled_width")
            
            set progress_bar ""
            # Filled portion (completed)
            for i in (seq 1 $filled_width)
                set progress_bar "$progress_bar▓"
            end
            # Empty portion
            for i in (seq 1 $empty_width)
                set progress_bar "$progress_bar░"
            end
        else
            set progress_bar "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
            set progress_percent 0
        end
        
        # Update Ghostty native progress bar
        # Update at most once per second to avoid timeout
        set current_time_sec (date +%s)
        if test (math "$current_time_sec - $last_progress_update") -ge 1
            if test "$status_value" = "completed"
                if test "$conclusion_value" = "success"
                    printf "%b" "$ghostty_progress_start""100""$ghostty_progress_end"
                else
                    printf "%b" "$ghostty_progress_error"
                end
            else if test "$status_value" = "in_progress"
                printf "%b" "$ghostty_progress_start""$progress_percent""$ghostty_progress_end"
            else if test "$status_value" = "queued"
                printf "%b" "$ghostty_progress_indeterminate"
            end
            set last_progress_update $current_time_sec
        end

        # Clear screen and display header
        clear
        
        # Modern minimal header with thin borders
        printf "\n"
        
        # Show status indicator with animation
        if test "$status_value" = "completed"
            if test "$conclusion_value" = "success"
                printf " %b%s WORKFLOW COMPLETED%b %s\n" $green "✓" $reset $workflow_name
            else if test "$conclusion_value" = "failure"
                printf " %b%s WORKFLOW FAILED%b %s\n" $red "✗" $reset $workflow_name
            else if test "$conclusion_value" = "cancelled"
                printf " %b%s WORKFLOW CANCELLED%b %s\n" $yellow "⊘" $reset $workflow_name
            else
                printf " %b%s WORKFLOW %s%b %s\n" $yellow "◆" (string upper $conclusion_value) $reset $workflow_name
            end
        else if test "$status_value" = "in_progress"
            printf " %b%s WORKFLOW RUNNING%b %s\n" $cyan $current_spinner $reset $workflow_name
        else if test "$status_value" = "queued"
            printf " %b%s WORKFLOW QUEUED%b %s\n" $yellow $current_queued $reset $workflow_name
        else
            printf " %b◆ WORKFLOW: %s%b %s\n" $yellow $status_value $reset $workflow_name
        end
        
        printf " %b%s%b\n\n" $gray "────────────────────────────────────────────────────────────" $reset
        
        # Progress bar section (modern, clean)
        if test "$status_value" != "completed"
            printf " %bProgress%b  %b%s%b %3d%% %b(%d/%d jobs)%b\n\n" $dim $reset $cyan $progress_bar $reset $progress_percent $gray $completed_jobs $jobs_count $reset
        end
        
        # Info section (compact, no emojis)
        printf " %b Commit%b    %s\n" $gray $reset "$display_title"
        printf " %b Branch%b    %s\n" $gray $reset "$head_branch"
        printf " %b Elapsed%b   %s\n" $gray $reset "$elapsed_display"
        printf " %b Run ID%b    %s\n" $gray $reset "$run_id"
        
        printf "\n %b%s%b\n" $gray "────────────────────────────────────────────────────────────" $reset
        printf " %bJOBS%b\n" $bold $reset
        printf " %b%s%b\n" $gray "────────────────────────────────────────────────────────────" $reset
        
        # Parse and display jobs with steps
        set job_index 0
        
        while test $job_index -lt $jobs_count
            set job_name (echo $run_data | jq -r ".jobs[$job_index].name // \"Job $job_index\"")
            set job_status (echo $run_data | jq -r ".jobs[$job_index].status // \"unknown\"")
            set job_conclusion (echo $run_data | jq -r ".jobs[$job_index].conclusion // \"none\"")
            set job_started_at (echo $run_data | jq -r ".jobs[$job_index].startedAt // \"\"")
            set job_completed_at (echo $run_data | jq -r ".jobs[$job_index].completedAt // \"\"")
            
            # Get steps for this job
            set steps_count (echo $run_data | jq -r ".jobs[$job_index].steps | length // 0")
            set completed_steps (echo $run_data | jq -r "[.jobs[$job_index].steps[] | select(.status == \"completed\")] | length // 0")
            set current_step_name (echo $run_data | jq -r "[.jobs[$job_index].steps[] | select(.status == \"in_progress\")][0].name // \"\"")
            set current_step_num (echo $run_data | jq -r "[.jobs[$job_index].steps[] | select(.status == \"in_progress\")][0].number // 0")
            
            # Calculate job duration
            if test -n "$job_completed_at" -a "$job_completed_at" != "null"
                set job_start_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$job_started_at" +%s 2>/dev/null)
                set job_end_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$job_completed_at" +%s 2>/dev/null)
                if test -n "$job_start_time" -a -n "$job_end_time"
                    set job_duration (math "$job_end_time - $job_start_time")
                    set job_duration_display "$job_duration"s
                else
                    set job_duration_display ""
                end
            else if test -n "$job_started_at" -a "$job_started_at" != "null"
                set job_start_time (date -jf "%Y-%m-%dT%H:%M:%SZ" "$job_started_at" +%s 2>/dev/null)
                if test -n "$job_start_time"
                    set job_elapsed (math "$current_time - $job_start_time")
                    set job_duration_display "$job_elapsed"s
                else
                    set job_duration_display ""
                end
            else
                set job_duration_display ""
            end
            
            # Display job with appropriate icon and color (clean, no box)
            if test "$job_status" = "completed"
                if test "$job_conclusion" = "success"
                    printf " %b✓%b %s %b%s%b\n" $green $reset "$job_name" $dim "$job_duration_display" $reset
                else if test "$job_conclusion" = "failure"
                    printf " %b✗%b %s %b%s%b\n" $red $reset "$job_name" $dim "$job_duration_display" $reset
                else if test "$job_conclusion" = "cancelled"
                    printf " %b⊘%b %s %b%s%b\n" $yellow $reset "$job_name" $dim "$job_duration_display" $reset
                else if test "$job_conclusion" = "skipped"
                    printf " %b⊙%b %b%s%b %b%s%b\n" $dim $reset $dim "$job_name" $reset $dim "$job_duration_display" $reset
                else
                    printf " ◆ %s %b%s%b\n" "$job_name" $dim "$job_duration_display" $reset
                end
            else if test "$job_status" = "in_progress"
                printf " %b%s%b %s %b%s%b\n" $cyan $current_spinner $reset "$job_name" $cyan "$job_duration_display" $reset
                # Show current step for in-progress jobs
                if test -n "$current_step_name" -a "$current_step_name" != "null"
                    printf "   %b→ Step %d/%d: %s%b\n" $dim $current_step_num $steps_count "$current_step_name" $reset
                end
            else if test "$job_status" = "queued"
                printf " %b%s%b %b%s%b %bqueued%b\n" $yellow $current_queued $reset $dim "$job_name" $reset $yellow $reset
            else
                printf " ◆ %s %b%s%b\n" "$job_name" $dim "$job_status" $reset
            end
            
            set job_index (math "$job_index + 1")
        end
        
        printf " %b%s%b\n" $gray "────────────────────────────────────────────────────────────" $reset
        
        # Check if workflow is completed
        if test "$status_value" = "completed"
            # Clear native progress bar
            printf "%b" "$ghostty_progress_off"
            
            echo ""
            
            # Show summary statistics with colors (clean, modern)
            set passed_jobs (echo $run_data | jq -r '[.jobs[] | select(.conclusion == "success")] | length')
            set failed_jobs (echo $run_data | jq -r '[.jobs[] | select(.conclusion == "failure")] | length')
            set skipped_jobs (echo $run_data | jq -r '[.jobs[] | select(.conclusion == "skipped")] | length')
            
            printf " %bSUMMARY%b\n" $bold $reset
            printf " %b%s%b\n" $gray "────────────────────────────────────────────────────────────" $reset
            printf " Total: %d" $jobs_count
            if test $passed_jobs -gt 0
                printf "   %b✓ Passed: %d%b" $green $passed_jobs $reset
            end
            if test $failed_jobs -gt 0
                printf "   %b✗ Failed: %d%b" $red $failed_jobs $reset
            end
            if test $skipped_jobs -gt 0
                printf "   %b⊙ Skipped: %d%b" $dim $skipped_jobs $reset
            end
            printf "\n"
            printf " Duration: %s\n" "$elapsed_display"
            printf " %b%s%b\n\n" $gray "────────────────────────────────────────────────────────────" $reset
            
            printf " %bNext Steps%b\n" $bold $reset
            if test "$conclusion_value" = "failure"
                printf "   %b•%b View failed logs: %bgh run view %s --log-failed%b\n" $red $reset $cyan $run_id $reset
                printf "   %b•%b Rerun failed:     %bgh run rerun %s --failed%b\n" $yellow $reset $cyan $run_id $reset
            end
            printf "   %b•%b View details:     %bgh run view %s%b\n" $blue $reset $cyan $run_id $reset
            printf "   %b•%b Open in browser:  %bopen %s%b\n" $blue $reset $cyan $run_url $reset
            echo ""
            
            # Play sound notification on macOS
            if test (uname) = "Darwin"
                if test "$conclusion_value" = "success"
                    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
                else if test "$conclusion_value" = "failure"
                    afplay /System/Library/Sounds/Basso.aiff 2>/dev/null &
                end
            end
            
            set monitoring false
        else
            echo ""
            # Clean refresh indicator
            printf " %b%s Refreshing in 3s%b (Ctrl+C to stop)\n" $dim $current_spinner $reset
            set refresh_count (math "$refresh_count + 1")
            sleep 3
        end
    end
end
