FROM ollama/ollama:latest

# 1. Variáveis para o momento do BUILD
ENV OLLAMA_HOST=0.0.0.0:11434

# 2. "Assando" o modelo qwen3:4b na imagem
# Usamos nohup para garantir que o servidor não morra enquanto baixamos
RUN nohup bash -c "ollama serve &" && \
    sleep 10 && \
    echo "🔴 Baixando qwen3:4b (Map/Reduce & Dev)..." && \
    ollama pull qwen3:4b && \
    sleep 5

# 3. Configuração de Runtime (Cloud Run)
ENV OLLAMA_KEEP_ALIVE=24h

# ⚠️ O PULO DO GATO (Mantido do seu original):
# Força o Ollama a escutar na porta injetada pelo Cloud Run
ENTRYPOINT ["/bin/sh", "-c", "export OLLAMA_HOST=0.0.0.0:$PORT && echo '🚀 Ollama iniciando na porta '$PORT && exec ollama serve"]
