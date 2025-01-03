```bash
docker stop valheim-dedicated1; docker rm valheim-dedicated1

docker run -d --net=host  --name=valheim-dedicated1 cm2network/valheim

docker run -d --net=host \
    -v "$(pwd)/valheim-data:/home/steam/valheim-dedicated/" \
    --name=valheim-dedicated cm2network/valheim
```