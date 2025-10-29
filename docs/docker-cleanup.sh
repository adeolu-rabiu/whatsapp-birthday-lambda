#!/bin/bash

echo "Starting Docker cleanup process..."

# First make sure Docker service is running
if ! systemctl is-active --quiet docker; then
  echo "Docker is not running, starting it..."
  sudo systemctl start docker
  sleep 5
fi

echo "Removing all stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -a -f

echo "Removing unused volumes..."
docker volume prune -f

echo "Removing unused networks..."
docker network prune -f

echo "Running full system prune..."
docker system prune -a -f --volumes

echo "Docker cleanup complete!"

# Note for WSL disk optimization:
#echo ""
#echo "NOTE: To optimize your Docker WSL disk in Windows, run this in PowerShell with Admin rights:"
#echo "Optimize-VHD -Path \"C:\\Users\\user\\AppData\\Local\\Docker\\wsl\\data\\docker_data.vhdx\" -Mode Full"
#echo ""
