#!/data/data/com.termux/files/usr/bin/bash
# Install and configure local 4B model on Razr Ultra 25
# Uses llama.cpp with Vulkan acceleration (Snapdragon 8 Elite GPU)
# Vulkan is more accessible than QNN SDK in Termux

set -e

MODEL_DIR="$HOME/models"
MODEL_NAME="${EDGE_MODEL:-qwen2.5-4b-instruct-q4_k_m.gguf}"

echo "=== Omni Neural / Local Edge Model Setup ==="
echo "Device: Razr Ultra 25 (Snapdragon 8 Elite)"
echo ""

# --- Option A: Ollama (easiest, recommended first) ---
echo "Option A: Install Ollama (easier, uses Vulkan automatically)"
echo ""

if ! command -v ollama > /dev/null 2>&1; then
  # Ollama for Android/Termux
  pkg install golang -y 2>/dev/null || true
  
  # Try pre-built binary approach
  OLLAMA_VERSION="0.9.0"
  ARCH=$(uname -m)
  
  if [ "$ARCH" = "aarch64" ]; then
    echo "Downloading Ollama for ARM64..."
    curl -fsSL -o /tmp/ollama "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-arm64"
    chmod +x /tmp/ollama
    mv /tmp/ollama "$PREFIX/bin/ollama"
    echo "Ollama installed"
  else
    echo "Architecture $ARCH not directly supported. Try building from source."
  fi
else
  echo "Ollama already installed: $(ollama --version)"
fi

# Start Ollama server
if command -v ollama > /dev/null 2>&1; then
  echo ""
  echo "Starting Ollama server..."
  ollama serve &
  sleep 3
  
  echo ""
  echo "Pulling a 4B model (Qwen2.5 4B — fast, capable):"
  echo ""
  echo "  ollama pull qwen2.5:4b"
  echo ""
  echo "Or pull your preferred 4B model:"
  echo ""
  echo "  ollama pull phi4-mini"
  echo "  ollama pull gemma3:4b"
  echo "  ollama pull llama3.2:3b"
  echo ""
  echo "After pulling, test with:"
  echo ""
  echo "  ollama run qwen2.5:4b \"Hello, are you running locally?\""
  echo ""
fi

# --- Option B: llama.cpp with Vulkan (more NPU-direct, more complex) ---
echo "Option B: llama.cpp with Vulkan (skip if Ollama works)"
echo ""

build_llamacpp() {
  if [ -d "$HOME/llama.cpp" ]; then
    echo "llama.cpp already cloned"
    cd "$HOME/llama.cpp" && git pull
  else
    git clone https://github.com/ggml-org/llama.cpp.git "$HOME/llama.cpp"
    cd "$HOME/llama.cpp"
  fi
  
  pkg install vulkan-tools vulkan-headers -y 2>/dev/null || true
  
  cmake -B build \
    -DGGML_VULKAN=ON \
    -DGGML_NATIVE=ON \
    -DCMAKE_BUILD_TYPE=Release
  
  cmake --build build --config Release -j$(nproc)
  echo "llama.cpp built with Vulkan support"
  echo "Binary: $HOME/llama.cpp/build/bin/llama-server"
}

# Uncomment to build llama.cpp:
# build_llamacpp

# --- Model directory setup ---
mkdir -p "$MODEL_DIR"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your local model endpoint: http://localhost:11434"
echo "This is your Edge endpoint in Horizons UI."
echo ""
echo "To add to routing_rules.json as 'omni-neural-4b':"
echo "  The endpoint URL is already configured."
echo "  Just update the model name to match what you pulled."
echo ""
echo "To make it start automatically:"
echo ""
echo "  echo 'ollama serve &' >> ~/.bashrc"
