#!/bin/bash

# 🚨 Script de Redeploy Corrigido - Ollama Cloud Run
# Corrige os problemas de porta e variáveis de ambiente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔧 Redeploy Corrigido - Ollama Cloud Run${NC}"
echo ""

# Verificar argumentos
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Erro: Especifique o ambiente: developer, staging ou production${NC}"
    echo "Uso: ./redeploy-fix.sh [developer|staging|production]"
    exit 1
fi

ENV=$1

# Configurações por ambiente
case $ENV in
    developer|dev)
        SERVICE_NAME="brh-ollama-dev"
        PROJECT_ID="brh-dev-469211"
        REGION="us-east4"
        CPU="2"
        MEMORY="4Gi"
        MIN_INSTANCES="1"
        MAX_INSTANCES="3"
        KEEP_ALIVE="12h"
        AUTH="--allow-unauthenticated"
        ;;
    staging)
        SERVICE_NAME="ollama-service-staging"
        PROJECT_ID="your-staging-project-id"
        REGION="us-east4"
        CPU="4"
        MEMORY="8Gi"
        MIN_INSTANCES="0"
        MAX_INSTANCES="5"
        KEEP_ALIVE="24h"
        AUTH="--no-allow-unauthenticated"
        ;;
    production)
        SERVICE_NAME="ollama-service"
        PROJECT_ID="your-production-project-id"
        REGION="us-east4"
        CPU="8"
        MEMORY="16Gi"
        MIN_INSTANCES="1"
        MAX_INSTANCES="10"
        KEEP_ALIVE="24h"
        AUTH="--no-allow-unauthenticated"
        ;;
    *)
        echo -e "${RED}❌ Ambiente inválido: $ENV${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}📦 Ambiente: $ENV${NC}"
echo -e "${GREEN}🔧 Serviço: $SERVICE_NAME${NC}"
echo -e "${GREEN}🌍 Projeto: $PROJECT_ID${NC}"
echo ""

# Fazer o deploy com as configurações corretas
echo -e "${YELLOW}🚀 Iniciando deploy...${NC}"

gcloud run deploy $SERVICE_NAME \
    --project=$PROJECT_ID \
    --region=$REGION \
    --image=us-east4-docker.pkg.dev/$PROJECT_ID/cloud-run-source-deploy/$SERVICE_NAME/$SERVICE_NAME:latest \
    --platform=managed \
    --cpu=$CPU \
    --memory=$MEMORY \
    --no-cpu-throttling \
    --min-instances=$MIN_INSTANCES \
    --max-instances=$MAX_INSTANCES \
    --timeout=600s \
    --concurrency=80 \
    --port=8080 \
    --set-env-vars="ENVIRONMENT=$ENV,OLLAMA_KEEP_ALIVE=$KEEP_ALIVE" \
    $AUTH

echo ""
echo -e "${GREEN}✅ Deploy completado!${NC}"
echo ""

# Obter URL do serviço
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --project=$PROJECT_ID \
    --region=$REGION \
    --format='value(status.url)')

echo -e "${GREEN}🌐 URL do serviço: $SERVICE_URL${NC}"
echo ""

# Aguardar serviço ficar pronto
echo -e "${YELLOW}⏳ Aguardando serviço ficar pronto (pode levar até 2 minutos)...${NC}"
sleep 30

# Testar o serviço
echo -e "${YELLOW}🧪 Testando conectividade...${NC}"

# Teste 1: API tags (lista modelos)
echo -e "${YELLOW}📋 Teste 1: Listando modelos disponíveis...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$SERVICE_URL/api/tags" \
    -H "Authorization: Bearer $(gcloud auth print-identity-token)")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Serviço respondendo corretamente!${NC}"
    echo "Modelos disponíveis:"
    echo "$BODY" | jq -r '.models[].name' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ Erro: HTTP $HTTP_CODE${NC}"
    echo "$BODY"
fi

echo ""
echo -e "${GREEN}🎉 Redeploy concluído!${NC}"
echo ""
echo -e "${YELLOW}📝 Comandos úteis:${NC}"
echo "  - Ver logs: gcloud run services logs tail $SERVICE_NAME --project=$PROJECT_ID"
echo "  - Testar API: curl $SERVICE_URL/api/tags -H \"Authorization: Bearer \$(gcloud auth print-identity-token)\""
echo ""
