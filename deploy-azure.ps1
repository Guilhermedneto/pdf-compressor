# Script de Deploy Automatizado para Azure
# PDF Compressor - Deploy no grupo de recursos rg-estudo-api

param(
    [string]$ResourceGroup = "rg-estudo-api",
    [string]$Location = "eastus",
    [string]$AcrName = "pdfcompressoracr",
    [string]$AppServicePlan = "pdf-compressor-plan",
    [string]$BackendApp = "pdf-compressor-backend",
    [string]$FrontendApp = "pdf-compressor-frontend"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PDF Compressor - Deploy na Azure" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Azure CLI está instalado
Write-Host "Verificando Azure CLI..." -ForegroundColor Yellow
$azCli = Get-Command az -ErrorAction SilentlyContinue
if (-not $azCli) {
    Write-Host "ERRO: Azure CLI não está instalado!" -ForegroundColor Red
    Write-Host "Instale em: https://aka.ms/installazurecli" -ForegroundColor Yellow
    exit 1
}
Write-Host "Azure CLI encontrado!" -ForegroundColor Green

# Verificar se Docker está rodando
Write-Host "Verificando Docker..." -ForegroundColor Yellow
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host "ERRO: Docker não está instalado!" -ForegroundColor Red
    exit 1
}

try {
    docker ps | Out-Null
} catch {
    Write-Host "ERRO: Docker não está rodando!" -ForegroundColor Red
    Write-Host "Inicie o Docker Desktop e tente novamente." -ForegroundColor Yellow
    exit 1
}
Write-Host "Docker está rodando!" -ForegroundColor Green

# Login na Azure
Write-Host ""
Write-Host "Fazendo login na Azure..." -ForegroundColor Yellow
az account show | Out-Null
if ($LASTEXITCODE -ne 0) {
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha no login da Azure!" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Login realizado com sucesso!" -ForegroundColor Green

# Verificar se o grupo de recursos existe
Write-Host ""
Write-Host "Verificando grupo de recursos: $ResourceGroup..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "ERRO: Grupo de recursos $ResourceGroup não existe!" -ForegroundColor Red
    Write-Host "Criando grupo de recursos..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao criar grupo de recursos!" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Grupo de recursos confirmado!" -ForegroundColor Green

# Passo 1: Criar Azure Container Registry
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passo 1: Criando Azure Container Registry" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$acrExists = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
if (-not $acrExists) {
    Write-Host "Criando ACR: $AcrName..." -ForegroundColor Yellow
    az acr create `
        --resource-group $ResourceGroup `
        --name $AcrName `
        --sku Basic `
        --admin-enabled true

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao criar ACR!" -ForegroundColor Red
        exit 1
    }
    Write-Host "ACR criado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "ACR já existe, pulando criação..." -ForegroundColor Yellow
}

# Login no ACR
Write-Host "Fazendo login no ACR..." -ForegroundColor Yellow
az acr login --name $AcrName
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no login do ACR!" -ForegroundColor Red
    exit 1
}

# Passo 2: Build e Push das Imagens
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passo 2: Build e Push das Imagens Docker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Backend
Write-Host ""
Write-Host "Building imagem do Backend..." -ForegroundColor Yellow
docker build -t "$AcrName.azurecr.io/pdf-compressor-backend:latest" ./backend
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no build do backend!" -ForegroundColor Red
    exit 1
}

Write-Host "Pushing imagem do Backend para ACR..." -ForegroundColor Yellow
docker push "$AcrName.azurecr.io/pdf-compressor-backend:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no push do backend!" -ForegroundColor Red
    exit 1
}
Write-Host "Backend image pushed com sucesso!" -ForegroundColor Green

# Frontend
Write-Host ""
Write-Host "Building imagem do Frontend..." -ForegroundColor Yellow
docker build -t "$AcrName.azurecr.io/pdf-compressor-frontend:latest" ./frontend
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no build do frontend!" -ForegroundColor Red
    exit 1
}

Write-Host "Pushing imagem do Frontend para ACR..." -ForegroundColor Yellow
docker push "$AcrName.azurecr.io/pdf-compressor-frontend:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha no push do frontend!" -ForegroundColor Red
    exit 1
}
Write-Host "Frontend image pushed com sucesso!" -ForegroundColor Green

# Passo 3: Criar App Service Plan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passo 3: Criando App Service Plan" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$planExists = az appservice plan show --name $AppServicePlan --resource-group $ResourceGroup 2>$null
if (-not $planExists) {
    Write-Host "Criando App Service Plan: $AppServicePlan..." -ForegroundColor Yellow
    az appservice plan create `
        --name $AppServicePlan `
        --resource-group $ResourceGroup `
        --is-linux `
        --sku S1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao criar App Service Plan!" -ForegroundColor Red
        exit 1
    }
    Write-Host "App Service Plan criado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "App Service Plan já existe, pulando criação..." -ForegroundColor Yellow
}

