```bash
# https://developer.valvesoftware.com/wiki/SteamCMD
# https://hub.docker.com/r/cm2network/valheim/

docker stop valheim-dedicated; docker rm valheim-dedicated
mkdir /opt/valheim-data
chmod 777 /opt/valheim-data
docker run -d --net=host -v "/opt/valheim-data:/home/steam/valheim-dedicated/" -e SERVER_PORT=2456 --name=valheim-dedicated cm2network/valheim
```


```bash
docker stop steamcmd; docker rm steamcmd
docker run -it --name=steamcmd cm2network/steamcmd bash
./steamcmd.sh +force_install_dir /home/steam/enshrouded-dedicated +login anonymous +app_update 2278520 +quit
```


```bash
docker volume create enshrouded-persistent-data
docker run \
  --detach \
  --name enshrouded-server \
  --mount type=volume,source=enshrouded-persistent-data,target=/home/steam/enshrouded/savegame \
  --publish 15636:15636/udp \
  --publish 15637:15637/udp \
  --env=SERVER_NAME='Enshrouded Containerized Server' \
  --env=SERVER_SLOTS=16 \
  --env=SERVER_PASSWORD='boobs' \
  --env=GAME_PORT=15636 \
  --env=QUERY_PORT=15637 \
  sknnr/enshrouded-dedicated-server:latest
```
