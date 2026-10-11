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

fi

echo
sleep 2
echo "DOKER: Validating $NAME application.."
for i in {1..10}; do
    HTTP_CODE=$(curl --output /dev/null --silent --write-out '%{http_code}' http://localhost:5173 || true)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "$NAME application available"
        break
    fi

    if [ "$i" -eq 10 ]; then
        echo "$NAME application not available"
        echo "HTTP status: $HTTP_CODE"
        docker logs "$NAME"
        exit 1
    fi

    echo "Application not ready yet. Attempt $i/10. Retrying in 1 second.."
    sleep 1
done

echo
sleep 2
echo "NGINX: Validating.."
for i in {1..10}; do
    HTTP_CODE=$(curl --output /dev/null --silent --write-out '%{http_code}' http://localhost || true)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "$NAME application available"
        break
    fi

    if [ "$i" -eq 10 ]; then
        echo "$NAME application not available"
        echo "HTTP status: $HTTP_CODE"
        systemctl status nginx
        exit 1
    fi

    echo "Application not ready yet. Attempt $i/10. Retrying in 1 second.."
    sleep 1
done
