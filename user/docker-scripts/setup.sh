#!/usr/bin/zsh

# Update permissions of the docker compose volumes
chown user:user /user/projects
chown user:user /user/projects/.pnpm-store
chown user:user /user/projects/*
chown user:user /user/projects/*/node_modules
