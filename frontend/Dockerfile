FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
# Usamos directamente el binario de Angular CLI para evitar problemas de permisos con "ng"
RUN node ./node_modules/@angular/cli/bin/ng.js build

FROM nginx:alpine

# Angular 17+ genera dist/login/browser, copiamos esa carpeta como root de Nginx
COPY --from=build /app/dist/login/browser /usr/share/nginx/html

# Configuración personalizada de Nginx para SPA Angular (fallback a index.html)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
