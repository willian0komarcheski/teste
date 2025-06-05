# Dockerfile para Receive-Send-API (Node.js)
FROM node:18-alpine

RUN apk add --no-cache curl

WORKDIR /usr/src/app

# Copia primeiro os arquivos de dependência para aproveitar cache do Docker
COPY package*.json ./

# Instala dependências de produção
RUN npm install --production && \
    npm cache clean --force

# Copia o resto da aplicação
COPY . .

# Expõe a porta e define healthcheck
EXPOSE 3000

# Comando de inicialização
CMD ["npm", "start"]