# 🚀 Ollama Container - Guia de Deploy Multi-Ambiente

Este repositório contém a configuração do container Ollama para deploy em múltiplos ambientes do GCP Cloud Run.

## 📁 Estrutura de Arquivos

```
├── Dockerfile                      # Dockerfile multi-ambiente
├── cloudbuild.yaml                 # Build original (manter para referência)
├── cloudbuild.sandbox.yaml         # Deploy para sandbox
├── cloudbuild.staging.yaml         # Deploy para staging
├── cloudbuild.production.yaml      # Deploy para produção
├── .env                            # Template base (não usar em produção)
├── .env.sandbox                    # Configurações sandbox
├── .env.development                # Configurações development
├── .env.staging                    # Configurações staging
└── .env.production                 # Configurações produção
```

## 🌍 Ambientes

### 1. **Sandbox** (Testes e Desenvolvimento)
- **CPU**: 2 cores
- **Memória**: 4Gi
- **Instâncias**: 0-2
- **Acesso**: Público (para testes)
- **Keep-Alive**: 12h

### 2. **Development** (Desenvolvimento Integrado)
- **CPU**: 2 cores
- **Memória**: 4Gi
- **Instâncias**: 0-3
- **Acesso**: Interno
- **Keep-Alive**: 12h

### 3. **Staging** (Homologação)
- **CPU**: 4 cores
- **Memória**: 8Gi
- **Instâncias**: 0-5
- **Acesso**: Interno (autenticado)
- **Keep-Alive**: 24h

### 4. **Production** (Produção)
- **CPU**: 8 cores
- **Memória**: 16Gi
- **Instâncias**: 1-10
- **Acesso**: Interno (autenticado)
- **Keep-Alive**: 24h
- **Min Instances**: 1 (sempre ativo)

## 🔧 Configuração Inicial

### 1. Atualizar Project IDs nos arquivos .env

Edite cada arquivo `.env.*` e atualize os seguintes valores:

```bash
# .env.sandbox
GCP_PROJECT_ID=seu-projeto-sandbox

# .env.development
GCP_PROJECT_ID=seu-projeto-dev

# .env.staging
GCP_PROJECT_ID=seu-projeto-staging

# .env.production
GCP_PROJECT_ID=seu-projeto-prod
```

### 2. Criar os serviços no Cloud Run (primeira vez)

Para cada ambiente, você precisa criar o serviço inicialmente:

```bash
# Sandbox
gcloud run deploy ollama-service-sandbox \
  --image=gcr.io/YOUR_PROJECT_ID/ollama-custom-sandbox:latest \
  --region=us-east4 \
  --platform=managed \
  --allow-unauthenticated

# Staging
gcloud run deploy ollama-service-staging \
  --image=gcr.io/YOUR_PROJECT_ID/ollama-custom-staging:latest \
  --region=us-east4 \
  --platform=managed \
  --no-allow-unauthenticated

# Production
gcloud run deploy ollama-service \
  --image=gcr.io/YOUR_PROJECT_ID/ollama-custom:latest \
  --region=us-east4 \
  --platform=managed \
  --no-allow-unauthenticated
```

## 🚀 Deploy

### Deploy Manual

#### Sandbox
```bash
gcloud builds submit --config=cloudbuild.sandbox.yaml --project=SEU_PROJECT_ID
```

#### Staging
```bash
gcloud builds submit --config=cloudbuild.staging.yaml --project=SEU_PROJECT_ID
```

#### Production
```bash
gcloud builds submit --config=cloudbuild.production.yaml --project=SEU_PROJECT_ID
```

### Deploy Automático via GitHub/GitLab

Configure triggers no Cloud Build:

1. **Trigger Sandbox**
   - Branch: `develop` ou `sandbox`
   - Config: `cloudbuild.sandbox.yaml`

2. **Trigger Staging**
   - Branch: `staging` ou `homolog`
   - Config: `cloudbuild.staging.yaml`

3. **Trigger Production**
   - Branch: `main` ou tag `v*`
   - Config: `cloudbuild.production.yaml`
   - **Importante**: Configure aprovação manual!

## 🔍 Testando o Serviço

### Health Check
```bash
curl -X GET https://SEU_SERVICE_URL/api/tags
```

### Testando um prompt
```bash
curl -X POST https://SEU_SERVICE_URL/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:4b",
    "prompt": "Olá, como você está?",
    "stream": false
  }'
```

## 📊 Monitoramento

### Ver logs do serviço
```bash
gcloud run services logs read ollama-service-sandbox --region=us-east4
```

### Verificar status do serviço
```bash
gcloud run services describe ollama-service-sandbox --region=us-east4
```

## 🔐 Segurança

- **Sandbox**: Acesso público para testes (usar com cuidado)
- **Staging/Production**: Acesso interno apenas
- **Produção**: Requer autenticação GCP

### Acessar serviço interno
```bash
# Gerar token de autenticação
TOKEN=$(gcloud auth print-identity-token)

# Fazer request autenticado
curl -H "Authorization: Bearer $TOKEN" \
     https://SEU_SERVICE_URL/api/tags
```

## 🛠️ Troubleshooting

### Build está demorando muito
- O download dos modelos pode levar 5-10 minutos
- Verifique timeout do Cloud Build (configurado para 40min)

### Serviço não responde
```bash
# Verificar logs
gcloud run services logs read NOME_DO_SERVICO --region=us-east4

# Verificar variáveis de ambiente
gcloud run services describe NOME_DO_SERVICO --region=us-east4 --format=yaml
```

### Erro de memória
- Aumente a memória no arquivo cloudbuild correspondente
- Modelos maiores precisam de mais RAM

## 📝 Variáveis de Ambiente Importantes

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `OLLAMA_HOST` | Host e porta do servidor | `0.0.0.0:11434` |
| `OLLAMA_KEEP_ALIVE` | Tempo que modelo fica em memória | `24h` |
| `OLLAMA_MAX_LOADED_MODELS` | Máximo de modelos carregados | `1-3` |
| `OLLAMA_NUM_PARALLEL` | Requests paralelas | `1-4` |
| `ENVIRONMENT` | Nome do ambiente | `sandbox/staging/production` |

## 🎯 Próximos Passos

- [ ] Configure alertas no Cloud Monitoring
- [ ] Configure backup dos modelos
- [ ] Implemente rate limiting
- [ ] Configure Auto-scaling baseado em carga
- [ ] Adicione métricas customizadas

## 📚 Documentação Adicional

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)

---

**Mantido por**: BlueRise Team  
**Última atualização**: Janeiro 2026
