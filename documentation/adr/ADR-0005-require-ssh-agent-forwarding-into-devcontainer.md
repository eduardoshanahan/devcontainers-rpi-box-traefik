# ADR-0005: Require SSH agent forwarding into devcontainer

## Status

Accepted

## Context

The devcontainer needs to access private Git remotes over SSH.
Copying private keys into the container increases exposure risk and complicates key management.

## Decision

Require SSH agent forwarding for devcontainer sessions:

- The host `SSH_AUTH_SOCK` is mounted into the container at `/ssh-agent`.
- The container sets `SSH_AUTH_SOCK=/ssh-agent`.
- Validation ensures `SSH_AUTH_SOCK` is set and points to a valid socket before proceeding.

## Consequences

- Private keys remain on the host; the container uses the agent for authentication
- More secure and easier key rotation
- Requires a running SSH agent on the host before launching the devcontainer

## Alternatives Considered

- Copy keys into the container (rejected: higher risk and harder lifecycle management)
- Use HTTPS + tokens (deferred: may be useful, but not the default workflow here)

