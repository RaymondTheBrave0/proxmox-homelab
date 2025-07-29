# Proxmox Backup and Restore Guide

## Current Backup Configuration

### Backup Status ✅
- **Initial Full Backup**: Completed on July 29, 2025
- **Nginx Proxy Manager (Container 100)**: 784MB backup
- **Nextcloud (Container 101)**: 1.72GB backup (including data directory)
- **Backup Location**: `/mnt/backup` on Proxmox server
- **Storage**: backup-storage (960GB total, 0.08% used)

### Important Fix Applied
- Nextcloud data directory (`/mnt/nextcloud-data`) was initially excluded from backups
- This has been fixed by enabling `backup=1` flag on mp0 mount point
- All future backups will include the complete Nextcloud data

## Automated Backup Schedule

### Daily Backups
- **Time**: 2:00 AM daily
- **Script**: `/root/enhanced-backup-script.sh`
- **Retention Policy**:
  - Daily backups: Keep for 7 days
  - Weekly backups: Keep for 4 weeks (Sundays)
  - Monthly backups: Keep for 3 months (1st of month)

### What Gets Backed Up
1. **Container 100 (Nginx Proxy Manager)**:
   - Full system backup
   - All configurations and SSL certificates
   
2. **Container 101 (Nextcloud)**:
   - Full system backup
   - Nextcloud data directory (`/mnt/nextcloud-data`)
   - All user files and configurations

## Manual Backup Commands

### Backup Both Containers
```bash
ssh root@192.168.1.10 "vzdump 100 101 --compress zstd --storage backup-storage --mode snapshot"
```

### Backup Individual Container
```bash
# Nginx Proxy Manager
ssh root@192.168.1.10 "vzdump 100 --compress zstd --storage backup-storage --mode snapshot"

# Nextcloud
ssh root@192.168.1.10 "vzdump 101 --compress zstd --storage backup-storage --mode snapshot"
```

### Run Enhanced Backup Script Manually
```bash
ssh root@192.168.1.10 "/root/enhanced-backup-script.sh"
```

## Restore Procedures

### List Available Backups
```bash
ssh root@192.168.1.10 "ls -lht /mnt/backup/dump/*.tar.zst"
```

### Restore Container from Backup

#### Option 1: Restore Over Existing Container (Overwrites current)
```bash
# Stop the container first
ssh root@192.168.1.10 "pct stop <CONTAINER_ID>"

# Restore from backup
ssh root@192.168.1.10 "pct restore <CONTAINER_ID> /mnt/backup/dump/<BACKUP_FILE> --force"

# Example for Nextcloud:
ssh root@192.168.1.10 "pct stop 101"
ssh root@192.168.1.10 "pct restore 101 /mnt/backup/dump/vzdump-lxc-101-2025_07_29-21_06_16.tar.zst --force"
```

#### Option 2: Restore to New Container ID (Safer - keeps original)
```bash
# Restore to a new container ID (e.g., 102)
ssh root@192.168.1.10 "pct restore 102 /mnt/backup/dump/<BACKUP_FILE>"

# Then update the IP address if needed
ssh root@192.168.1.10 "pct set 102 -net0 name=eth0,bridge=vmbr0,firewall=0,gw=192.168.1.1,hwaddr=<NEW_MAC>,ip=<NEW_IP>/24,type=veth"
```

### Emergency Recovery Steps

If both containers are lost:

1. **Restore Nginx Proxy Manager first**:
   ```bash
   ssh root@192.168.1.10 "pct restore 100 /mnt/backup/dump/vzdump-lxc-100-<DATE>.tar.zst --force"
   ssh root@192.168.1.10 "pct start 100"
   ```

2. **Restore Nextcloud**:
   ```bash
   ssh root@192.168.1.10 "pct restore 101 /mnt/backup/dump/vzdump-lxc-101-<DATE>.tar.zst --force"
   ssh root@192.168.1.10 "pct start 101"
   ```

3. **Verify Services**:
   - Nginx Proxy Manager: http://192.168.1.10:81
   - Nextcloud: https://192.168.1.50:8080

## Backup Monitoring

### Check Backup Logs
```bash
ssh root@192.168.1.10 "tail -f /var/log/proxmox-backup.log"
```

### Check Cron Job Execution
```bash
ssh root@192.168.1.10 "tail -f /var/log/proxmox-backup-cron.log"
```

### Manual Backup Verification
```bash
ssh root@192.168.1.10 "/root/enhanced-backup-script.sh"
```

## Best Practices

1. **Before Major Changes**: Always create a manual backup
2. **Test Restores**: Periodically test restoring to a different container ID
3. **Monitor Storage**: Check backup storage isn't getting full
4. **Keep Documentation**: Update this guide with any changes

## Quick Reference

- **Proxmox Server**: 192.168.1.10
- **Backup Storage Path**: `/mnt/backup/dump/`
- **Backup Scripts Location**: `/root/`
- **Log Files**: `/var/log/proxmox-backup.log`
- **Cron Schedule**: Daily at 2:00 AM

## Disaster Recovery Checklist

- [ ] Backups are running daily (check logs)
- [ ] Backup storage has sufficient space
- [ ] Latest backup files exist for both containers
- [ ] Restore procedure has been tested
- [ ] This documentation is up to date

---
Last Updated: July 29, 2025
