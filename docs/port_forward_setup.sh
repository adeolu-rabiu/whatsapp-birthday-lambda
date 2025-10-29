#!/bin/bash
echo "Setting up port forwarding for WhatsApp Birthday Bot UI"
echo "Running this on your local machine will allow you to access the UI"
echo "Usage: ./port_forward_setup.sh [username] [custom_local_port]"

USERNAME=${1:-"user"}
LOCAL_PORT=${2:-"8080"}

echo "SSH command: ssh -L ${LOCAL_PORT}:localhost:3000 ${USERNAME}@192.168.1.66"
echo "After connecting, access the UI at: http://localhost:${LOCAL_PORT}"

read -p "Connect now? (y/n): " connect_now
if [[ "$connect_now" =~ ^[Yy]$ ]]; then
  ssh -L ${LOCAL_PORT}:localhost:3000 ${USERNAME}@192.168.1.66
fi
