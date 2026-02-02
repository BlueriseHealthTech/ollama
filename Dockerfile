FROM ollama/ollama:latest

# --- 1. O SEGREDO DA PERSISTÊNCIA ---
# Alteramos o local onde os modelos são salvos para uma pasta que NÃO é um Volume.
# O padrão (/root/.ollama) é deletado após o build. Este novo caminho (/models) será salvo.
ENV OLLAMA_MODELS="/models"

# Cria a pasta e dá permissão
RUN mkdir -p /models && chmod 777 /models

# Argumentos de Build
ARG ENV=development
ARG MODELS_LIST="qwen3:4b" 
# Nota: qwen3 ainda não é oficial na library padrão, ajustei para qwen2.5 ou use o nome exato se for custom

LABEL environment="${ENV}"

# --- 2. BAIXANDO OS MODELOS (COOKING) ---
# Iniciamos o servidor em background, esperamos ele subir, baixamos e depois matamos o processo.
RUN bash -c 'nohup ollama serve > /dev/null 2>&1 & \
    PID=$! && \
    sleep 5 && \
    echo "🔴 Iniciando download dos modelos em $OLLAMA_MODELS..." && \
    ollama pull '"$MODELS_LIST"' && \
    echo "✅ Download concluído!" && \
    kill $PID'

# --- 3. CONFIGURAÇÃO DE RUNTIME ---
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_KEEP_ALIVE=24h

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:11434/api/tags || exit 1

# Entrypoint - OLLAMA_MODELS já está setado lá em cima, então ele vai achar os arquivos.
ENTRYPOINT ["/bin/sh", "-c", "export OLLAMA_HOST=0.0.0.0:${PORT:-11434} && exec ollama serve"]