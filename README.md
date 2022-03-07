# docker-automated-media
 Automated Media Download Setup for Synology

 ## Introduction
 All credit for this fantastic project goes to [mdhiggings](https://github.com/mdhiggins/sonarr-sma)

## Setup
- Change volumes for each service, so it corresponds to your TV/Movie/Download folders
- Ensure that the correct ports for your services are exposed
- Copy autoProcess.ini.sample and remove .sample
- Add apikey to the Sonarr & Radarr sections
- Ensure you have Docker installed on your NAS

## Running
- Simply run the command docker-compose up -d
