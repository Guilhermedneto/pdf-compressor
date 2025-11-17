# Script de Deploy para Azure Web App for Containers - Plano Gratuito
# PDF Compressor - Tentando múltiplas regiões

param(
    [string]$ResourceGroup = "rg-estudo-api",
    [string]$AcrName = "pdfcompressoracr",
    [string]$BackendApp = "pdf-compressor-api",
    [string]$FrontendApp = "pdf-compressor-web"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PDF Compressor - Deploy Web App Gratuito" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Regiões para tentar (em ordem de preferência)
$regions = @(
    "brazilsouth",    # Brasil Sul (mais próximo)
    "eastus2",        # East US 2 (alternativa)
    "westus",         # West US
    "westeurope",     # West Europe
    "northeurope",    # North Europe
    "southeastasia"   # Southeast Asia
)

# Verificar login
az account show | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Faça login com 'az login'!" -ForegroundColor Red
    exit 1
}

# Obter credenciais do ACR
Write-Host "Obtendo credenciais do ACR..." -ForegroundColor Yellow
$acrServer = az acr show --name $AcrName --query loginServer --output tsv
$acrUsername = az acr credential show --name $AcrName --query username --output tsv
$acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" --output tsv

Write-Host "ACR: $acrServer" -ForegroundColor Green
Write-Host ""

# Tentar criar App Service Plan em diferentes regiões
$planCreated = $false
$successLocation = ""
$AppServicePlan = "pdf-compressor-free-plan"

Write-Host "Tentando criar App Service Plan em diferentes regiões..." -ForegroundColor Yellow
Write-Host ""

foreach ($location in $regions) {
    Write-Host "Tentando região: $location..." -ForegroundColor Cyan

    # Tentar criar o plano
    $result = az appservice plan create `
        --name "$AppServicePlan-$location" `
        --resource-group $ResourceGroup `
        --location $location `
        --is-linux `
        --sku F1 `
        2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCESSO na região $location!" -ForegroundColor Green
        $planCreated = $true
        $successLocation = $location
        $AppServicePlan = "$AppServicePlan-$location"
        break
    } else {
        Write-Host "  Falhou em $location (sem cota disponível)" -ForegroundColor Yellow
    }
}

if (-not $planCreated) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERRO: Nenhuma região tem cota disponível" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Sua assinatura do Visual Studio Enterprise não tem cota para App Service Plans (nem Free)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Cyan
    Write-Host "1. Solicitar aumento de cota no portal Azure:" -ForegroundColor White
    Write-Host "   https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/newsupportrequest" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Usar Azure Container Instances (ACI) - pay-per-use:" -ForegroundColor White
    Write-Host "   .\deploy-azure-aci.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Deploy em outro provedor gratuito (Render, Railway, Vercel):" -ForegroundColor White
    Write-Host "   (Posso criar scripts para esses)" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "App Service Plan criado com sucesso!" -ForegroundColor Green
Write-Host "Região: $successLocation" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Criar Web App para Backend
Write-Host "Criando Web App para Backend..." -ForegroundColor Yellow
az webapp create `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --name $BackendApp `
    --deployment-container-image-name "$acrServer/pdf-compressor-backend:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar Web App do Backend!" -ForegroundColor Red

    # Verificar se é problema de nome duplicado
    Write-Host ""
    Write-Host "Tentando com nome alternativo..." -ForegroundColor Yellow
    $BackendApp = "pdf-compressor-api-" + (Get-Random -Minimum 1000 -Maximum 9999)

    az webapp create `
        --resource-group $ResourceGroup `
        --plan $AppServicePlan `
        --name $BackendApp `
        --deployment-container-image-name "$acrServer/pdf-compressor-backend:latest"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Não foi possível criar o Web App do Backend!" -ForegroundColor Red
        exit 1
    }
}

# Configurar container do backend
Write-Host "Configurando Backend..." -ForegroundColor Yellow
az webapp config container set `
    --name $BackendApp `
    --resource-group $ResourceGroup `
    --docker-custom-image-name "$acrServer/pdf-compressor-backend:latest" `
    --docker-registry-server-url "https://$acrServer" `
    --docker-registry-server-user $acrUsername `
    --docker-registry-server-password $acrPassword

# Configurar variáveis de ambiente do backend
$backendUrl = "https://$BackendApp.azurewebsites.net"
$frontendUrl = "https://$FrontendApp.azurewebsites.net"

az webapp config appsettings set `
    --resource-group $ResourceGroup `
    --name $BackendApp `
    --settings `
        WEBSITES_PORT=8000 `
        ENVIRONMENT=production `
        ALLOWED_HOSTS="$BackendApp.azurewebsites.net" `
        ALLOWED_ORIGINS=$frontendUrl `
        MAX_FILE_SIZE=104857600

# Habilitar HTTPS
az webapp update `
    --resource-group $ResourceGroup `
    --name $BackendApp `
    --https-only true

Write-Host "Backend configurado!" -ForegroundColor Green
Write-Host "URL: $backendUrl" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "LIMITAÇÃO DO PLANO FREE" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "O plano F1 (Free) permite apenas 1 Web App por plano." -ForegroundColor Yellow
Write-Host "Para o Frontend, temos opções:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opção 1: Azure Static Web Apps (100% gratuito)" -ForegroundColor Cyan
Write-Host "  - Hospedagem gratuita de frontend" -ForegroundColor White
Write-Host "  - CDN global incluído" -ForegroundColor White
Write-Host "  - SSL automático" -ForegroundColor White
Write-Host ""
Write-Host "Opção 2: GitHub Pages (100% gratuito)" -ForegroundColor Cyan
Write-Host "  - Hospedagem simples e rápida" -ForegroundColor White
Write-Host "  - Deploy automático via GitHub Actions" -ForegroundColor White
Write-Host ""
Write-Host "Opção 3: Vercel (100% gratuito)" -ForegroundColor Cyan
Write-Host "  - Excelente para React/Vite" -ForegroundColor White
Write-Host "  - Deploy automático" -ForegroundColor White
Write-Host ""
Write-Host "Qual opção você prefere para o frontend?" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "BACKEND DEPLOY CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend URL: $backendUrl" -ForegroundColor White
Write-Host "Health Check: $backendUrl/health" -ForegroundColor White
Write-Host ""
Write-Host "Aguarde 2-3 minutos para o container iniciar." -ForegroundColor Yellow
Write-Host ""
Write-Host "Para ver logs:" -ForegroundColor Cyan
Write-Host "  az webapp log tail --name $BackendApp --resource-group $ResourceGroup" -ForegroundColor White
Write-Host ""
