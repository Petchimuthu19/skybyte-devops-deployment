#!/bin/bash
set -euo pipefail   # ✅ Exit on error, unset vars, pipe failures

# ─── Config ───────────────────────────────────────────
IMAGE_TAG=$(git rev-parse --short HEAD)   # ✅ Immutable tag from git SHA
IMAGE_NAME="skybyte/app"

echo "==> Building Docker image (tag: ${IMAGE_TAG})"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .   # ✅ No more :latest

echo "==> Applying Terraform"
cd terraform
terraform init -reconfigure               # ✅ Safe for repeated runs
terraform plan -out=tfplan                # ✅ Preview before applying
terraform apply tfplan                    # ✅ Apply only the reviewed plan
cd ..

echo "==> Installing/Upgrading Helm chart"
helm upgrade --install skybyte-app helm/skybyte-app \
  --namespace devops-challenge \
  --create-namespace \                    # ✅ Create namespace if missing
  --set image.tag="${IMAGE_TAG}" \        # ✅ Pass immutable image tag
  --wait \                                # ✅ Wait for pods to be ready
  --timeout 120s

echo "==> Done. Image: ${IMAGE_NAME}:${IMAGE_TAG}"
