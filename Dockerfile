FROM INSERT_BASE_IMAGE
WORKDIR /app
COPY package.json ./
RUN apk update && apk add curl && npm install -g pnpm@latest-8 && pnpm install
COPY . .
RUN pnpm build
EXPOSE 4242
CMD ["sh", "-c", "pnpm serve --host 0.0.0.0 --port 4242"]