# Nextcloud Deployment Plan for Biblical Document Sharing

## Overview
Deploy Nextcloud on Proxmox to create a secure, web-accessible platform for sharing biblical documents, audio files (MP3), images (JPG), and videos (MP4) with controlled user access.

## Architecture Decision

### Option 1: LXC Container (Recommended)
- **Pros**: Lightweight, fast, efficient resource usage
- **Cons**: Slightly more complex for some operations
- **Best for**: Your use case with document/media sharing

### Option 2: Virtual Machine
- **Pros**: Complete isolation, easier snapshots
- **Cons**: More resource overhead
- **Use if**: You need Windows clients or special software

## Storage Planning

### 1. Container/VM Storage
- **Location**: vm-storage (ZFS mirror)
- **Size**: 32GB for OS and Nextcloud application
- **Why**: Redundancy for the application

### 2. Data Storage
- **Location**: Create new ZFS dataset on vm-storage
- **Path**: /vm-storage/nextcloud-data
- **Size**: Start with 200GB (expandable)
- **Features**: 
  - ZFS snapshots for data protection
  - Compression enabled (saves space for documents)

### 3. Backup Strategy
- **Daily backups** to backup-storage
- **Weekly ZFS snapshots** retained for 4 weeks
- **Monthly snapshots** retained for 6 months

## Network Configuration

### 1. Internal Network
- Container IP: 192.168.1.x (static)
- Connected to Proxmox default bridge

### 2. External Access
- **Option A**: Direct port forward (simpler)
  - Forward ports 80/443 to Nextcloud
  - Use Let's Encrypt for SSL

- **Option B**: Reverse proxy (recommended)
  - Install Nginx Proxy Manager
  - Better security and flexibility
  - Easy SSL management

### 3. Domain Setup
- Register domain or use dynamic DNS
- Point to your public IP
- Configure SSL certificate

## Nextcloud Configuration

### 1. Installation Method
- **Ubuntu 22.04 LXC** template
- **Nextcloud AIO** (All-in-One) or manual install
- **MariaDB** for database
- **Redis** for caching

### 2. Storage Structure
```
/nextcloud-data/
├── Biblical-Documents/
│   ├── PDF/
│   ├── Word/
|   ├── Books/
│   └── Text/
├── Media/
│   ├── Audio-MP3/
│   │   ├── Sermons/
|   |   ├── Teaching Series/
│   │   └── Bible/
│   ├── Images-JPG/
│   │   ├── Maps/
│   │   └── Illustrations/
│   └── Video-MP4/
│       ├── Teachings/
│       └── Documentaries/
└── Shared-Resources/
```

### 3. User Management
- **Admin account**: Full control
- **User groups**:
  - Family: Full access
  - Friends: Selected folders
  - Public: Read-only specific content

### 4. Sharing Features
- Password-protected links
- Expiration dates for shares
- Download limits
- Watermarking for PDFs (optional)

## Security Considerations

### 1. Access Control
- Strong passwords enforced
- Two-factor authentication enabled
- IP whitelisting (optional)

### 2. Encryption
- SSL/TLS for all connections
- Server-side encryption for sensitive documents
- Encrypted backups

### 3. Firewall Rules
- Only open necessary ports
- Rate limiting enabled
- Fail2ban for brute force protection

## Performance Optimization

### 1. Caching
- Redis for file locking
- APCu for PHP caching
- Browser caching headers

### 2. Database
- MariaDB tuning for Nextcloud
- Regular maintenance scripts

### 3. PHP Configuration
- Memory limit: 512MB
- Upload size: 2GB (for videos)
- Execution time: 3600s

## Maintenance Plan

### 1. Updates
- Monthly Nextcloud updates
- Security updates immediately
- Test updates on snapshot first

### 2. Monitoring
- Disk space alerts
- Performance monitoring
- Access logs review

### 3. Backup Testing
- Monthly restore tests
- Document recovery procedures

## Implementation Steps

### Phase 1: Infrastructure (Day 1)
1. Create LXC container
2. Configure networking
3. Set up storage

### Phase 2: Installation (Day 1-2)
1. Install Nextcloud
2. Configure database
3. Set up caching

### Phase 3: Configuration (Day 2-3)
1. Create folder structure
2. Set up users/groups
3. Configure sharing

### Phase 4: Security (Day 3-4)
1. SSL certificates
2. Firewall rules
3. Backup automation

### Phase 5: Content (Day 4-5)
1. Upload documents
2. Organize media
3. Set permissions

### Phase 6: Testing (Day 5-6)
1. Test external access
2. Verify sharing works
3. Performance testing

## Resource Requirements

### Container Specs
- **CPU**: 2-4 cores
- **RAM**: 4-8GB
- **Storage**: 32GB OS + 200GB data (expandable)

### Expected Performance
- 10-20 concurrent users
- 100GB+ document storage
- Streaming 1080p videos

## Cost Estimate
- **Domain**: $12/year (optional)
- **Everything else**: Free (self-hosted)

## Alternative Considerations

### If Nextcloud seems too complex:
1. **Seafile**: Simpler, faster for documents
2. **FileRun**: Better media handling
3. **Pydio**: Modern interface

### Additional Features to Consider:
1. Collabora/OnlyOffice for document editing
2. Full-text search with Elasticsearch
3. Automatic Bible verse linking
4. Media transcoding for mobile
