FROM node:20 AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*
COPY . .
RUN corepack enable && yarn install --frozen-lockfile --ignore-scripts
RUN yarn nx build @aws/threat-composer-app --verbose
FROM nginx:alpine
COPY --from=builder /app/packages/threat-composer-app/build/website /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
