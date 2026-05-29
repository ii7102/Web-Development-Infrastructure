FROM node:26-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM nginx:stable-alpine

# Vite outputs to dist/ -- change to /app/build if you use Create React App.
COPY --from=build /app/dist /usr/share/nginx/html

# SPA routing + cache rules.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Runtime env injection: generates /config.js from container env vars on start.
# The official nginx image runs every *.sh in /docker-entrypoint.d/ before
# starting nginx, so we hook in there and keep the image's default CMD.
COPY docker-entrypoint.sh /docker-entrypoint.d/40-app-config.sh
RUN chmod +x /docker-entrypoint.d/40-app-config.sh

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
