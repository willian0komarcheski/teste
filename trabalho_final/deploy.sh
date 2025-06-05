#!/bin/bash

# Script para deploy automatizado do sistema de chat com Docker Compose

# Cores para logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para log
log_info() {
    echo -e "${GREEN}[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $(date +'%Y-%m-%d %H:%M:%S') - $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1${NC}"
}

# Verifica se o Docker e Docker Compose estão instalados
log_info "Verificando pré-requisitos (Docker e Docker Compose)..."
if ! command -v docker &> /dev/null; then
    log_error "Docker não encontrado. Por favor, instale o Docker."
    exit 1
fi

# Determina o comando do Docker Compose (v1 ou v2)
COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    log_info "Usando Docker Compose v1 (docker-compose)"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    log_info "Usando Docker Compose v2 (docker compose)"
else
    log_error "Docker Compose (v1 ou v2) não encontrado. Por favor, instale o Docker Compose."
    exit 1
fi

# Navega para o diretório do docker-compose.yml (assumindo que o script está na raiz do projeto)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"
log_info "Executando no diretório: $SCRIPT_DIR"

# Carrega variáveis de ambiente de um arquivo .env, se existir
if [ -f .env ]; then
    log_info "Carregando variáveis de ambiente do arquivo .env"
    set -a
    source .env
    set +a
else
    log_warn "Arquivo .env não encontrado. Usando valores padrão do docker-compose.yml ou variáveis de ambiente existentes."
fi

# Função para verificar a saúde de um container
check_health() {
    local service_name=$1
    local retries=12
    local interval=10
    log_info "Aguardando o serviço '$service_name' ficar saudável..."
    for ((i=1; i<=retries; i++)); do
        health_status=$($COMPOSE_CMD ps -q $service_name | xargs docker inspect --format='{{.State.Health.Status}}' 2>/dev/null)

        if [ "$health_status" == "healthy" ]; then
            log_info "Serviço '$service_name' está saudável."
            return 0
        elif [ "$health_status" == "unhealthy" ]; then
            log_error "Serviço '$service_name' está com status 'unhealthy'. Abortando."
            return 1
        fi
        log_info "Serviço '$service_name' ainda não está saudável (Status: ${health_status:-starting}). Tentativa $i/$retries. Aguardando ${interval}s..."
        sleep $interval
    done
    log_error "Serviço '$service_name' não ficou saudável após $(($retries * $interval)) segundos."
    return 1
}

# Build das imagens
log_info "Iniciando o build das imagens Docker (se necessário)..."
$COMPOSE_CMD build
if [ $? -ne 0 ]; then
    log_error "Falha no build das imagens Docker."
    exit 1
fi
log_info "Build das imagens concluído com sucesso."

# Subir os containers
log_info "Iniciando os containers com '$COMPOSE_CMD up -d'..."
$COMPOSE_CMD up -d
if [ $? -ne 0 ]; then
    log_error "Falha ao iniciar os containers com '$COMPOSE_CMD up -d'."
    exit 1
fi
log_info "Comando '$COMPOSE_CMD up -d' executado. Verificando saúde dos serviços..."

# Verificar saúde
check_health "redis" || exit 1
check_health "db" || exit 1
# check_health "auth-api"
# check_health "record-api"
# check_health "receive-send-api"

log_info "Deploy iniciado. Verificando logs dos containers..."
sleep 5
log_info "Logs recentes dos containers:"
$COMPOSE_CMD logs --tail="20"

log_info "-----------------------------------------------------"
log_info " Sistema de Chat por Microserviços iniciado!         "
log_info "-----------------------------------------------------"
log_info "Endpoints disponíveis (verifique as portas no .env ou docker-compose.yml):"
log_info "- Auth API (PHP):         http://localhost:${AUTH_API_PORT:-8080}"
log_info "- Record API (Python):    http://localhost:${RECORD_API_PORT:-5001}"
log_info "- Receive/Send API (Node):http://localhost:${RECEIVE_SEND_API_PORT:-3000}"
log_info "- Redis:                  localhost:6379"
log_info "- PostgreSQL:             localhost:${DB_PORT:-5432}"
log_info "-----------------------------------------------------"
log_info "Para parar os serviços, execute: '$COMPOSE_CMD down'"
log_info "Para ver os logs em tempo real, execute: '$COMPOSE_CMD logs -f'"
log_info "-----------------------------------------------------"

exit 0
