FROM node:24-alpine

WORKDIR /app

# Copia definições de dependências primeiro para aproveitar o cache de camadas
COPY package*.json ./
RUN npm ci --omit=dev

# Copia o código-fonte com permissões adequadas
COPY --chown=node:node . .

# Execução com usuário não-root para menor privilégio
USER node

EXPOSE 3000

# Executa o processo Node diretamente para repasse correto de sinais POSIX (SIGTERM)
CMD ["node", "src/server.js"]
