# Deploy para Azure Web App

Este guia explica como fazer deploy da aplicação PDF Compressor na Azure usando containers.

## Pré-requisitos

1. Conta na Azure
2. Azure CLI instalado
3. Docker instalado localmente
4. Conta no Azure Container Registry (ACR) ou Docker Hub

## Opção 1: Deploy usando Azure Container Registry (Recomendado)

### Passo 1: Criar recursos na Azure

```bash
# Login na Azure
az login

# Criar um Resource Group
az group create --name pdf-compressor-rg --location brazilsouth

# Criar um Azure Container Registry
az acr create --resource-group pdf-compressor-rg \
  --name pdfcompressoracr --sku Basic

# Habilitar admin user
az acr update -n pdfcompressoracr --admin-enabled true

# Obter credenciais
az acr credential show --name pdfcompressoracr
```

### Passo 2: Build e Push das imagens

```bash
# Login no ACR
az acr login --name pdfcompressoracr

# Build e push do backend
cd backend
docker build -t pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest .
docker push pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest

# Build e push do frontend
cd ../frontend
docker build -t pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest .
docker push pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest
```

### Passo 3: Criar App Service Plan

```bash
# Criar um App Service Plan (Linux)
az appservice plan create --name pdf-compressor-plan \
  --resource-group pdf-compressor-rg \
  --is-linux --sku B1
```

### Passo 4: Criar Web Apps

```bash
# Criar Web App para o backend
az webapp create --resource-group pdf-compressor-rg \
  --plan pdf-compressor-plan \
  --name pdf-compressor-backend \
  --deployment-container-image-name pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest

# Configurar credenciais do ACR
az webapp config container set --name pdf-compressor-backend \
  --resource-group pdf-compressor-rg \
  --docker-custom-image-name pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest \
  --docker-registry-server-url https://pdfcompressoracr.azurecr.io \
  --docker-registry-server-user pdfcompressoracr \
  --docker-registry-server-password <PASSWORD_FROM_STEP_1>

# Criar Web App para o frontend
az webapp create --resource-group pdf-compressor-rg \
  --plan pdf-compressor-plan \
  --name pdf-compressor-frontend \
  --deployment-container-image-name pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest

# Configurar credenciais do ACR
az webapp config container set --name pdf-compressor-frontend \
  --resource-group pdf-compressor-rg \
  --docker-custom-image-name pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest \
  --docker-registry-server-url https://pdfcompressoracr.azurecr.io \
  --docker-registry-server-user pdfcompressoracr \
  --docker-registry-server-password <PASSWORD_FROM_STEP_1>
```

### Passo 5: Configurar variáveis de ambiente

```bash
# Configurar URL da API no frontend
az webapp config appsettings set --resource-group pdf-compressor-rg \
  --name pdf-compressor-frontend \
  --settings VITE_API_URL=https://pdf-compressor-backend.azurewebsites.net

# Reiniciar o frontend para aplicar as configurações
az webapp restart --name pdf-compressor-frontend --resource-group pdf-compressor-rg
```

## Opção 2: Deploy usando Docker Compose (Multi-container)

### Passo 1: Criar docker-compose para Azure

Crie um arquivo `docker-compose.azure.yml`:

```yaml
version: '3.8'

services:
  backend:
    image: pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest
    ports:
      - "8000:8000"
    environment:
      - PYTHONUNBUFFERED=1

  frontend:
    image: pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest
    ports:
      - "80:80"
    environment:
      - VITE_API_URL=http://backend:8000
    depends_on:
      - backend
```

### Passo 2: Deploy multi-container

```bash
az webapp create --resource-group pdf-compressor-rg \
  --plan pdf-compressor-plan \
  --name pdf-compressor-app \
  --multicontainer-config-type compose \
  --multicontainer-config-file docker-compose.azure.yml
```

## Testar a aplicação

Após o deploy, acesse:

- **Frontend**: https://pdf-compressor-frontend.azurewebsites.net
- **Backend API**: https://pdf-compressor-backend.azurewebsites.net/docs

## Atualizar a aplicação

Quando fizer mudanças no código:

```bash
# Rebuild e push das imagens
docker build -t pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest ./backend
docker push pdfcompressoracr.azurecr.io/pdf-compressor-backend:latest

docker build -t pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest ./frontend
docker push pdfcompressoracr.azurecr.io/pdf-compressor-frontend:latest

# Reiniciar os Web Apps
az webapp restart --name pdf-compressor-backend --resource-group pdf-compressor-rg
az webapp restart --name pdf-compressor-frontend --resource-group pdf-compressor-rg
```

## Custos estimados

- **App Service Plan B1**: ~$13/mês
- **Azure Container Registry Basic**: ~$5/mês
- **Total aproximado**: ~$18/mês

## Notas importantes

1. **Ghostscript**: O Dockerfile do backend já inclui a instalação do Ghostscript
2. **Arquivos temporários**: Os arquivos PDF são armazenados em volumes efêmeros. Para produção, considere usar Azure Blob Storage
3. **CORS**: O backend já está configurado para aceitar requisições de qualquer origem
4. **Limites de upload**: Configure o limite de upload no Azure Web App se necessário

## Troubleshooting

Ver logs do container:
```bash
az webapp log tail --name pdf-compressor-backend --resource-group pdf-compressor-rg
```

Ver configuração do container:
```bash
az webapp config container show --name pdf-compressor-backend --resource-group pdf-compressor-rg
```
