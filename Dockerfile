FROM node:24-alpine

WORKDIR /app

# Copia definicoes de dependencias primeiro para aproveitar cache de camadas
COPY package*.json ./
RUN npm install --omit=dev

# Copia o codigo-fonte
COPY . .

EXPOSE 3000

CMD ["npm", "start"]
