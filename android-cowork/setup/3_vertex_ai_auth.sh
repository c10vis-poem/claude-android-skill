#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# Android AI Workstation — Step 3: Vertex AI Authentication
# Routes Claude Code API calls through your GCP credits.
# ============================================================
set -euo pipefail

VERTEX_ENV="$HOME/android-cowork/config/vertex_env.sh"

echo "==> Installing Google Cloud SDK in Termux..."
pkg install -y google-cloud-sdk 2>/dev/null || {
  # Fallback: manual install of gcloud via pip
  pip install google-cloud-aiplatform google-auth google-auth-oauthlib
  # Note: full gcloud CLI may need manual download for Android
  echo "   Installed Python GCP libraries; for full gcloud CLI see:"
  echo "   https://cloud.google.com/sdk/docs/install"
}

echo ""
echo "==> You will now authenticate with Google Cloud."
echo "    This opens a browser for OAuth. Copy the code back to Termux."
echo ""
python3 - << 'PYEOF'
import subprocess, sys
try:
    result = subprocess.run(
        ["gcloud", "auth", "application-default", "login", "--no-launch-browser"],
        check=False
    )
except FileNotFoundError:
    print("gcloud not found — using Python ADC flow instead")
    try:
        from google.oauth2 import service_account
        from google.auth import default
        creds, proj = default()
        print(f"ADC already configured for project: {proj}")
    except Exception as e:
        print(f"Please authenticate manually: gcloud auth application-default login")
        print(f"Error: {e}")
PYEOF

echo ""
echo "==> Writing Vertex AI environment config..."
cat > "$VERTEX_ENV" << 'ENVEOF'
#!/bin/bash
# Vertex AI configuration — edit PROJECT_ID and REGION for your setup
# Source this before running Claude Code to use GCP credits:
#   source ~/android-cowork/config/vertex_env.sh

# ---- EDIT THESE ----
export ANTHROPIC_VERTEX_PROJECT_ID="YOUR_GCP_PROJECT_ID"
export CLOUD_ML_REGION="us-east5"          # Best Claude availability
# --------------------

# Route Claude Code through Vertex AI
export CLAUDE_CODE_USE_VERTEX=1

# Also configure for ReasoningBank / Gemini on Vertex
export GOOGLE_CLOUD_PROJECT="$ANTHROPIC_VERTEX_PROJECT_ID"
export GOOGLE_CLOUD_LOCATION="$CLOUD_ML_REGION"
export GOOGLE_GENAI_USE_VERTEXAI="True"

echo "Vertex AI active: project=$ANTHROPIC_VERTEX_PROJECT_ID region=$CLOUD_ML_REGION"
ENVEOF

chmod +x "$VERTEX_ENV"

echo "==> Adding Vertex auto-source option to .bashrc..."
grep -q 'vertex_env.sh' "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" << 'BRCEOF'

# Uncomment to always use Vertex AI (GCP credits):
# source ~/android-cowork/config/vertex_env.sh
BRCEOF

echo ""
echo "==> Step 3 complete!"
echo ""
echo "    IMPORTANT: Edit vertex_env.sh with your actual GCP project ID:"
echo "    nano $VERTEX_ENV"
echo ""
echo "    Then activate for a session:"
echo "    source $VERTEX_ENV"
echo ""
echo "    Next: bash ~/android-cowork/setup/4_voice_setup.sh"
