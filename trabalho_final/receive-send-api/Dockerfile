# Dockerfile para Receive-Send-API (Node.js)
FROM node:18-alpine

# Cria usuário não-root para segurança
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src/app

# Copia primeiro os arquivos de dependência para aproveitar cache do Docker
COPY package*.json ./

# Instala dependências de produção
RUN npm install --production && \
    npm cache clean --force

# Copia o resto da aplicação
COPY . .

# Muda para usuário não-root
USER appuser

# Expõe a porta e define healthcheck
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1

# Comando de inicialização
CMD ["npm", "start"]