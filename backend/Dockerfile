
FROM node:20

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

# Create a non-root user and switch to it
RUN useradd --create-home appuser
USER appuser

EXPOSE 3003

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3003/health || exit 1

CMD ["node","server.js"]
