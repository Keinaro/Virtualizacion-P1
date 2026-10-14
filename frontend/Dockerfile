# ETAPA 1: Compilar la aplicación Vue
FROM node:20-alpine AS build

WORKDIR /app

# Copiar e instalar dependencias
COPY package*.json ./
RUN npm ci

# Copiar código y compilar
COPY . .
RUN npm run build

# ETAPA 2: Servir la aplicación con nginx
FROM nginx:1.27-alpine

# Configuración de nginx para Vue
COPY nginx-spa.conf /etc/nginx/conf.d/default.conf

# Copiar archivos compilados
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80