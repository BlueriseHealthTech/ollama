# 🔧 Troubleshooting - Ollama Cloud Run

## ❌ Problema Identificado: Não consegue executar chamadas ao Ollama

### 🔍 Diagnóstico Completo

#### **Problema 1: Conflito de Variável OLLAMA_HOST**
```yaml
# ❌ ERRADO - Forçando valor no YAML
env:
- name: OLLAMA_HOST
  value: 0.0.0.0:8080
```

**Causa:** O Cloud Run injeta automaticamente a variável `PORT` (geralmente 8080), e o Dockerfile já está configurado para usar essa variável. Quando você força `OLLAMA_HOST` no YAML, está sobrescrevendo essa configuração inteligente.

**Solução:** **REMOVA** a variável `OLLAMA_HOST` do YAML do Cloud Run. Deixe o Dockerfile gerenciar isso.

---

#### **Problema 2: Startup Probe Agressivo**
```yaml
# ❌ ERRADO
startupProbe:
  timeoutSeconds: 240
  periodSeconds: 240
  failureThreshold: 1  # Falha após 1 tentativa!
```

**Causa:** O Ollama demora para carregar modelos grandes. Com `failureThreshold: 1`, se o serviço não responder em 4 minutos, ele já é considerado falho e reiniciado.

**Solução:** Aumentar o `failureThreshold` e reduzir o `periodSeconds`:

```yaml
# ✅ CORRETO
startupProbe:
  timeoutSeconds: 10
  periodSeconds: 10
  failureThreshold: 30  # 30 tentativas = 5 minutos total
  httpGet:
    path: /api/tags
    port: 8080
```

---

#### **Problema 3: Health Check com Porta Fixa**
No Dockerfile original:
```dockerfile
# ❌ ERRADO - Porta hardcoded
HEALTHCHECK CMD curl -f http://localhost:11434/api/tags
```

**Solução:** Usar a variável `PORT`:
```dockerfile
# ✅ CORRETO - Usa a PORT do Cloud Run
HEALTHCHECK CMD curl -f http://localhost:${PORT:-11434}/api/tags
```

---

## 🚀 Como Resolver

### **Opção 1: Redeploy com Script Automatizado (RECOMENDADO)**

```bash
# Tornar o script executável (se ainda não fez)
chmod +x redeploy-fix.sh

# Fazer redeploy no ambiente de desenvolvimento
./redeploy-fix.sh sandbox
```

O script irá:
1. ✅ Remover a variável `OLLAMA_HOST` conflitante
2. ✅ Configurar a porta correta (8080)
3. ✅ Ajustar o timeout e concurrency
4. ✅ Testar a conectividade automaticamente

---

### **Opção 2: Atualizar Manualmente via gcloud**

```bash
gcloud run deploy brh-ollama-dev \
  --project=brh-dev-469211 \
  --region=us-east4 \
  --image=us-east4-docker.pkg.dev/brh-dev-469211/cloud-run-source-deploy/brh-ollama-dev/brh-ollama-dev:latest \
  --platform=managed \
  --cpu=6 \
  --memory=16Gi \
  --no-cpu-throttling \
  --min-instances=1 \
  --max-instances=3 \
  --timeout=600s \
  --concurrency=80 \
  --port=8080 \
  --set-env-vars="ENVIRONMENT=sandbox,OLLAMA_KEEP_ALIVE=12h" \
  --allow-unauthenticated
```

**IMPORTANTE:** Note que **NÃO** estamos definindo `OLLAMA_HOST` aqui!

---

### **Opção 3: Editar YAML Manualmente**

Se você precisa editar o YAML diretamente no Console do GCP:

1. Vá para Cloud Run > brh-ollama-dev > EDITAR E IMPLANTAR NOVA REVISÃO

2. **REMOVA** estas linhas da seção `env`:
```yaml
# ❌ REMOVER ISTO
- name: OLLAMA_HOST
  value: 0.0.0.0:8080
```

3. Na seção de **Startup Probe**, altere para:
```yaml
startupProbe:
  timeoutSeconds: 10
  periodSeconds: 10
  failureThreshold: 30
  httpGet:
    path: /api/tags
    port: 8080
```

