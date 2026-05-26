#!/bin/bash
# ============================================================
# Vertex AI Environment — Android AI Workstation
#
# Source this file to route Claude Code API calls through
# Google Cloud Vertex AI (uses your GCP credits).
#
# Usage:
#   source ~/android-cowork/config/vertex_env.sh
#   claude  # Now runs against Vertex AI
# ============================================================

# ── EDIT THESE (required) ─────────────────────────────────────
export ANTHROPIC_VERTEX_PROJECT_ID="YOUR_GCP_PROJECT_ID"
export CLOUD_ML_REGION="us-east5"          # Best Claude on Vertex availability
# ─────────────────────────────────────────────────────────────

# Route Claude Code through Vertex AI
export CLAUDE_CODE_USE_VERTEX=1

# Also configure Python GCP clients (ReasoningBank, GenAI SDK)
export GOOGLE_CLOUD_PROJECT="$ANTHROPIC_VERTEX_PROJECT_ID"
export GOOGLE_CLOUD_LOCATION="$CLOUD_ML_REGION"
export GOOGLE_GENAI_USE_VERTEXAI="True"

# Vertex AI supports these Claude models (as of mid-2025):
#   claude-sonnet-4-5@20251001
#   claude-3-7-sonnet@20250219
#   claude-3-5-haiku@20251022
# Claude Code will auto-select based on your account.

echo "[Vertex AI] Project: $ANTHROPIC_VERTEX_PROJECT_ID  Region: $CLOUD_ML_REGION"
echo "[Vertex AI] CLAUDE_CODE_USE_VERTEX=1 — GCP credits active"
