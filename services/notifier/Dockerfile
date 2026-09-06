FROM node:22-slim AS builder

WORKDIR /build
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

# --- runtime stage ---
FROM node:22-slim

RUN useradd --create-home appuser

WORKDIR /app
COPY --from=builder /build/node_modules ./node_modules
COPY package.json .
COPY src/ ./src/
COPY index.js .

USER appuser
EXPOSE 9200

CMD ["node", "index.js"]