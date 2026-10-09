FROM node:24-alpine

WORKDIR /app

# Copia definicoes de dependencias primeiro para aproveitar cache de camadas
COPY package*.json ./
RUN npm ci --omit=dev

# Copia o codigo-fonte com permissoes adequadas
COPY --chown=node:node . .

# Execucao com usuario nao-root para menor privilegio
USER node

EXPOSE 3000

# Executa o processo Node diretamente para repasse correto de sinais POSIX (SIGTERM)
CMD ["node", "src/server.js"]

