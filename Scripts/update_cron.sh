#!/bin/bash

# Define paths
file_path="/shared/time.txt"
cron_job_file="/tmp/cronjob.tmp"
automation_script="/shared/Scripts/automation.sh"
cron_identifier="# automation_cron"
log_file="/shared/update_cron.log"

# Read the time from the file
if [[ -f "$file_path" ]]; then
    read_time=$(cat "$file_path" | tr -d '\r')  # Remove any carriage returns for Windows compatibility
else
    echo "$(date): $file_path does not exist." >> "$log_file"
    exit 1
fi

# Extract hours and minutes using awk for better handling
hours=$(echo "$read_time" | awk -F: '{print $1}' | sed 's/^0*//') # Remove leading zeros
minutes=$(echo "$read_time" | awk -F: '{print $2}' | sed 's/^0*//') # Remove leading zeros
echo "$(date): Read time: $hours:$minutes" >> "$log_file"

# Check values for debugging
echo "$(date): Processed hours: '$hours'" >> "$log_file"
echo "$(date): Processed minutes: '$minutes'" >> "$log_file"

# Create a new cron job entry
if [ -z "$hours" ] || [ "$hours" -eq "0" ]; then
    new_cron_job="*/$minutes * * * * $automation_script $cron_identifier"
else
    new_cron_job="*/$minutes */$hours * * * $automation_script $cron_identifier"
fi
echo "$(date): New cron job: $new_cron_job" >> "$log_file"

# Remove old cron jobs with the identifier
crontab -l | grep -v "$cron_identifier" > "$cron_job_file"

# Add the new cron job entry
echo "$new_cron_job" >> "$cron_job_file"

# Install the new cron job file
if crontab "$cron_job_file"; then
    echo "$(date): Cron job updated successfully." >> "$log_file"
else
    echo "$(date): Failed to update cron job." >> "$log_file"
fi
