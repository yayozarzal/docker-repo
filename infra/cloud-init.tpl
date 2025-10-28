#cloud-config
package_update: true
package_upgrade: false
runcmd:
  - |
    set -e
    # Instalar Docker & Compose plugin
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl restart docker

    # Carpeta deploy
    mkdir -p /opt/app
    cat >/opt/app/docker-compose.yml <<'COMPOSE'
    version: '3.8'
    services:
      backend:
        image: groverdz/task-api-backend:latest
        container_name: task-api-backend
        environment:
          - PORT=3000
        ports:
          - "3000:3000"
        restart: unless-stopped
        healthcheck:
          test: ["CMD", "wget", "-qO-", "http://localhost:3000/api/health"]
          interval: 10s
          timeout: 3s
          retries: 5

      frontend:
        image: groverdz/task-app-frontend:latest
        container_name: task-app-frontend
        depends_on:
          backend:
            condition: service_healthy
        ports:
          - "80:80"
        restart: unless-stopped
    COMPOSE

    cd /opt/app
    docker compose pull
    docker compose up -d

    # Abrir puertos con UFW si estuviera habilitado (generalmente no lo está)
    if command -v ufw >/dev/null 2>&1; then
      ufw allow 22 || true
      ufw allow 80 || true
      ufw allow 3000 || true
      ufw reload || true
    fi
