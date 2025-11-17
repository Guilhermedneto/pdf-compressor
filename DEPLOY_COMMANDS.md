# Comandos para Deploy na Azure - rg-estudo-api

## Pré-requisitos

1. **Azure CLI instalado**: https://aka.ms/installazurecli
2. **Docker Desktop rodando**
3. **Login na Azure**:
```bash
az login
```

## Variáveis do Projeto

```bash
# Definir variáveis
RESOURCE_GROUP="rg-estudo-api"
LOCATION="eastus"
ACR_NAME="pdfcompressoracr"
APP_SERVICE_PLAN="pdf-compressor-plan"
BACKEND_APP="pdf-compressor-backend"
FRONTEND_APP="pdf-compressor-frontend"
```

## Passo 1: Criar Azure Container Registry (ACR)

```bash
# Criar ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Fazer login no ACR
az acr login --name $ACR_NAME
```

## Passo 2: Build e Push das Imagens Docker

### Backend

```bash
# Navegar para o diretório do projeto
cd "c:\Users\guilh\OneDrive\Desktop\Estudo\Comprimir - PDF"

# Build da imagem do backend
docker build -t $ACR_NAME.azurecr.io/pdf-compressor-backend:latest ./backend

# Push para o ACR
docker push $ACR_NAME.azurecr.io/pdf-compressor-backend:latest
```

### Frontend

```bash
# Build da imagem do frontend
docker build -t $ACR_NAME.azurecr.io/pdf-compressor-frontend:latest ./frontend

# Push para o ACR
docker push $ACR_NAME.azurecr.io/pdf-compressor-frontend:latest
```

## Passo 3: Criar App Service Plan

```bash
# Criar App Service Plan com suporte a Linux e containers
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --is-linux \
  --sku B1
```

## Passo 4: Criar Web App para o Backend

```bash
# Obter credenciais do ACR
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Criar Web App do Backend
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --name $BACKEND_APP \
  --deployment-container-image-name $ACR_NAME.azurecr.io/pdf-compressor-backend:latest

# Configurar credenciais do registry
az webapp config container set \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/pdf-compressor-backend:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD

# Configurar porta do container
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --settings WEBSITES_PORT=8000
```

## Passo 5: Configurar Variáveis de Ambiente do Backend

```bash
# Obter URL do frontend (será criado no próximo passo)
FRONTEND_URL="https://$FRONTEND_APP.azurewebsites.net"
BACKEND_URL="https://$BACKEND_APP.azurewebsites.net"

# Configurar variáveis de ambiente
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --settings \
    ENVIRONMENT=production \
    ALLOWED_HOSTS=$BACKEND_APP.azurewebsites.net \
    ALLOWED_ORIGINS=$FRONTEND_URL \
    MAX_FILE_SIZE=104857600 \
    RATE_LIMIT=60
```

## Passo 6: Criar Web App para o Frontend

```bash
# Criar Web App do Frontend
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --name $FRONTEND_APP \
  --deployment-container-image-name $ACR_NAME.azurecr.io/pdf-compressor-frontend:latest

# Configurar credenciais do registry
az webapp config container set \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/pdf-compressor-frontend:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD

# Configurar porta do container
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FRONTEND_APP \
  --settings WEBSITES_PORT=80
```

## Passo 7: Configurar Variável de Ambiente do Frontend

```bash
# Configurar URL da API
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FRONTEND_APP \
  --settings VITE_API_URL=$BACKEND_URL
```

## Passo 8: Habilitar HTTPS Only

```bash
# Backend
az webapp update \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP \
  --https-only true

# Frontend
az webapp update \
  --resource-group $RESOURCE_GROUP \
  --name $FRONTEND_APP \
  --https-only true
```

## Passo 9: Configurar Continuous Deployment (Opcional)

```bash
# Habilitar CI/CD para o backend
az webapp deployment container config \
  --name $BACKEND_APP \
  --resource-group $RESOURCE_GROUP \
  --enable-cd true

# Habilitar CI/CD para o frontend
az webapp deployment container config \
  --name $FRONTEND_APP \
  --resource-group $RESOURCE_GROUP \
  --enable-cd true
```

## Passo 10: Verificar Logs

```bash
# Logs do Backend
az webapp log tail --name $BACKEND_APP --resource-group $RESOURCE_GROUP

# Logs do Frontend
az webapp log tail --name $FRONTEND_APP --resource-group $RESOURCE_GROUP
```

## URLs da Aplicação

Após o deploy completo:

- **Backend API**: `https://pdf-compressor-backend.azurewebsites.net`
- **Frontend**: `https://pdf-compressor-frontend.azurewebsites.net`
- **Backend Docs** (apenas dev): `https://pdf-compressor-backend.azurewebsites.net/docs`
- **Health Check**: `https://pdf-compressor-backend.azurewebsites.net/health`

## Troubleshooting

### Verificar status dos apps
```bash
az webapp show --name $BACKEND_APP --resource-group $RESOURCE_GROUP --query state
az webapp show --name $FRONTEND_APP --resource-group $RESOURCE_GROUP --query state
```

### Reiniciar apps
```bash
az webapp restart --name $BACKEND_APP --resource-group $RESOURCE_GROUP
az webapp restart --name $FRONTEND_APP --resource-group $RESOURCE_GROUP
```

### Verificar configurações
```bash
az webapp config appsettings list --name $BACKEND_APP --resource-group $RESOURCE_GROUP
```

### Atualizar imagens
```bash
# Rebuild e push das novas imagens
docker build -t $ACR_NAME.azurecr.io/pdf-compressor-backend:latest ./backend
docker push $ACR_NAME.azurecr.io/pdf-compressor-backend:latest

# Reiniciar para puxar nova imagem
az webapp restart --name $BACKEND_APP --resource-group $RESOURCE_GROUP
```

## Custos Estimados

- **ACR Basic**: ~$5/mês
- **App Service Plan B1**: ~$13/mês por plano
- **Total aproximado**: ~$18/mês

Para reduzir custos, considere usar F1 (Free) ou Shared D1, mas com limitações de recursos.

## Limpeza (se necessário)

```bash
# Deletar apenas os recursos do PDF Compressor
az webapp delete --name $BACKEND_APP --resource-group $RESOURCE_GROUP
az webapp delete --name $FRONTEND_APP --resource-group $RESOURCE_GROUP
az appservice plan delete --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP
az acr delete --name $ACR_NAME --resource-group $RESOURCE_GROUP
```

## Próximos Passos

1. Configurar domínio customizado (opcional)
2. Implementar Application Insights para monitoramento
3. Configurar backup automático
4. Implementar autenticação (Azure AD)
5. Configurar CDN para o frontend
