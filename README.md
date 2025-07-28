# Proxmox Homelab Configuration

This repository contains all configuration files, scripts, and documentation for my Proxmox homelab setup.

## 🏠 Overview

- **Proxmox VE Server**: 192.168.1.10
- **Services Running**:
  - Nginx Proxy Manager (LXC 100)
  - Nextcloud AIO (LXC 101) - 192.168.1.50

## 📁 Repository Contents

### Documentation
- `nextcloud-deployment-plan.md` - Complete Nextcloud deployment strategy
- `nextcloud-backup-recovery-plan.md` - Backup and recovery procedures
- `nextcloud-aio-access-info.md` - Access information and setup guide
- `backup-completion-summary.md` - Backup status summary

### Scripts
- `proxmox-backup-strategy.sh` - Automated backup script for Proxmox

### Web Interface
- `proxmox-dashboard.html` - HTML dashboard for easy access to all services

## 🚀 Quick Start

1. **Access Dashboard**: Open `proxmox-dashboard.html` in your browser
2. **Proxmox Web UI**: https://192.168.1.10:8006
3. **Nextcloud Setup**: https://192.168.1.50:8080

## 🔧 Services

### Nginx Proxy Manager
- Container ID: 100
- Purpose: Reverse proxy with SSL management
- Access: http://192.168.1.10:81

### Nextcloud AIO
- Container ID: 101
- IP: 192.168.1.50
- Admin Port: 8080 (HTTPS)
- Features: All-in-One Nextcloud with Office, Talk, and more

## 🛡️ Backup Strategy

- **ZFS Snapshots**: Instant recovery capability
- **Container Backups**: Full system backups to backup-storage
- **Automated Script**: Run `proxmox-backup-strategy.sh` on Proxmox host

## 📝 Notes

- Always use HTTPS for Nextcloud AIO admin interface
- Container firewall has been disabled for Nextcloud (LXC 101)
- Backups are stored in `/mnt/backup` on Proxmox host

## 🔐 Security

- Use strong passwords
- Enable 2FA where possible
- Regular backups are automated
- Keep all services updated

## 📞 Support

For Proxmox issues, consult:
- [Proxmox Forum](https://forum.proxmox.com)
- [Nextcloud Documentation](https://docs.nextcloud.com)

---

Last updated: July 28, 2025
