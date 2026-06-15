#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Pull and run the live package directly from GHCR
sudo docker run -d -p 80:80 --restart always ghcr.io/briandu106/nginx-autoscale:latest
