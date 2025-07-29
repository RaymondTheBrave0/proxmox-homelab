#!/bin/bash
# Enhanced Proxmox Backup Script with Nextcloud AIO Support
# This script provides comprehensive backup for Proxmox containers with special handling for Nextcloud

# Configuration
BACKUP_STORAGE="backup-storage"
BACKUP_PATH="/mnt/backup"
LOG_FILE="/var/log/proxmox-backup.log"
EMAIL="root@localhost"
NEXTCLOUD_CONTAINER="101"
NGINX_CONTAINER="100"

# Retention policy
DAILY_BACKUPS=7
WEEKLY_BACKUPS=4
MONTHLY_BACKUPS=3

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check disk space
check_disk_space() {
    log_message "Checking disk space..."
    
    # Check backup storage
    backup_usage=$(df -h $BACKUP_PATH | awk 'NR==2 {print $5}' | sed 's/%//')
    available_space=$(df -h $BACKUP_PATH | awk 'NR==2 {print $4}')
    
    log_message "Backup storage usage: ${backup_usage}%, Available: ${available_space}"
    
    if [ "$backup_usage" -gt 85 ]; then
        log_message "WARNING: Backup storage is ${backup_usage}% full!"
        return 1
    fi
    return 0
}

# Function to backup containers with verification
backup_containers() {
    local backup_type=$1
    local timestamp=$(date +'%Y%m%d_%H%M%S')
    
    log_message "Starting $backup_type backup..."
    
    # Backup each container
    for container_id in $NGINX_CONTAINER $NEXTCLOUD_CONTAINER; do
        container_name=$(pct config $container_id | grep "hostname:" | awk '{print $2}')
        log_message "Backing up container $container_id ($container_name)..."
        
        # Create backup with detailed notes
        vzdump $container_id \
            --compress zstd \
            --storage $BACKUP_STORAGE \
            --mode snapshot \
            --notes "Type: $backup_type | Date: $(date) | Container: $container_name" \
            --quiet
        
        if [ $? -eq 0 ]; then
            log_message "SUCCESS: Container $container_id backed up"
            
            # Get backup file name
            backup_file=$(ls -t $BACKUP_PATH/dump/vzdump-lxc-$container_id-*.tar.zst | head -1)
            
            # Verify backup
            if [ -f "$backup_file" ]; then
                file_size=$(ls -lh "$backup_file" | awk '{print $5}')
                log_message "Backup verified: $backup_file (Size: $file_size)"
            fi
        else
            log_message "ERROR: Failed to backup container $container_id"
            return 1
        fi
    done
    
    return 0
}

# Function to create Nextcloud-specific backup
backup_nextcloud_data() {
    log_message "Creating Nextcloud data snapshot..."
    
    # Check if Nextcloud has external data mount
    external_mount=$(pct config $NEXTCLOUD_CONTAINER | grep "mp0:" | awk '{print $2}')
    
    if [ ! -z "$external_mount" ]; then
        log_message "Nextcloud has external mount at: $external_mount"
        
        # Create a tar backup of Nextcloud data (if needed)
        # This is optional since the container backup includes the mount point
        log_message "External mount will be handled by container snapshot"
    fi
    
    # Put Nextcloud in maintenance mode before backup (optional)
    # pct exec $NEXTCLOUD_CONTAINER -- sudo -u www-data php /var/www/html/occ maintenance:mode --on
    
    # Perform backup
    backup_containers "nextcloud-special"
    
    # Disable maintenance mode after backup (optional)
    # pct exec $NEXTCLOUD_CONTAINER -- sudo -u www-data php /var/www/html/occ maintenance:mode --off
}

# Function to cleanup old backups
cleanup_old_backups() {
    log_message "Cleaning up old backups..."
    
    # Get current date components
    current_date=$(date +%s)
    
    # List all backup files
    backup_files=$(ls -t $BACKUP_PATH/dump/vzdump-lxc-*.tar.zst 2>/dev/null)
    
    for backup_file in $backup_files; do
        # Extract date from filename
        file_date=$(stat -c %Y "$backup_file")
        age_days=$(( ($current_date - $file_date) / 86400 ))
        
        # Determine if backup should be kept
        keep_backup=false
        
        # Keep daily backups for DAILY_BACKUPS days
        if [ $age_days -le $DAILY_BACKUPS ]; then
            keep_backup=true
            backup_type="daily"
        # Keep weekly backups (Sunday) for WEEKLY_BACKUPS weeks
        elif [ $age_days -le $((WEEKLY_BACKUPS * 7)) ]; then
            day_of_week=$(date -d "@$file_date" +%w)
            if [ "$day_of_week" -eq 0 ]; then
                keep_backup=true
                backup_type="weekly"
            fi
        # Keep monthly backups (1st of month) for MONTHLY_BACKUPS months
        elif [ $age_days -le $((MONTHLY_BACKUPS * 30)) ]; then
            day_of_month=$(date -d "@$file_date" +%d)
            if [ "$day_of_month" -eq "01" ]; then
                keep_backup=true
                backup_type="monthly"
            fi
        fi
        
        if [ "$keep_backup" = false ] && [ $age_days -gt $DAILY_BACKUPS ]; then
            log_message "Removing old backup: $backup_file (Age: $age_days days)"
            rm -f "$backup_file"
            rm -f "${backup_file}.notes"
        else
            log_message "Keeping $backup_type backup: $(basename $backup_file) (Age: $age_days days)"
        fi
    done
}

