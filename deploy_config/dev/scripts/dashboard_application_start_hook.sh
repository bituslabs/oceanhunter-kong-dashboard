# Create docker network if not exist
echo "Creating docker network"
docker network create agfish-network || true

# Removing old container
echo "Removing old container"
docker stop common-kong-dashboard
docker rm common-kong-dashboard
docker rmi INSERT_ECR_REPO_NAME:latest

# Pulling ECR image
echo "Pulling ECR image"
aws ecr get-login-password --region INSERT_AWS_REGION | docker login --username AWS --password-stdin INSERT_AWS_ACCOUNT_ID.dkr.ecr.INSERT_AWS_REGION.amazonaws.com
docker pull INSERT_ECR_REPO_NAME:latest

# Building container
echo "Building docker container"
cd INSERT_SOURCE_FILE_DESTINATION && docker compose -f docker-compose.yml up -d
docker network connect agfish-network common-kong-dashboard