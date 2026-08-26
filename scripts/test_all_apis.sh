#!/bin/bash
# =========================================================
# MahalFlow Automated API Test & Model Validation Runner (Bash)
# =========================================================

echo "=================================================================="
echo "🚀 Running MahalFlow Full Backend API Test Suite"
echo "=================================================================="

cd "$(dirname "$0")/../backend-go" || exit 1
go run cmd/test-api/main.go
