#!/bin/bash

# Script to rename .docx files: replace underscores with hyphens
# Operates on files in /home/raymond/Documents/posts/

SOURCE_DIR="/home/raymond/Documents/posts"
LOG_FILE="/home/raymond/Applications/proxmox-homelab/rename-log-$(date +%Y%m%d-%H%M%S).txt"

echo "Starting rename process..."
echo "Log file: $LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"
echo "Rename Log - $(date)" | tee -a "$LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"

# Count files
total_files=$(find "$SOURCE_DIR" -name "*.docx" -type f | wc -l)
echo "Found $total_files .docx files to process" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Process each .docx file
count=0
renamed=0
skipped=0

while IFS= read -r file; do
    count=$((count + 1))
    
    # Get directory and filename
    dir=$(dirname "$file")
    filename=$(basename "$file")
    
    # Check if filename contains underscores
    if [[ "$filename" == *"_"* ]]; then
        # Replace underscores with hyphens
        new_filename="${filename//_/-}"
        new_path="$dir/$new_filename"
        
        # Check if target file already exists
        if [ -f "$new_path" ]; then
            echo "[$count/$total_files] SKIP: Target already exists: $new_filename" | tee -a "$LOG_FILE"
            skipped=$((skipped + 1))
        else
            # Rename the file
            mv "$file" "$new_path"
            if [ $? -eq 0 ]; then
                echo "[$count/$total_files] RENAMED: $filename → $new_filename" | tee -a "$LOG_FILE"
                renamed=$((renamed + 1))
            else
                echo "[$count/$total_files] ERROR: Failed to rename $filename" | tee -a "$LOG_FILE"
            fi
        fi
    else
        echo "[$count/$total_files] NO CHANGE: $filename (no underscores)" | tee -a "$LOG_FILE"
        skipped=$((skipped + 1))
    fi
done < <(find "$SOURCE_DIR" -name "*.docx" -type f | sort)

echo "" | tee -a "$LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"
echo "Summary:" | tee -a "$LOG_FILE"
echo "- Total files: $total_files" | tee -a "$LOG_FILE"
echo "- Renamed: $renamed" | tee -a "$LOG_FILE"
echo "- Skipped: $skipped" | tee -a "$LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"

echo ""
echo "✓ Rename process complete!"
echo "  Check the log file for details: $LOG_FILE"
