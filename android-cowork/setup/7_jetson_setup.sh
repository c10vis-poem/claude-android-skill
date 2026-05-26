#!/bin/bash
# Jetson Orin Nano Super — N0.V4 Hub Node Setup
# Run this ON the Jetson (Ubuntu 24.04 / JetPack 6)
# Not a Termux script — standard bash

set -e

echo "=== N0.V4 Hub Node Setup — Jetson Orin Nano Super ==="
echo ""

# --- System update ---
echo "Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# --- Docker with NVIDIA support ---
echo ""
echo "Installing Docker + NVIDIA Container Toolkit..."

if ! command -v docker > /dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  echo "Docker installed. Log out and back in if permission issues."
fi

# NVIDIA Container Toolkit (for CUDA in Docker)
if ! dpkg -l nvidia-container-toolkit > /dev/null 2>&1; then
  distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
  curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
  curl -s -L "https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list" | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update
  sudo apt-get install -y nvidia-container-toolkit
  sudo systemctl restart docker
  echo "NVIDIA Container Toolkit installed"
fi

# Test GPU in Docker
echo ""
echo "Testing CUDA in Docker:"
docker run --rm --gpus all ubuntu nvidia-smi || echo "GPU test failed — check JetPack installation"

# --- Ollama with GPU ---
echo ""
echo "Installing Ollama..."

if ! command -v ollama > /dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi

# Configure Ollama for Jetson GPU
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_NUM_GPU=999"
Environment="CUDA_VISIBLE_DEVICES=0"
EOF
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama

echo "Pulling models for Docker CLI #1 and #2:"
ollama pull llama3:8b
ollama pull mistral:7b

# --- Postgres + pgvector ---
echo ""
echo "Installing Postgres + pgvector..."

docker run -d \
  --name nova-postgres \
  --restart unless-stopped \
  -e POSTGRES_USER=nova \
  -e POSTGRES_PASSWORD=change-this-password \
  -e POSTGRES_DB=nova_brain \
  -p 5432:5432 \
  -v nova-pgdata:/var/lib/postgresql/data \
  pgvector/pgvector:pg16

sleep 5

# Create tables
docker exec -i nova-postgres psql -U nova -d nova_brain << 'SQL'
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS thoughts (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  session_id TEXT,
  content TEXT NOT NULL,
  embedding vector(1536),
  tags TEXT[],
  source TEXT
);

CREATE TABLE IF NOT EXISTS ptl_log (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  session_id TEXT,
  original TEXT,
  cleaned TEXT,
  confidence FLOAT
);

CREATE TABLE IF NOT EXISTS training_pairs (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  prompt TEXT,
  response TEXT,
  approved BOOLEAN DEFAULT FALSE,
  confidence FLOAT
);

CREATE INDEX IF NOT EXISTS thoughts_embedding_idx ON thoughts USING ivfflat (embedding vector_cosine_ops);
SQL

echo "Postgres + pgvector ready at port 5432"

# --- N0.V4 directory structure ---
echo ""
echo "Creating N0.V4 directory structure..."
mkdir -p ~/nova/logs ~/nova/wiki/patterns ~/nova/wiki/entities ~/nova/wiki/synthesis
mkdir -p ~/nova/training/approved ~/nova/training/pending ~/nova/training/rejected
mkdir -p ~/android-cowork/nova

# Copy schema files from Razr sync (if available)
# These will sync from Razr via rsync in log_sync.sh

# --- PTL Server ---
echo ""
echo "Setting up PTL Server..."

pip3 install fastapi uvicorn anthropic asyncpg 2>/dev/null || true

# Create PTL systemd service
sudo tee /etc/systemd/system/nova-ptl.service << 'EOF'
[Unit]
Description=N0.V4 Prompt Translation Layer
After=network.target

[Service]
User=YOUR-USERNAME
WorkingDirectory=/home/YOUR-USERNAME/android-cowork/nova
ExecStart=/usr/bin/python3 ptl_server.py
Restart=always
Environment="PTL_PORT=8080"

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo "Edit /etc/systemd/system/nova-ptl.service — replace YOUR-USERNAME"
echo "Then: sudo systemctl enable nova-ptl && sudo systemctl start nova-ptl"

# --- Summary ---
echo ""
echo "=== Jetson Setup Complete ==="
echo ""
echo "Running services:"
echo "  Ollama (GPU):     http://localhost:11434"
echo "  Postgres:         postgresql://nova:PASSWORD@localhost:5432/nova_brain"
echo "  PTL Server:       http://localhost:8080 (after systemctl start)"
echo ""
echo "Next steps:"
echo "  1. Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
echo "  2. sudo tailscale up"
echo "  3. Get Tailscale IP: tailscale ip -4"
echo "  4. Update routing_rules.json on Razr with Tailscale IP"
echo "  5. Set up SSH key auth from Razr for passwordless log sync"
echo ""
