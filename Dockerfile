# 1. Usar a imagem oficial do Ollama como base
FROM ollama/ollama:latest

# 2. Inicia o servidor em background, espera, e baixa os modelos
RUN ollama serve & \
    sleep 10 && \
    ollama pull qwen2.5:7b-instruct-q4_k_m && \
    ollama pull qwen2.5:7b-instruct-q5_k_m

# 3. Definir as variáveis de ambiente para o runtime
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_KEEP_ALIVE=24h

# 4. CORREÇÃO FINAL: Substituir o ENTRYPOINT
ENTRYPOINT ["/bin/sh", "-c", "export OLLAMA_PORT=$PORT && ollama serve"]
