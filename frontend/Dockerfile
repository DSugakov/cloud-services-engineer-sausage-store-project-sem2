# Stage 1: build Angular app
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --no-fund
COPY . .
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build -- --configuration production

# Stage 2: serve with nginx
FROM nginx:1.25-alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=builder /app/dist/frontend/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx","-g","daemon off;"]

