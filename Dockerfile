FROM ollama/ollama:latest

# Build Arguments
ARG ENV=development
ARG OLLAMA_MODELS=qwen3:4b

# Labels para identificação
LABEL environment="${ENV}"
LABEL maintainer="BlueRise"
LABEL description="Ollama container customizado para multi-ambientes"

# 1. Variáveis para o momento do BUILD
ENV OLLAMA_HOST=0.0.0.0:11434
ENV ENVIRONMENT=${ENV}

# 2. "Assando" os modelos na imagem
# Usamos nohup para garantir que o servidor não morra enquanto baixamos
RUN bash -c 'nohup ollama serve > /tmp/ollama.log 2>&1 & \
    sleep 10 && \
    echo "🔴 Baixando modelos para ambiente: $ENV..." && \
    IFS="," read -ra MODELS <<< "$OLLAMA_MODELS" && \
    for model in "${MODELS[@]}"; do \
        echo "📦 Baixando modelo: $model" && \
        ollama pull "$model" || exit 1; \
    done && \
    echo "✅ Todos os modelos foram baixados com sucesso!" && \
    sleep 5'

# 3. Configuração de Runtime (Cloud Run)
ENV OLLAMA_KEEP_ALIVE=24h

# 4. Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:11434/api/tags || exit 1

# ⚠️ O PULO DO GATO:
# Força o Ollama a escutar na porta injetada pelo Cloud Run
ENTRYPOINT ["/bin/sh", "-c", "export OLLAMA_HOST=0.0.0.0:${PORT:-11434} && echo '🚀 Ollama iniciando no ambiente: ${ENVIRONMENT}' && echo '🌐 Porta: ${PORT:-11434}' && exec ollama serve"]
