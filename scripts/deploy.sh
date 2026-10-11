#!/bin/bash
set -e

NAME="vite-project"
USERNAME="jajalab"
IMAGE="$USERNAME/$NAME:latest"

echo
echo "DOCKER: Verifying"
docker --version

echo
echo "DOCKER: Pulling latest $NAME image.."
docker pull $IMAGE

echo
echo "DOCKER: Starting $NAME.."
if [ $( docker ps -a | grep $NAME | wc -l ) -gt 0 ]; then
    echo "Container: EXISTS"
    echo
    echo "DOCKER: Removing previous container.."
    docker rm -f "$NAME" 2>/dev/null || true

    echo
    echo "DOCKER: Launching new $IMAGE container.."
    docker run -d --name $NAME -p 5173:5173 $IMAGE

    STATE=$(docker inspect --format='{{.State.Status}}' $NAME)
    if [ "$STATE" = "running" ]; then
        echo "Container: RUNNING"
    else
        echo "Container: NOT RUNNING"
        echo "State: $STATE"
        exit 1
    fi
else
    echo "Container: NO EXISTING CONTAINER"

    echo "DOCKER: Launching new $IMAGE container.."
    docker run -d --name $NAME -p 5173:5173 $IMAGE

    exit 1
fi

echo
echo "DOKER: Validating $NAME application.."
if [ "$(curl --output /dev/null --silent --write-out '%{http_code}' http://localhost:5173)" = "200" ]; then
  echo "$NAME application available"
else
  echo "$NAME application not available"
  exit 1
fi

echo
echo "NGINX: Validating.."
if [ "$(curl --output /dev/null --silent --write-out '%{http_code}' http://localhost)" = "200" ]; then
  echo "$NAME application available"
else
  echo "$NAME application not available"
  exit 1
fi
