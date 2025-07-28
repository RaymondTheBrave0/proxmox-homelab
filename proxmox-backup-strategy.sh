#!/bin/bash
# Proxmox Backup Strategy Script
# Created for Nextcloud deployment preparation
# Run this on Proxmox server (192.168.1.10)

# Configuration
BACKUP_STORAGE="backup-storage"
ZFS_POOL="vm-storage"
LOG_FILE="/var/log/proxmox-backup.log"
EMAIL="root@localhost"
RETENTION_DAYS=30
RETENTION_WEEKS=8
RETENTION_MONTHS=6

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to create ZFS snapshots
create_zfs_snapshots() {
    log_message "Starting ZFS snapshot creation..."
    
    # Get all datasets
    datasets=$(zfs list -H -o name | grep "^${ZFS_POOL}")
    
    for dataset in $datasets; do
        if [[ "$dataset" == *"subvol"* ]]; then
            snapshot_name="${dataset}@auto-$(date +'%Y%m%d-%H%M%S')"
            log_message "Creating snapshot: $snapshot_name"
            zfs snapshot "$snapshot_name"
            if [ $? -eq 0 ]; then
                log_message "SUCCESS: Snapshot created for $dataset"
            else
                log_message "ERROR: Failed to create snapshot for $dataset"
            fi
        fi
    done
}

# Function to backup containers and VMs
backup_vms() {
    log_message "Starting VM/Container backups..."
    
    # Get all running containers
    containers=$(pct list | grep running | awk '{print $1}')
    
    for vmid in $containers; do
        log_message "Backing up container $vmid..."
        vzdump $vmid --compress zstd --storage $BACKUP_STORAGE --mode snapshot
        if [ $? -eq 0 ]; then
            log_message "SUCCESS: Container $vmid backed up"
        else
            log_message "ERROR: Failed to backup container $vmid"
        fi
    done
    
    # Get all running VMs
    vms=$(qm list | grep running | awk '{print $1}')
    
    for vmid in $vms; do
        log_message "Backing up VM $vmid..."
        vzdump $vmid --compress zstd --storage $BACKUP_STORAGE --mode snapshot
        if [ $? -eq 0 ]; then
            log_message "SUCCESS: VM $vmid backed up"
        else
            log_message "ERROR: Failed to backup VM $vmid"
        fi
    done
}

# Function to clean old snapshots
cleanup_old_snapshots() {
    log_message "Cleaning up old snapshots..."
    
    # Daily snapshots older than RETENTION_DAYS
    daily_cutoff=$(date -d "$RETENTION_DAYS days ago" +%Y%m%d)
    
    # Weekly snapshots older than RETENTION_WEEKS
    weekly_cutoff=$(date -d "$((RETENTION_WEEKS * 7)) days ago" +%Y%m%d)
    
    # Monthly snapshots older than RETENTION_MONTHS
    monthly_cutoff=$(date -d "$((RETENTION_MONTHS * 30)) days ago" +%Y%m%d)
    
    # Get all snapshots
    snapshots=$(zfs list -H -t snapshot -o name | grep "@auto-")
    
    for snapshot in $snapshots; do
        snap_date=$(echo $snapshot | grep -oP '\d{8}' | head -1)
        
        if [[ "$snap_date" < "$daily_cutoff" ]]; then
            log_message "Removing old snapshot: $snapshot"
            zfs destroy "$snapshot"
        fi
    done
}

# Function to verify backup integrity
verify_backups() {
    log_message "Verifying backup integrity..."
    
    # Check backup storage space
    backup_usage=$(df -h /mnt/backup | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$backup_usage" -gt 90 ]; then
        log_message "WARNING: Backup storage is ${backup_usage}% full!"
        echo "Backup storage critical: ${backup_usage}% used" | mail -s "Proxmox Backup Warning" $EMAIL
    fi
    
    # Check ZFS pool health
    pool_status=$(zpool status $ZFS_POOL | grep state: | awk '{print $2}')
    
    if [ "$pool_status" != "ONLINE" ]; then
        log_message "ERROR: ZFS pool $ZFS_POOL is not healthy! Status: $pool_status"
        echo "ZFS pool $ZFS_POOL status: $pool_status" | mail -s "Proxmox ZFS Alert" $EMAIL
    fi
}

# Main execution
main() {
    log_message "=== Starting Proxmox backup process ==="
    
    # Create ZFS snapshots
    create_zfs_snapshots
    
    # Backup VMs and containers
    backup_vms
    
    # Cleanup old snapshots
    cleanup_old_snapshots
    
    # Verify backups
    verify_backups
    
    log_message "=== Backup process completed ==="
}

# Run main function
main
