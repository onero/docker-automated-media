# Docker Automated Media Stack

Automated media download and management setup for Synology NAS (and other systems).

## Overview

This Docker Compose stack provides a complete automated media management solution with the following services:

- **SABnzbd** - Usenet downloader
- **Sonarr** - TV series automation and management (with SMA integration)
- **Radarr** - Movie automation and management (with SMA integration)
- **Bazarr** - Subtitle download automation
- **Plex** - Media streaming server

All credit for the fantastic [Sickbeard MP4 Automator (SMA)](https://github.com/mdhiggins/sickbeard_mp4_automator) integration goes to [mdhiggins](https://github.com/mdhiggins/sonarr-sma).

## Features

- ✅ Automated TV show and movie downloads
- ✅ Automatic media transcoding via SMA
- ✅ Subtitle automation
- ✅ Plex media server integration
- ✅ Easy configuration via Docker Compose
- ✅ Optimized for Synology NAS

## Prerequisites

- Docker and Docker Compose installed on your system
- Access to Usenet providers (for SABnzbd)
- Storage volumes for media (TV shows, movies) and downloads

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/onero/docker-automated-media.git
cd docker-automated-media
```

### 2. Configure Volumes

Edit [docker-compose.yml](docker-compose.yml) and update the volume mappings for your setup:

```yaml
# Example: Replace these paths with your actual directories
- /volume1/Series:/tv          # Your TV shows folder
- /volume1/Movies:/movies       # Your movies folder
- /volume1/Downloads/complete:/downloads    # Download destination
```

**Default paths (Synology):**
- TV Shows: `/volume1/Series`
- Movies: `/volume1/Movies`
- Downloads: `/volume1/Downloads/complete`
- Incomplete Downloads: `/volume1/Downloads/incomplete`

### 3. Configure User Permissions

Update the user and group IDs in [docker-compose.yml](docker-compose.yml#L3-L9):

```yaml
x-common-variables: &common-variables
  PUID: 0  # Change to your user ID
  PGID: 0  # Change to your group ID
  TZ: Europe/Prague  # Change to your timezone
```

> **Tip:** Run `id` in terminal to find your user and group IDs.

### 4. Set Up SMA Configuration

Copy the sample configuration file:

```bash
cp config/autoProcess.ini.sample config/autoProcess.ini
```

Edit `config/autoProcess.ini` and configure your preferred settings. Key sections to review:
- **[Converter]** - FFmpeg settings and output format
- **[Video]** - Video codec preferences
- **[Audio]** - Audio codec and language settings

### 5. Configure Plex Claim Token

Get your Plex claim token from [plex.tv/claim](https://www.plex.tv/claim/) and update it in [docker-compose.yml](docker-compose.yml#L86):

```yaml
PLEX_CLAIM: claim-<your-claim-token>
HOSTNAME: 'AdaminoFlix'  # Change to your preferred name
```

### 6. Review Port Mappings

Default ports (ensure they don't conflict with existing services):
- SABnzbd: `8080`
- Sonarr: `8989`
- Radarr: `7878`
- Bazarr: `6767`
- Plex: `32400`

## Running the Stack

Start all services:

```bash
docker-compose up -d
```

Check service status:

```bash
docker-compose ps
```

View logs:

```bash
docker-compose logs -f
```

## Post-Installation Configuration

### 1. SABnzbd Setup
1. Access SABnzbd at `http://your-ip:8080`
2. Complete the setup wizard
3. Configure your Usenet provider
4. Set download directories

### 2. Sonarr Setup
1. Access Sonarr at `http://your-ip:8989`
2. Go to Settings → General → API Key
3. Copy the API key
4. Edit `config/autoProcess.ini` and add the key to the `[Sonarr]` section:
   ```ini
   [Sonarr]
   apikey = your-api-key-here
   ```
5. Configure download client (SABnzbd)
6. Add your TV show root folder (`/tv`)

### 3. Radarr Setup
1. Access Radarr at `http://your-ip:7878`
2. Go to Settings → General → API Key
3. Copy the API key
4. Edit `config/autoProcess.ini` and add the key to the `[Radarr]` section:
   ```ini
   [Radarr]
   apikey = your-api-key-here
   ```
5. Configure download client (SABnzbd)
6. Add your movie root folder (`/movies`)

### 4. Bazarr Setup
1. Access Bazarr at `http://your-ip:6767`
2. Connect to Sonarr and Radarr using their API keys
3. Configure subtitle providers
4. Set subtitle languages

### 5. Plex Setup
1. Access Plex at `http://your-ip:32400/web`
2. Sign in with your Plex account
3. Add libraries for TV shows (`/tv`) and movies (`/movies`)

## Maintenance

### Update Services

```bash
docker-compose pull
docker-compose up -d
```

### Stop Services

```bash
docker-compose down
```

### View Conversion Logs

```bash
./scripts/show-conversion-log.sh
```

### Manual Media Conversion

If you've added media to your library without SMA conversion (e.g., files added directly without going through Sonarr/Radarr), you can manually trigger conversion using the `manual-conversion.sh` script.

**For Sonarr (TV Shows):**
```bash
nohup /bin/bash "$(pwd)/scripts/manual-conversion.sh" Sonarr "/tv/Mr. Robot" > /dev/null 2>&1 &
```

**For Radarr (Movies):**
```bash
nohup /bin/bash "$(pwd)/scripts/manual-conversion.sh" Radarr "/movies/Gladiator" > /dev/null 2>&1 &
```

**Monitor conversion progress:**
```bash
tail -f ./conversion_progress.log
```

> **Note:** Replace the path with your actual media folder path. The script runs in the background and logs progress to `conversion_progress.log`.

### Restart a Specific Service

```bash
docker-compose restart sonarr
```

## Troubleshooting

### Permission Issues
- Ensure PUID and PGID match the user who owns the media directories
- Check folder permissions: `chmod -R 755 /volume1/Series /volume1/Movies`

### SMA Not Working
- Verify `autoProcess.ini` has correct API keys
- Check that the config volume is properly mounted
- Review container logs: `docker-compose logs sonarr` or `docker-compose logs radarr`

### Port Conflicts
- Change port mappings in [docker-compose.yml](docker-compose.yml) if needed
- Format: `host-port:container-port`

## File Structure

```
.
├── docker-compose.yml           # Main compose configuration
├── config/
│   ├── autoProcess.ini.sample   # SMA configuration template
│   └── autoProcess.ini          # Your SMA configuration (create this)
├── scripts/
│   ├── show-conversion-log.sh       # Helper script to view conversion logs
│   └── manual-conversion.sh         # Manual media conversion script
├── sabnzbd-data/                # SABnzbd config (auto-created)
├── sonarr-data/                 # Sonarr config (auto-created)
├── radarr-data/                 # Radarr config (auto-created)
├── bazarr-data/                 # Bazarr config (auto-created)
└── plex-data/                   # Plex config (auto-created)
```

## Contributing

Feel free to submit issues and pull requests to improve this setup!

## Credits

- [Sickbeard MP4 Automator](https://github.com/mdhiggins/sickbeard_mp4_automator) by [mdhiggins](https://github.com/mdhiggins)
- [LinuxServer.io](https://www.linuxserver.io/) for Docker images

## License

See [LICENSE](LICENSE) file for details.
