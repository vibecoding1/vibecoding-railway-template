FROM node:18

# Set working directory
WORKDIR /app

# Update system and install essential tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    nano \
    vim \
    python3 \
    python3-pip \
    postgresql-client \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install global Node.js tools for React+Vite+Supabase stack
RUN npm install -g \
    vite \
    @vitejs/plugin-react \
    typescript \
    supabase \
    tailwindcss \
    eslint \
    prettier \
    @typescript-eslint/parser \
    concurrently

# Install PiloTY MCP and dependencies
RUN pip3 install \
    fastapi \
    uvicorn \
    requests \
    python-multipart

# Note: PiloTY MCP will be installed when available
# For now, we'll use our custom Claude context manager

# Create claude integration directory
RUN mkdir -p /app/claude-integration

# Copy startup scripts and Claude integration
COPY start-dev-environment.sh /start-dev-environment.sh
COPY claude-context-manager.py /app/claude-integration/
RUN chmod +x /start-dev-environment.sh

# Expose ports for Vite dev server and Claude MCP
EXPOSE 3000 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default command
CMD ["/start-dev-environment.sh"] 