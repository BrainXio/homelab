#!/bin/bash

docker compose -f automation/docker-compose.yml --profile tail up -d --force-recreate --remove-orphans