# Function to generate backup report
generate_backup_report() {
    log_message "Generating backup report..."
    
    report_file="/tmp/backup_report_$(date +%Y%m%d).txt"
    
    echo "=== Proxmox Backup Report ===" > $report_file
    echo "Date: $(date)" >> $report_file
    echo "" >> $report_file
    
    echo "=== Storage Status ===" >> $report_file
    df -h $BACKUP_PATH >> $report_file
    echo "" >> $report_file
    
    echo "=== Recent Backups ===" >> $report_file
    ls -lht $BACKUP_PATH/dump/vzdump-lxc-*.tar.zst | head -20 >> $report_file
    echo "" >> $report_file
    
    echo "=== Container Status ===" >> $report_file
    pct list >> $report_file
    echo "" >> $report_file
    
    echo "=== Backup Summary ===" >> $report_file
    echo "Total backups: $(ls $BACKUP_PATH/dump/vzdump-lxc-*.tar.zst 2>/dev/null | wc -l)" >> $report_file
    echo "Total size: $(du -sh $BACKUP_PATH/dump/ | awk '{print $1}')" >> $report_file
    
    # Send report via email (if configured)
    if command -v mail >/dev/null 2>&1; then
        cat $report_file | mail -s "Proxmox Backup Report - $(date +%Y-%m-%d)" $EMAIL
    fi
    
    # Also save to log
    cat $report_file >> $LOG_FILE
}

# Function to test restore capability
test_restore_capability() {
    log_message "Testing restore capability..."
    
    # List available backups
    latest_nginx_backup=$(ls -t $BACKUP_PATH/dump/vzdump-lxc-${NGINX_CONTAINER}-*.tar.zst 2>/dev/null | head -1)
    latest_nextcloud_backup=$(ls -t $BACKUP_PATH/dump/vzdump-lxc-${NEXTCLOUD_CONTAINER}-*.tar.zst 2>/dev/null | head -1)
    
    if [ -z "$latest_nginx_backup" ] || [ -z "$latest_nextcloud_backup" ]; then
        log_message "ERROR: No backups found for testing"
        return 1
    fi
    
    log_message "Latest backups available for restore:"
    log_message "  Nginx: $(basename $latest_nginx_backup)"
    log_message "  Nextcloud: $(basename $latest_nextcloud_backup)"
    
    # Verify backup integrity
    for backup in $latest_nginx_backup $latest_nextcloud_backup; do
        if tar -tzf "$backup" >/dev/null 2>&1; then
            log_message "Backup integrity verified: $(basename $backup)"
        else
            log_message "ERROR: Backup integrity check failed: $(basename $backup)"
            return 1
        fi
    done
    
    return 0
}

# Main execution
main() {
    log_message "========================================="
    log_message "Starting Enhanced Proxmox Backup Process"
    log_message "========================================="
    
    # Check prerequisites
    if ! check_disk_space; then
        log_message "ERROR: Insufficient disk space for backup"
        exit 1
    fi
    
    # Determine backup type based on day
    day_of_week=$(date +%w)
    day_of_month=$(date +%d)
    
    if [ "$day_of_month" -eq "01" ]; then
        backup_type="monthly"
    elif [ "$day_of_week" -eq "0" ]; then
        backup_type="weekly"
    else
        backup_type="daily"
    fi
    
    # Perform backups
    if backup_containers "$backup_type"; then
        log_message "Backup completed successfully"
    else
        log_message "ERROR: Backup failed"
        exit 1
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Test restore capability
    test_restore_capability
    
    # Generate report
    generate_backup_report
    
    log_message "========================================="
    log_message "Backup Process Completed"
    log_message "========================================="
}

# Run main function
main
