# ============================================================
# Área 2 + 6 — Gateway nginx con el build de producción de Vue
# Contexto de build: raíz del repo (ver docker-compose.yml)
# ============================================================

# ---------- Etapa 1: build del frontend ----------
FROM node:20-alpine AS build-frontend
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ---------- Etapa 2: nginx sirviendo el estático ----------
FROM nginx:1.27-alpine
COPY gateway/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-frontend /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
