# SupportChatBot

AI-powered IT support assistant for the SWC team at Volvo Group Digital Technology & Operations.

## Architecture

The service runs as a single Docker container that serves a web UI on port 5050. All AI inference happens on-premises using local Mac Studio servers running Ollama — no cloud APIs, no data leaving the Volvo network.

```
User Browser → Docker Container (port 5050) → Ollama (internal Mac Studios)
                      ↕
              kb.json (knowledge base)
```

## Design Decisions

### Docker-First Deployment

The application is packaged as a Docker image published to Docker Hub. This means:

- No .NET SDK, no Python, no build tools needed on team machines
- One command to pull, one command to run
- Consistent environment across all team laptops
- Auto-restarts with Docker Desktop

### Security Model

Three layers of separation keep things safe:

1. **Application code** (Docker image, public) — contains zero Volvo data. Just the .NET app that processes queries. Anyone can pull it; there's nothing sensitive inside.

2. **Knowledge base** (kb.json, private) — contains embedded Volvo internal knowledge. Distributed separately through authenticated corporate channels. Never committed to any public repository.

3. **Configuration** (.env file, local only) — created at setup time on each machine. Contains only internal server URLs. Never leaves the user's laptop.

This separation means the public Docker image is safe to host openly, while sensitive knowledge stays within Volvo's authenticated perimeter.

### Authentication

- **Docker image**: No authentication needed. Public pull from Docker Hub.
- **Knowledge base**: Requires Volvo SSO (corporate browser login). Cannot be downloaded programmatically — this is intentional, not a bug.
- **Ollama servers**: Only reachable from the Volvo internal network. No auth tokens needed — network boundary is the access control.
- **The bot itself**: No user login. It runs locally on your machine, talks only to internal servers.

### Efficiency & Load Balancing

- **Round-robin Ollama routing**: The app supports multiple Ollama hosts. If one Mac Studio is busy or down, requests route to the next.
- **Failover**: If the primary model fails, the app automatically falls back to a lighter model.
- **Embedding is pre-computed**: The knowledge base ships with pre-calculated vector embeddings. No embedding computation happens at query time for the KB — only the user's question gets embedded live.
- **Lightweight container**: ~110 MB image, 1 GB memory limit, 2 CPU cores. Runs fine alongside normal work.

### On-Premises AI

All inference runs on two Mac Studios on the internal network:

- No OpenAI, no Azure AI, no external LLM APIs
- Questions and answers never leave the corporate network
- Models: Gemma 4 (primary), with automatic fallback
- Embedding: nomic-embed-text (768 dimensions, cosine similarity)

## Setup

Requires: Docker Desktop running, Volvo network access.

1. Clone this repo
2. Obtain `kb.json` from your team lead (browser download, corporate auth required)
3. Run `setup.bat`

The bot will be available at `http://localhost:5050`.

## Files

| File | Purpose |
|------|---------|
| `setup.bat` | Pulls image, configures, and starts the container |
| `diagnose.bat` | Collects diagnostics for troubleshooting |
| `kb.json` | Knowledge base (not in repo — obtained separately) |

## Team

SWC Team, Volvo Group Digital Technology & Operations
