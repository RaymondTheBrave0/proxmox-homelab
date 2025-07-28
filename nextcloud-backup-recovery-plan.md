# Nextcloud Backup and Recovery Plan

## Current Backup Status (Pre-Nextcloud Installation)

### Completed Backups:
1. **ZFS Snapshot Created**: `vm-storage/subvol-100-disk-0@pre-nextcloud-deployment`
   - Created: 28 July 2025
   - Purpose: Full system state before Nextcloud deployment
   
2. **Container Backup**: nginx-proxy (VMID 100)
   - Location: `/mnt/backup/dump/vzdump-lxc-100-2025_07_28-12_19_14.tar.zst`
   - Size: 769MB
   - Type: Compressed with zstd
   - Mode: Snapshot (no downtime)

## Backup Strategy

### 1. ZFS Snapshots (Instant Recovery)
- **Daily**: Automated snapshots retained for 30 days
- **Weekly**: Sunday snapshots retained for 8 weeks
- **Monthly**: First Sunday snapshots retained for 6 months

### 2. Proxmox VZDump Backups (Full System)
- **Daily**: All containers/VMs backed up to backup-storage
- **Compression**: ZSTD for optimal space/speed
- **Mode**: Snapshot (no downtime)

### 3. Nextcloud-Specific Backups (Post-Installation)
- **Database**: Daily MariaDB dumps
- **Data**: Synced to backup-storage
- **Config**: Version controlled

## Recovery Procedures

### 1. Quick Recovery from ZFS Snapshot
```bash
# List available snapshots
zfs list -t snapshot | grep vm-storage

# Rollback to specific snapshot
zfs rollback vm-storage/subvol-100-disk-0@pre-nextcloud-deployment

# Clone snapshot (safer option)
zfs clone vm-storage/subvol-100-disk-0@pre-nextcloud-deployment vm-storage/recovery-test
```

### 2. Full Container Recovery
```bash
# List available backups
ls -la /mnt/backup/dump/

# Restore container (will overwrite existing)
pct restore 100 /mnt/backup/dump/vzdump-lxc-100-2025_07_28-12_19_14.tar.zst --force

# Restore to new VMID (safer)
pct restore 101 /mnt/backup/dump/vzdump-lxc-100-2025_07_28-12_19_14.tar.zst
```

### 3. Nextcloud Data Recovery (Post-Installation)
```bash
# Database recovery
mysql -u root -p nextcloud < /backup/nextcloud-db-backup.sql

# File recovery from ZFS
zfs send vm-storage/nextcloud-data@backup | zfs receive vm-storage/nextcloud-data-restored

# Config recovery
cp /backup/nextcloud/config/config.php /var/www/nextcloud/config/
```

## Automation Setup

### 1. Install Backup Script
```bash
# Copy to Proxmox server
scp proxmox-backup-strategy.sh root@192.168.1.10:/usr/local/bin/
chmod +x /usr/local/bin/proxmox-backup-strategy.sh

# Test run
/usr/local/bin/proxmox-backup-strategy.sh
```

### 2. Setup Cron Jobs
```bash
# Edit crontab
crontab -e

# Add these lines:
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/proxmox-backup-strategy.sh

# Weekly ZFS scrub on Sunday at 3 AM
0 3 * * 0 zpool scrub vm-storage
```

### 3. Monitor Backup Health
```bash
# Check backup storage usage
df -h /mnt/backup

# Check ZFS health
zpool status vm-storage

# List recent backups
ls -lht /mnt/backup/dump/ | head -10

# Check ZFS snapshots
zfs list -t snapshot
```

## Pre-Nextcloud Installation Checklist

- [x] ZFS snapshot created: `pre-nextcloud-deployment`
- [x] nginx-proxy container backed up
- [x] Backup script created
- [x] Recovery procedures documented
- [ ] Test recovery procedure (optional but recommended)
- [ ] Setup automated backups
- [ ] Verify backup storage has sufficient space

## Emergency Contacts

- Proxmox Forum: https://forum.proxmox.com
- ZFS Documentation: https://openzfs.github.io/openzfs-docs/
- Local backup location: /mnt/backup
- ZFS pool: vm-storage

## Important Notes

1. **Always test recovery procedures** in a non-production environment
2. **Monitor backup storage** - currently 960GB available
3. **ZFS snapshots** are instant but consume space as data changes
4. **VZDump backups** are complete but take time and space
5. **Keep this document updated** as system changes

## Next Steps for Nextcloud

Once Nextcloud is installed:
1. Create dedicated backup dataset: `zfs create vm-storage/nextcloud-backups`
2. Setup Nextcloud backup script
3. Configure database dumps
4. Test full recovery procedure
5. Document Nextcloud-specific recovery steps
