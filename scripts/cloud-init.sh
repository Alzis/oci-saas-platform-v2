#!/bin/bash
set -e

# 1. Evita que o Ubuntu abra janelas interativas durante o apt upgrade
export DEBIAN_FRONTEND=noninteractive

# Log everything to a file
exec > >(tee /var/log/cloud-init-output.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "--- Starting Cloud-Init Script ---"

echo "--- Forcing apt to use IPv4 ---"
echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4

# 2. Update e Upgrade com flags que forçam o uso das configurações atuais (sem travar)
apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# 3. Instalação de ferramentas básicas
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

# --- Restante do seu script de Docker ---
echo "--- Installing Docker ---"
# Use /etc/apt/keyrings (padrão moderno do Docker) para evitar avisos de segurança
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# 3. Install Docker Compose v2
echo "--- Installing Docker Compose ---"
DOCKER_COMPOSE_VERSION="v2.24.6" # Use a specific version for stability
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Verify installations
docker --version
docker compose version

# 4. Setup Application Directory
echo "--- Setting up application directory ---"
APP_DIR="/opt/saas-platform"
REPO_URL="https://github.com/Alzis/oci-saas-platform-v2.git" # <-- CHANGE THIS

mkdir -p ${APP_DIR}
chown -R ubuntu:ubuntu ${APP_DIR}

# We will clone the repo as the 'ubuntu' user during the first deploy
# For now, the directory is ready.

# 5. Enable Docker to start on boot
systemctl enable docker

echo "--- Cloud-Init Script Finished Successfully ---"

# The deployment itself (cloning the repo and running docker compose)
# will be handled by the GitHub Actions pipeline.