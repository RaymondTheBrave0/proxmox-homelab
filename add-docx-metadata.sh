#!/bin/bash

# Script to add metadata to DOCX files for Nextcloud organization
# Specifically designed for theological/biblical content

DOCS_DIR="/home/raymond/Documents/posts"
LOG_FILE="/home/raymond/Applications/proxmox-homelab/metadata-log-$(date +%Y%m%d-%H%M%S).txt"

echo "Starting metadata addition process..."
echo "Log file: $LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"
echo "Metadata Addition Log - $(date)" | tee -a "$LOG_FILE"
echo "=========================" | tee -a "$LOG_FILE"

# Function to extract keywords from filename
extract_keywords() {
    local filename="$1"
    # Remove .docx extension and numbers at start
    local base=$(basename "$filename" .docx | sed 's/^[0-9]*-//')
    
    # Convert hyphens to spaces for keywords
    echo "${base//-/ }"
}

# Function to determine category based on filename
determine_category() {
    local filename="$1"
    local lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
    
    # Category logic based on content
    if [[ "$lower" =~ calvinism ]]; then
        echo "Calvinism"
    elif [[ "$lower" =~ revelation|rapture|tribulation|end.time|eschatology ]]; then
        echo "Eschatology"
    elif [[ "$lower" =~ baptism|communion|church ]]; then
        echo "Church Practices"
    elif [[ "$lower" =~ trinity|god|jesus|christ|holy.spirit ]]; then
        echo "Theology"
    elif [[ "$lower" =~ hebrew|greek|translation ]]; then
        echo "Biblical Languages"
    elif [[ "$lower" =~ healing|health|vitamin|covid|vaccine ]]; then
        echo "Health and Healing"
    elif [[ "$lower" =~ marriage|women|gender|sexuality ]]; then
        echo "Family and Relationships"
    elif [[ "$lower" =~ gnosticism|false.doctrine ]]; then
        echo "Apologetics"
    elif [[ "$lower" =~ prophecy|daniel|prophetic ]]; then
        echo "Prophecy"
    else
        echo "General Theology"
    fi
}

# Process each DOCX file
count=0
while IFS= read -r file; do
    count=$((count + 1))
    filename=$(basename "$file")
    
    # Extract information from filename
    keywords=$(extract_keywords "$filename")
    category=$(determine_category "$filename")
    title="${keywords}"
    
    echo "[$count] Processing: $filename" | tee -a "$LOG_FILE"
    echo "  Title: $title" | tee -a "$LOG_FILE"
    echo "  Keywords: $keywords" | tee -a "$LOG_FILE"
    echo "  Category: $category" | tee -a "$LOG_FILE"
    
    # Add metadata using exiftool
    exiftool -overwrite_original \
        -Title="$title" \
        -Subject="$category" \
        -Keywords="$keywords" \
        -Category="$category" \
        -Creator="Raymond Clements" \
        -Description="Theological document: $title" \
        -Company="RTBSoftware" \
        "$file" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Metadata added successfully" | tee -a "$LOG_FILE"
    else
        echo "  ✗ Failed to add metadata" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
    
done < <(find "$DOCS_DIR" -name "*.docx" -type f | sort)

echo "=========================" | tee -a "$LOG_FILE"
echo "Metadata addition complete!" | tee -a "$LOG_FILE"
echo "Total files processed: $count" | tee -a "$LOG_FILE"

# Create a sample metadata report
echo ""
echo "Creating metadata report..."
REPORT_FILE="/home/raymond/Applications/proxmox-homelab/docx-metadata-report.txt"

echo "DOCX Metadata Report - $(date)" > "$REPORT_FILE"
echo "======================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Show metadata fields that Nextcloud can use
echo "Metadata fields added for Nextcloud search:" >> "$REPORT_FILE"
echo "- Title: Document title for display" >> "$REPORT_FILE"
echo "- Subject/Category: For filtering and grouping" >> "$REPORT_FILE"
echo "- Keywords: For full-text search" >> "$REPORT_FILE"
echo "- Creator: Author information" >> "$REPORT_FILE"
echo "- Description: Additional context" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Categories used:" >> "$REPORT_FILE"
exiftool -Category -s3 "$DOCS_DIR"/*.docx 2>/dev/null | sort | uniq -c | sort -nr >> "$REPORT_FILE"

echo ""
echo "✓ Report saved to: $REPORT_FILE"
