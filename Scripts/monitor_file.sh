#!/bin/bash

# Define paths
file_path="/shared/time.txt"
update_script="/shared/Scripts/update_cron.sh"
log_file="/shared/monitor_file.log"

# Function to run the update script and log the result
run_update_script() {
    echo "$(date): Running update script." >> "$log_file"
    if $update_script > /dev/null 2>&1; then
        echo "$(date): $file_path modified, cron job updated." >> "$log_file"
    else
        echo "$(date): Failed to run update script." >> "$log_file"
    fi
}

# Get the initial checksum of the file
last_checksum=$(md5sum "$file_path" | awk '{ print $1 }')
echo "$(date): Initial checksum: $last_checksum" >> "$log_file"

# Initial run of the update script and cron update
run_update_script

# Monitor the file for changes and trigger the update script and cron update
while true; do
    # Periodically check the file checksum to catch changes from Windows
    current_checksum=$(md5sum "$file_path" | awk '{ print $1 }')
    if [ "$current_checksum" != "$last_checksum" ]; then
        echo "$(date): Checksum changed: $current_checksum" >> "$log_file"
        last_checksum=$current_checksum
        run_update_script
    fi

    sleep 5  # Reduced sleep interval to check more frequently
done
