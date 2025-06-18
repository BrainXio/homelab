#!/bin/bash

docker compose -f ollama/docker-compose.yml --profile tailscale up -d --force-recreate --remove-orphans