FROM ollama/ollama:latest

# 1. Variáveis para o momento do BUILD (para o servidor subir localmente e baixar os modelos)
ENV OLLAMA_HOST=0.0.0.0:11434

# 2. "Assando" os modelos na imagem
# O 'nohup' garante que o processo não morra prematuramente.
RUN nohup bash -c "ollama serve &" && \
    sleep 10 && \
    echo "🔴 Baixando Modelo Primário..." && \
    ollama pull qwen2.5:7b-instruct-q4_k_m && \
    echo "🔵 Baixando Modelo Fallback..." && \
    ollama pull qwen2.5:7b-instruct-q5_k_m

# 3. Configuração de Runtime (Cloud Run)
ENV OLLAMA_KEEP_ALIVE=24h

# ⚠️ O PULO DO GATO:
# O Cloud Run passa a porta na variável $PORT.
# O comando abaixo força o OLLAMA_HOST a usar essa porta dinâmica.
ENTRYPOINT ["/bin/sh", "-c", "export OLLAMA_HOST=0.0.0.0:$PORT && echo '🚀 Ollama iniciando na porta '$PORT && exec ollama serve"]