4. Verifique se a porta do container está definida como **8080**:
```yaml
ports:
- name: http1
  containerPort: 8080
```

5. Clique em **IMPLANTAR**

---

## 🧪 Como Testar

### 1. Verificar Logs
```bash
gcloud run services logs tail brh-ollama-dev \
  --project=brh-dev-469211 \
  --region=us-east4
```

**Busque por:**
- ✅ `🚀 Ollama iniciando no ambiente: sandbox`
- ✅ `🌐 Porta: 8080`
- ✅ `📡 OLLAMA_HOST: 0.0.0.0:8080`
- ❌ Erros de conexão ou "connection refused"

### 2. Testar API de Tags (Lista Modelos)
```bash
# Obter token de autenticação
TOKEN=$(gcloud auth print-identity-token)

# Testar endpoint
curl -X GET https://brh-ollama-dev-st6yfcc7kq-uk.a.run.app/api/tags \
  -H "Authorization: Bearer $TOKEN"
```

**Resposta esperada:**
```json
{
  "models": [
    {
      "name": "qwen3:4b",
      "modified_at": "2025-01-21T...",
      "size": 4566948864,
      ...
    }
  ]
}
```

### 3. Testar Geração de Texto
```bash
curl -X POST https://brh-ollama-dev-st6yfcc7kq-uk.a.run.app/api/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:4b",
    "prompt": "Por que o céu é azul?",
    "stream": false
  }'
```

---

## 📊 Verificar Status do Serviço

```bash
gcloud run services describe brh-ollama-dev \
  --project=brh-dev-469211 \
  --region=us-east4 \
  --format=yaml | grep -A 10 "status:"
```

**Procure por:**
- `status: 'True'` em todas as condições (Ready, ConfigurationsReady, RoutesReady)
- Nome da revisão mais recente

---

## 🔄 Rebuild Completo (Se Necessário)

Se os problemas persistirem, faça um rebuild completo:

```bash
# 1. Rebuild da imagem com as correções
gcloud builds submit --config=cloudbuild.sandbox.yaml \
  --project=brh-dev-469211

# 2. Aguardar build concluir (pode demorar 10-15 minutos)

# 3. Verificar logs do build
gcloud builds log $(gcloud builds list --limit=1 --format='value(id)')

# 4. Testar novamente
./redeploy-fix.sh sandbox
```

---

## ❓ FAQ

### **P: Por que não posso definir OLLAMA_HOST no YAML?**
R: O Cloud Run injeta a variável `PORT` dinamicamente. O Dockerfile já está configurado para usar essa porta via `OLLAMA_HOST=0.0.0.0:${PORT}`. Quando você força um valor no YAML, cria um conflito.

### **P: O serviço demora muito para ficar pronto (mais de 5 minutos)**
R: O Ollama pode demorar para carregar modelos grandes (especialmente qwen3:4b). Isso é normal na primeira inicialização. Use `--min-instances=1` para manter uma instância sempre ativa.

### **P: Erro "connection refused" nos logs**
R: Provavelmente o Ollama está tentando escutar na porta errada. Verifique se você **removeu** a variável `OLLAMA_HOST` do YAML.

### **P: Erro 503 Service Unavailable**
R: O serviço ainda está inicializando. Aguarde 2-3 minutos e tente novamente. Verifique os logs para acompanhar o progresso.

### **P: Como saber se o modelo foi carregado corretamente?**
R: Use o endpoint `/api/tags` para listar os modelos disponíveis. Se `qwen3:4b` aparecer, o modelo foi carregado com sucesso.

---

## 📞 Suporte Adicional

Se os problemas persistirem:

1. Execute: `./redeploy-fix.sh sandbox`
2. Capture os logs: `gcloud run services logs tail brh-ollama-dev --project=brh-dev-469211 > logs.txt`
3. Teste o endpoint: `curl -v https://brh-ollama-dev-st6yfcc7kq-uk.a.run.app/api/tags`
4. Compartilhe os logs e a saída do curl para análise
