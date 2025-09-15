# VibeCoding Railway Development Template

This is the Railway template for VibeCoding development environments. It provides a pre-built container with React + Vite + Supabase + PiloTY MCP for Claude development.

## What This Template Provides

- ✅ **Ultra-Fast Package Management**: Bun for 3-10x faster installs than npm
- ✅ **Pre-installed Development Stack**: React, Vite, TypeScript, Supabase CLI, Tailwind CSS
- ✅ **PiloTY MCP Server**: Claude terminal access on port 8080
- ✅ **Vite Dev Server**: Hot reload development on port 3000
- ✅ **GitHub Integration**: Auto-clones user's GitHub repository
- ✅ **Claude Intelligence**: Connects to .claude folder for persistent AI memory
- ✅ **Health Monitoring**: Built-in health checks and auto-recovery

## Architecture

```
Railway Container (This Template)
├── Pre-built Development Environment
├── PiloTY MCP Server (Port 8080)
├── Vite Dev Server (Port 3000)
└── Auto-clone GitHub Repository
    └── Uses: react-vite-supabase-template
        └── Includes: .claude/ intelligence folder
```

## Environment Variables

The template expects these variables to be set by VibeCoding:

- `GITHUB_REPO_URL` - The user's GitHub repository to clone
- `PROJECT_NAME` - Name of the VibeCoding project
- `RAILWAY_ENVIRONMENT` - Set to "development"

## Deployment Flow

1. **Railway deploys this template** (30-60 seconds with Bun)
2. **Container starts and clones GitHub repo** (includes .claude folder)
3. **Ultra-fast dependency installation** with Bun (3-10x faster than npm)
4. **Starts development servers** (Vite + Claude MCP)
5. **Claude can connect via MCP** on port 8080
6. **User can preview via Vite** on port 3000

## Usage

This template is deployed automatically by VibeCoding's project creator. Users don't interact with it directly.

## Template ID

When deployed to Railway, this template should be assigned the ID:
`vibecoding-react-vite-supabase`

## Health Check

The template provides a health endpoint at `/health` that Railway uses to monitor container status. 