# Obter credenciais do ACR
Write-Host "Obtendo credenciais do ACR..." -ForegroundColor Yellow
$acrUsername = az acr credential show --name $AcrName --query username --output tsv
$acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" --output tsv

# Passo 4: Criar Web App para Backend
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passo 4: Criando Web App para Backend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$backendExists = az webapp show --name $BackendApp --resource-group $ResourceGroup 2>$null
if (-not $backendExists) {
    Write-Host "Criando Web App do Backend: $BackendApp..." -ForegroundColor Yellow
    az webapp create `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --name $BackendApp `
        --deployment-container-image-name "$AcrName.azurecr.io/pdf-compressor-backend:latest"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao criar Web App do Backend!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Web App do Backend já existe, atualizando..." -ForegroundColor Yellow
}

# Configurar container do backend
Write-Host "Configurando container do Backend..." -ForegroundColor Yellow
az webapp config container set `
    --name $BackendApp `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "$AcrName.azurecr.io/pdf-compressor-backend:latest" `
    --docker-registry-server-url "https://$AcrName.azurecr.io" `
    --docker-registry-server-user $acrUsername `
    --docker-registry-server-password $acrPassword

# Configurar porta e variáveis de ambiente do backend
Write-Host "Configurando variáveis de ambiente do Backend..." -ForegroundColor Yellow
$frontendUrl = "https://$FrontendApp.azurewebsites.net"
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $BackendApp `
    --settings `
        WEBSITES_PORT=8000 `
        ENVIRONMENT=production `
        ALLOWED_HOSTS="$BackendApp.azurewebsites.net" `
        ALLOWED_ORIGINS=$frontendUrl `
        MAX_FILE_SIZE=104857600 `
        RATE_LIMIT=60

Write-Host "Backend configurado com sucesso!" -ForegroundColor Green

# Passo 5: Criar Web App para Frontend
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passo 5: Criando Web App para Frontend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$frontendExists = az webapp show --name $FrontendApp --resource-group $ResourceGroup 2>$null
if (-not $frontendExists) {
    Write-Host "Criando Web App do Frontend: $FrontendApp..." -ForegroundColor Yellow
    az webapp create `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --name $FrontendApp `
        --deployment-container-image-name "$AcrName.azurecr.io/pdf-compressor-frontend:latest"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao criar Web App do Frontend!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Web App do Frontend já existe, atualizando..." -ForegroundColor Yellow
}

# Configurar container do frontend
Write-Host "Configurando container do Frontend..." -ForegroundColor Yellow
az webapp config container set `
    --name $FrontendApp `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "$AcrName.azurecr.io/pdf-compressor-frontend:latest" `
    --docker-registry-server-url "https://$AcrName.azurecr.io" `
    --docker-registry-server-user $acrUsername `
    --docker-registry-server-password $acrPassword

# Configurar porta e variáveis de ambiente do frontend
Write-Host "Configurando variáveis de ambiente do Frontend..." -ForegroundColor Yellow
$backendUrl = "https://$BackendApp.azurewebsites.net"
az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $FrontendApp `
    --settings `
        WEBSITES_PORT=80 `
        VITE_API_URL=$backendUrl

Write-Host "Frontend configurado com sucesso!" -ForegroundColor Green

# Passo 6: Habilitar HTTPS Only
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passo 6: Habilitando HTTPS Only" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Habilitando HTTPS para Backend..." -ForegroundColor Yellow
az webapp update `
    --resource-group $ResourceGroup `
    --name $BackendApp `
    --https-only true

Write-Host "Habilitando HTTPS para Frontend..." -ForegroundColor Yellow
az webapp update `
    --resource-group $ResourceGroup `
    --name $FrontendApp `
    --https-only true

Write-Host "HTTPS habilitado com sucesso!" -ForegroundColor Green

# Reiniciar apps
Write-Host ""
Write-Host "Reiniciando aplicações..." -ForegroundColor Yellow
az webapp restart --name $BackendApp --resource-group $ResourceGroup
az webapp restart --name $FrontendApp --resource-group $ResourceGroup

# Sumário
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOY CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "URLs da Aplicação:" -ForegroundColor Cyan
Write-Host "  Frontend:  $frontendUrl" -ForegroundColor White
Write-Host "  Backend:   $backendUrl" -ForegroundColor White
Write-Host "  Health:    $backendUrl/health" -ForegroundColor White
Write-Host ""
Write-Host "Aguarde alguns minutos para as aplicações iniciarem completamente." -ForegroundColor Yellow
Write-Host ""
Write-Host "Para ver os logs:" -ForegroundColor Cyan
Write-Host "  az webapp log tail --name $BackendApp --resource-group $ResourceGroup" -ForegroundColor White
Write-Host "  az webapp log tail --name $FrontendApp --resource-group $ResourceGroup" -ForegroundColor White
Write-Host ""
