#!/bin/bash
# Title: Task Manager
# Description: Displays all task status and provides bulk task management operations
# Author: spencershepard (GRIMM)
# Version: 1.0

TASK_DIR="/root/payloads/user/metapayload/.tasks"
MGMT_DIR="/root/payloads/user/metapayload"
LOOT_DIR="/root/loot/metapayload"

# Ensure task directory exists
if [ ! -d "$TASK_DIR" ]; then
    LOG yellow "No task directory found. No tasks to manage."
    exit 0
fi

# Function to count tasks by status
count_tasks() {
    local status="$1"
    local count=0
    
    shopt -s nullglob
    for meta_file in "$TASK_DIR"/*.meta; do
        [ -f "$meta_file" ] || continue
        
        source "$meta_file"
        
        # Check if task is actually running
        if [ "$TASK_STATUS" = "running" ] || [ "$TASK_STATUS" = "backgrounded" ]; then
            if [ -n "$TASK_PID" ] && ! kill -0 "$TASK_PID" 2>/dev/null; then
                # Task stopped, update status
                sed -i "s|^TASK_STATUS=.*|TASK_STATUS=\"completed\"|" "$meta_file"
                if ! grep -q "^TASK_END_TIME=" "$meta_file"; then
                    echo "TASK_END_TIME=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> "$meta_file"
                fi
                TASK_STATUS="completed"
            fi
        fi
        
        if [ "$status" = "all" ] || [ "$TASK_STATUS" = "$status" ]; then
            ((count++))
        fi
    done
    
    echo $count
}

# Function to display task summary
display_task_summary() {
    local total=$(count_tasks "all")
    local running=$(count_tasks "running")
    local backgrounded=$(count_tasks "backgrounded")
    local completed=$(count_tasks "completed")
    local failed=$(count_tasks "failed")
    
    LOG "Total Tasks: $total"
    LOG yellow "Running: $running"
    LOG cyan "Backgrounded: $backgrounded"
    LOG green "Completed: $completed"
    LOG red "Failed: $failed"
    LOG purple "══════"
}

# Function to display individual tasks
display_tasks() {
    local task_num=1
    
    shopt -s nullglob
    for meta_file in "$TASK_DIR"/*.meta; do
        [ -f "$meta_file" ] || continue
        
        source "$meta_file"
        
        # Check if task is actually running
        local is_running=false
        if [ "$TASK_STATUS" = "running" ] || [ "$TASK_STATUS" = "backgrounded" ]; then
            if [ -n "$TASK_PID" ] && kill -0 "$TASK_PID" 2>/dev/null; then
                is_running=true
            else
                # Update status if not running
                sed -i "s|^TASK_STATUS=.*|TASK_STATUS=\"completed\"|" "$meta_file"
                if ! grep -q "^TASK_END_TIME=" "$meta_file"; then
                    echo "TASK_END_TIME=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> "$meta_file"
                fi
                TASK_STATUS="completed"
            fi
        fi
        
        LOG ""
        LOG "─────────────────────────────────────────"
        LOG "Task #$task_num: $TASK_ID"
        LOG "─────────────────────────────────────────"
        
        # Truncate long commands for display
        local display_cmd="$TASK_CMD"
        if [ ${#display_cmd} -gt 60 ]; then
            display_cmd="${display_cmd:0:60}..."
        fi
        LOG "Command: $display_cmd"
        
        # Color-code status
        case "$TASK_STATUS" in
            "running"|"backgrounded")
                if [ "$is_running" = true ]; then
                    LOG yellow "Status: $TASK_STATUS (PID: $TASK_PID)"
                else
                    LOG cyan "Status: completed"
                fi
                ;;
            "completed")
                LOG green "Status: $TASK_STATUS"
                ;;
            "failed")
                LOG red "Status: $TASK_STATUS"
                ;;
            *)
                LOG "Status: $TASK_STATUS"
                ;;
        esac
        
        LOG "Started: $TASK_START_TIME"
        if [ -n "$TASK_END_TIME" ]; then
            LOG "Ended: $TASK_END_TIME"
        fi
        
        ((task_num++))
    done
    
    LOG ""
    LOG purple "═══════════════════════════════════════════"
}

# Function to stop all tasks
stop_all_tasks() {
    local stopped=0
    
    LOG yellow "Stopping all running tasks..."
    
    shopt -s nullglob
    for meta_file in "$TASK_DIR"/*.meta; do
        [ -f "$meta_file" ] || continue
        
        source "$meta_file"
        
        # Check if task is running
        if [ -n "$TASK_PID" ] && kill -0 "$TASK_PID" 2>/dev/null; then
            LOG "Stopping task $TASK_ID (PID: $TASK_PID)..."
            kill -TERM "$TASK_PID" 2>/dev/null
            sleep 0.5
            
            # Force kill if still running
            if kill -0 "$TASK_PID" 2>/dev/null; then
                kill -KILL "$TASK_PID" 2>/dev/null
            fi
            
            # Update metadata
            sed -i "s|^TASK_STATUS=.*|TASK_STATUS=\"stopped\"|" "$meta_file"
            if ! grep -q "^TASK_END_TIME=" "$meta_file"; then
                echo "TASK_END_TIME=\"$(date '+%Y-%m-%d %H:%M:%S')\"" >> "$meta_file"
            fi
            
            ((stopped++))
        fi
    done
    
    if [ $stopped -gt 0 ]; then
        LOG green "Stopped $stopped task(s)"
    else
        LOG cyan "No running tasks to stop"
    fi
}

# Function to delete all tasks
delete_all_tasks() {
    local deleted=0
    
    LOG yellow "Deleting all tasks..."
    
    # First stop all running tasks
    shopt -s nullglob
    for meta_file in "$TASK_DIR"/*.meta; do
        [ -f "$meta_file" ] || continue
        
        source "$meta_file"
        
        # Stop if running
        if [ -n "$TASK_PID" ] && kill -0 "$TASK_PID" 2>/dev/null; then
            kill -TERM "$TASK_PID" 2>/dev/null
            sleep 0.5
            kill -KILL "$TASK_PID" 2>/dev/null
        fi
        
        # Remove log file
        rm -f "$TASK_DIR/$TASK_ID.log"
        
        # Remove meta file
        rm -f "$meta_file"
        
        # Remove management payload
        local mgmt_payload_dir="$MGMT_DIR/View_Task_${TASK_ID}"
        rm -rf "$mgmt_payload_dir"
        
        ((deleted++))
    done
    
    if [ $deleted -gt 0 ]; then
        LOG green "Deleted $deleted task(s)"
    else
        LOG cyan "No tasks to delete"
    fi
}

# Function to export all logs
export_all_logs() {
    local exported=0
    
    LOG yellow "Exporting all task logs to loot..."
    
    mkdir -p "$LOOT_DIR"
    
    shopt -s nullglob
    for log_file in "$TASK_DIR"/*.log; do
        [ -f "$log_file" ] || continue
        
        local task_id=$(basename "$log_file" .log)
        local export_file="$LOOT_DIR/${task_id}_export.log"
        
        cp "$log_file" "$export_file"
        ((exported++))
    done
    
    if [ $exported -gt 0 ]; then
        LOG green "Exported $exported log(s) to $LOOT_DIR"
    else
        LOG cyan "No logs to export"
    fi
}

# Function to delete completed tasks
delete_completed_tasks() {
    local deleted=0
    
    LOG yellow "Deleting completed tasks..."
    
    shopt -s nullglob
    for meta_file in "$TASK_DIR"/*.meta; do
        [ -f "$meta_file" ] || continue
        
        source "$meta_file"
        
        # Check if task is completed (not running)
        local is_running=false
        if [ -n "$TASK_PID" ] && kill -0 "$TASK_PID" 2>/dev/null; then
            is_running=true
        fi
        
        if [ "$is_running" = false ]; then
            # Remove log file
            rm -f "$TASK_DIR/$TASK_ID.log"
            
            # Remove meta file
            rm -f "$meta_file"
            
            # Remove management payload
            local mgmt_payload_dir="$MGMT_DIR/View_Task_${TASK_ID}"
            rm -rf "$mgmt_payload_dir"
            
            ((deleted++))
        fi
    done
    
    if [ $deleted -gt 0 ]; then
        LOG green "Deleted $deleted completed task(s)"
    else
        LOG cyan "No completed tasks to delete"
    fi
}

# Main execution
display_task_summary
display_tasks

# Check if there are any tasks
total_tasks=$(count_tasks "all")
if [ $total_tasks -eq 0 ]; then
    LOG yellow "No tasks found"
    exit 0
fi

# Interactive menu
LOG ""
LOG cyan "  UP    - Stop all Tasks"
LOG cyan "  DOWN  - Delete all Tasks"
LOG cyan "  RIGHT - Export all Logs (to loot)"
LOG cyan "  LEFT  - Delete Completed Tasks"

resp=$(WAIT_FOR_INPUT "Press directional button or B to cancel")
case $? in
    $DUCKYSCRIPT_CANCELLED)
        LOG "Cancelled"
        exit 0
        ;;
    $DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
        LOG red "Error"
        exit 1
        ;;
esac

case "$resp" in
    "UP")
        # Stop all tasks
        LOG "Stop all tasks"
        resp=$(CONFIRMATION_DIALOG "Stop all running tasks?" "This will terminate all active tasks")
        case $? in
            $DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
                LOG red "Error in dialog"
                exit 1
                ;;
        esac
        
        case "$resp" in
            $DUCKYSCRIPT_USER_CONFIRMED)
                stop_all_tasks
                ;;
            $DUCKYSCRIPT_USER_DENIED)
                LOG "Cancelled"
                ;;
        esac
        ;;
    "DOWN")
        # Delete all tasks
        LOG "Delete all tasks"
        resp=$(CONFIRMATION_DIALOG "Delete ALL tasks?" "This will remove all task data and stop running tasks")
        case $? in
            $DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
                LOG red "Error in dialog"
                exit 1
                ;;
        esac
        
        case "$resp" in
            $DUCKYSCRIPT_USER_CONFIRMED)
                delete_all_tasks
                ;;
            $DUCKYSCRIPT_USER_DENIED)
                LOG "Cancelled"
                ;;
        esac
        ;;
    "RIGHT")
        # Export all logs
        LOG "Export all logs"
        export_all_logs
        ;;
    "LEFT")
        # Delete completed tasks
        LOG "Delete completed tasks"
        resp=$(CONFIRMATION_DIALOG "Delete completed tasks?" "This will remove all non-running tasks")
        case $? in
            $DUCKYSCRIPT_REJECTED|$DUCKYSCRIPT_ERROR)
                LOG red "Error in dialog"
                exit 1
                ;;
        esac
        
        case "$resp" in
            $DUCKYSCRIPT_USER_CONFIRMED)
                delete_completed_tasks
                ;;
            $DUCKYSCRIPT_USER_DENIED)
                LOG "Cancelled"
                ;;
        esac
        ;;
    "B")
        LOG "Cancelled"
        exit 0
        ;;
    *)
        LOG yellow "Unknown button: $resp"
        ;;
esac

LOG ""
LOG green "Task Manager operation complete"
exit 0
