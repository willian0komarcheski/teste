# Dockerfile para Record-API (Python)

# Use uma imagem base oficial do Python
FROM python:3.11-slim

# Defina o diretório de trabalho
WORKDIR /app

# Copie o arquivo de dependências (assumindo requirements.txt)
COPY requirements.txt requirements.txt

# Instale as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copie o restante do código da aplicação
COPY . .

# Exponha a porta que a API Python usará (ex: 5001)
EXPOSE 5001

# Comando para iniciar a aplicação (exemplo com Flask/FastAPI)
# Substitua 'your_app_module:app' pelo ponto de entrada real
# CMD ["python", "-m", "uvicorn", "your_app_module:app", "--host", "0.0.0.0", "--port", "5001"]
# Ou para Flask:
# CMD ["flask", "run", "--host=0.0.0.0", "--port=5001"]
# Adicione um comando placeholder se o ponto de entrada exato não for conhecido
CMD ["echo", "Execute a aplicação Python aqui"]

