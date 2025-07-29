# Nextcloud File Access Methods

## Method 1: WebDAV (Immediate, no setup required)

In Thunar or Files file manager:
1. Press `Ctrl + L` to open location bar
2. Enter: `davs://nextcloud.rtbsoftware.duckdns.org/remote.php/dav/files/raymond/`
   Or for local access: `dav://192.168.1.49:81/remote.php/dav/files/raymond/`
3. Enter your Nextcloud username and password
4. You can now drag and drop files directly

## Method 2: Samba Share (Best for bulk operations)

Run the setup script:
```bash
./setup_nextcloud_samba_share.sh
```

Then access via:
- `smb://192.168.1.49/nextcloud-data`
- Navigate to your user folder: `raymond/files/`

## Method 3: Direct SSH Copy (For command line)

Copy files directly:
```bash
# First, copy to the container
scp -r /home/raymond/Documents/posts/* root@192.168.1.10:/tmp/

# Then move into Nextcloud
ssh root@192.168.1.10 "pct exec 101 -- docker cp /tmp/posts nextcloud-app-1:/tmp/"
ssh root@192.168.1.10 "pct exec 101 -- docker exec -u www-data nextcloud-app-1 cp -r /tmp/posts/* /var/www/html/data/raymond/files/"
ssh root@192.168.1.10 "pct exec 101 -- docker exec -u www-data nextcloud-app-1 php occ files:scan raymond"
```

## Method 4: Mount Permanently with fstab

Add to `/etc/fstab`:
```
//192.168.1.49/nextcloud-data /mnt/nextcloud cifs credentials=/home/raymond/.smbcredentials,uid=1000,gid=1000 0 0
```

Create credentials file:
```bash
echo "username=root" > ~/.smbcredentials
echo "password=YOUR_PASSWORD" >> ~/.smbcredentials
chmod 600 ~/.smbcredentials
```

## Important Notes:

1. After copying files via Samba/SSH, you need to rescan files in Nextcloud:
   ```bash
   ssh root@192.168.1.10 "pct exec 101 -- docker exec -u www-data nextcloud-app-1 php occ files:scan raymond"
   ```

2. Files should be placed in: `/raymond/files/` within the share

3. The WebDAV method automatically handles file scanning and indexing

4. For VSCode: You can use the "Remote - SSH" extension to directly edit files on the Nextcloud server
