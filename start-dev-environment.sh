#!/bin/bash
set -e

echo "🚀 Starting VibeCoding Development Environment..."
echo "📦 Template: vibecoding-react-vite-supabase"
echo "🔗 GitHub Repo: ${GITHUB_REPO_URL:-'Not provided'}"
echo "📁 Project: ${PROJECT_NAME:-'Unnamed'}"

# Navigate to app directory
cd /app

# Clone GitHub repository if provided
if [ ! -z "$GITHUB_REPO_URL" ] && [ "$GITHUB_REPO_URL" != "" ]; then
    echo "📥 Cloning GitHub repository..."
    
    # Remove existing project directory if it exists
    if [ -d "project" ]; then
        rm -rf project
    fi
    
    # Clone the repository (should be from react-vite-supabase-template)
    git clone "$GITHUB_REPO_URL" project
    cd project
    
    echo "✅ Repository cloned successfully"
    
    # Update from remote (get latest changes)
    git pull origin main || git pull origin master || echo "⚠️ Could not pull latest changes"
else
    echo "📦 No custom repository provided, using VibeCoding template..."
    GITHUB_REPO_URL="https://github.com/vibecoding1/vibecoding-railway-template"
    
    # Remove existing project directory if it exists
    if [ -d "project" ]; then
        rm -rf project
    fi
    
    # Clone the VibeCoding template repository
    git clone "$GITHUB_REPO_URL" project
    cd project
    
    echo "✅ VibeCoding template cloned successfully"
    
    # Update from remote (get latest changes)
    git pull origin main || git pull origin develop || echo "⚠️ Could not pull latest changes"
fi

# Initialize .claude folder if it doesn't exist
echo "🧠 Setting up Claude intelligence folder..."
if [ ! -d ".claude" ]; then
    mkdir -p .claude/daily-updates
    
    # Create initial context files
    cat > .claude/context.md << 'EOF'
# Project Context

**Tech Stack**: React + Vite + TypeScript + Tailwind CSS + Supabase
**Last Updated**: $(date)

## Current Architecture
- Frontend: React SPA with Vite bundling
- Backend: Supabase Edge Functions
- Database: PostgreSQL with RLS policies
- Auth: Supabase Auth
- Styling: Tailwind CSS

## Project Status
- Newly created project
- Ready for development

## Next Steps
- Implement core features based on user requirements
- Set up database schema
- Configure authentication flow
EOF

    cat > .claude/instructions.md << 'EOF'
# Development Instructions

## Code Style Guidelines
- Use TypeScript strict mode
- Tailwind CSS for all styling (avoid custom CSS)
- React functional components with hooks
- Descriptive variable and function names

## React Best Practices
- One component per file
- Use proper TypeScript interfaces for props
- Implement error boundaries for robustness
- Use React.memo for performance optimization

## Supabase Integration
- Always implement Row Level Security (RLS)
- Use edge functions for complex business logic
- Implement real-time subscriptions where appropriate
- Handle authentication states properly

## File Organization
- Components in src/components/
- Pages in src/pages/
- Utilities in src/lib/
- Types in src/types/
- Supabase client in src/lib/supabase.ts
EOF

    cat > .claude/architecture.md << 'EOF'
# Technical Architecture

## Frontend Architecture
- React 18 with TypeScript
- Vite for build tooling and dev server
- Tailwind CSS for styling
- React Router for navigation

## Backend Architecture
- Supabase as Backend-as-a-Service
- PostgreSQL database with RLS
- Edge functions for server-side logic
- Real-time subscriptions for live updates

## Development Workflow
- Hot module replacement via Vite
- TypeScript compilation
- ESLint for code quality
- Prettier for code formatting
EOF

    cat > .claude/todos.md << 'EOF'
# Development TODOs

## Immediate Tasks
- [ ] Set up basic project structure
- [ ] Configure Supabase client
- [ ] Implement authentication flow
- [ ] Create initial database schema

## Future Enhancements
- [ ] Add comprehensive error handling
- [ ] Implement offline support
- [ ] Add comprehensive testing
- [ ] Optimize for performance
EOF

    echo "✅ Created initial Claude context files"
    
    # Commit the .claude folder
    git add .claude/
    git commit -m "Claude: Initialize project intelligence folder" || echo "⚠️  Could not commit .claude folder"
fi

# Install project dependencies if package.json exists
if [ -f "package.json" ]; then
    echo "📦 Installing project dependencies with Bun (super fast!)..."
    bun install
else
    # echo "📦 No package.json found, creating React+Vite+Supabase project with Bun..."
    # # Create a basic React+Vite project structure using Bun
    # bunx create-vite . --template react-ts
    # bun install
    
    # # Add Supabase and common dependencies
    # bun add @supabase/supabase-js @supabase/auth-helpers-react
    # bun add @headlessui/react @heroicons/react
    # bun add react-router-dom @tanstack/react-query
    
    # # Add Tailwind CSS
    # bun add -D tailwindcss postcss autoprefixer
    # bunx tailwindcss init -p
fi

# Start the development servers
echo "🎯 Starting development servers..."

# Start Vite dev server in background using Bun
bun run dev &
VITE_PID=$!

# Start PiloTY MCP server
echo "🤖 Starting PiloTY MCP server..."
python3 /app/claude-integration/claude-context-manager.py &
MCP_PID=$!

# Function to cleanup background processes
cleanup() {
    echo "🛑 Shutting down development environment..."
    kill $VITE_PID 2>/dev/null || true
    kill $MCP_PID 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

echo "✅ Development environment ready!"
echo "🌐 Vite dev server: http://localhost:3000"
echo "🤖 Claude MCP server: http://localhost:8080"
echo ""
echo "Claude can now start building your React+Vite+Supabase application!"

# Wait for background processes
wait 