# Create docker network if not exist
echo "Creating docker network"
docker network create agfish-network || true

# Removing old container
echo "Removing old container"
docker stop oceanhunter-kong-gateway
docker rm oceanhunter-kong-gateway
docker rmi INSERT_ECR_REPO_NAME:latest

# Pulling ECR image
echo "Pulling ECR image"
aws ecr get-login-password --region INSERT_AWS_REGION | docker login --username AWS --password-stdin INSERT_AWS_ACCOUNT_ID.dkr.ecr.INSERT_AWS_REGION.amazonaws.com
docker pull INSERT_ECR_REPO_NAME:latest

# Building container
echo "Building docker container"
# cd INSERT_SOURCE_FILE_DESTINATION && docker compose -f docker-compose.yml up -d
docker run -d --name INSERT_SERVICE_NAME --add-host host.docker.internal:host-gateway  --ulimit nofile=32768:65536 \
    -p INSERT_MAIN_HTTP_PORT:INSERT_MAIN_HTTP_PORT -p INSERT_MAIN_HTTPS_PORT:INSERT_MAIN_HTTPS_PORT -p INSERT_API_HTTP_PORT:INSERT_API_HTTP_PORT \
    -p INSERT_API_HTTPS_PORT:INSERT_API_HTTPS_PORT -p INSERT_KONG_GATEWAY_HTTP_PORT:INSERT_KONG_GATEWAY_HTTP_PORT -p INSERT_KONG_GATEWAY_HTTPS_PORT:INSERT_KONG_GATEWAY_HTTPS_PORT \
    -e KONG_DATABASE=postgres \
    -e KONG_PROXY_LISTEN="0.0.0.0:INSERT_MAIN_HTTP_PORT, 0.0.0.0:INSERT_MAIN_HTTPS_PORT ssl" \
    -e KONG_ADMIN_LISTEN="0.0.0.0:INSERT_API_HTTP_PORT, 0.0.0.0:INSERT_API_HTTPS_PORT ssl" \
    -e KONG_ADMIN_GUI_LISTEN="0.0.0.0:INSERT_KONG_GATEWAY_HTTP_PORT, 0.0.0.0:INSERT_KONG_GATEWAY_HTTPS_PORT ssl" \
    -e KONG_ADMIN_GUI_URL="https://INSERT_KONG_DASHBOARD_ENDPOINT" \
    -e KONG_ADMIN_GUI_AUTH="basic-auth" \
    -e KONG_ENFORCE_RBAC=on \
    -e KONG_PG_HOST=INSERT_POSTGRE_KONG_GATEWAY_HOST \
    -e KONG_PG_USER=INSERT_POSTGRE_KONG_GATEWAY_USERNAME \
    -e KONG_PG_PASSWORD=INSERT_POSTGRE_KONG_GATEWAY_PASSWORD \
    -e KONG_PG_PORT=INSERT_POSTGRE_KONG_GATEWAY_PORT \
    -e KONG_PG_SSL=on \
    -e KONG_PLUGINS="bundled,auth_sign" \
    -e KONG_PLUGINS_DIR="/usr/local/share/lua/5.1/kong/plugins" \
    INSERT_IMAGE_NAME:INSERT_IMAGE_TAG
    # INSERT_IMAGE_NAME:INSERT_IMAGE_TAG kong migrations bootstrap
docker network connect agfish-network oceanhunter-kong-gateway