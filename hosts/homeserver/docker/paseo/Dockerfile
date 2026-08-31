# Child image of the official Paseo image: installs the tools the daemon
# expects on PATH but the base image doesn't ship (gh is used for PR-aware
# worktrees and orchestration features).
#
# Per Paseo docs: leave the final user as root — the entrypoint uses root only
# for first-run mounted-volume setup, then drops to the non-root "paseo" user.
#
# After changing this file: docker compose build && docker compose up -d
# (docker compose up -d alone only builds if the image is missing)
FROM ghcr.io/getpaseo/paseo:latest

USER root

# GitHub CLI from the official apt repo
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gpg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Agent CLIs go here too, e.g.:
# RUN npm install -g @anthropic-ai/claude-code @openai/codex
