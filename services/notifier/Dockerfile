FROM node:22-slim AS builder

WORKDIR /build
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

# --- runtime stage ---
FROM gcr.io/distroless/nodejs22-debian12

# --- runtime stage ---
# FROM node:22-slim


# # Remove npm's own bundled tooling — it's not needed at runtime, and it
# # ships its own dependency tree (pacote, sigstore, etc.) that otherwise
# # gets flagged by container scanners despite being unrelated to this app.
# RUN rm -rf /usr/local/lib/node_modules/npm \
#            /usr/local/bin/npm \
#            /usr/local/bin/npx \
#            /usr/local/bin/corepack

           
# RUN useradd --create-home appuser

WORKDIR /app
COPY --from=builder /build/node_modules ./node_modules
COPY package.json .
COPY src/ ./src/
COPY index.js .

#USER appuser
USER nonroot
EXPOSE 9200

CMD ["index.js"]