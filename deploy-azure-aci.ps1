# Script de Deploy para Azure Container Instances (ACI)
# PDF Compressor - Deploy no grupo de recursos rg-estudo-api

param(
    [string]$ResourceGroup = "rg-estudo-api",
    [string]$Location = "eastus",
    [string]$AcrName = "pdfcompressoracr",
    [string]$BackendContainer = "pdf-compressor-backend-aci",
    [string]$FrontendContainer = "pdf-compressor-frontend-aci"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PDF Compressor - Deploy com ACI na Azure" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Azure CLI está instalado
Write-Host "Verificando Azure CLI..." -ForegroundColor Yellow
$azCli = Get-Command az -ErrorAction SilentlyContinue
if (-not $azCli) {
    Write-Host "ERRO: Azure CLI não está instalado!" -ForegroundColor Red
    exit 1
}
Write-Host "Azure CLI encontrado!" -ForegroundColor Green

# Verificar se está logado
Write-Host "Verificando login na Azure..." -ForegroundColor Yellow
az account show | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Faça login com 'az login'!" -ForegroundColor Red
    exit 1
}
Write-Host "Login confirmado!" -ForegroundColor Green

# Verificar se o grupo de recursos existe
Write-Host ""
Write-Host "Verificando grupo de recursos: $ResourceGroup..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroup
if ($rgExists -eq "false") {
    Write-Host "ERRO: Grupo de recursos $ResourceGroup não existe!" -ForegroundColor Red
    exit 1
}
Write-Host "Grupo de recursos confirmado!" -ForegroundColor Green

# Verificar se ACR existe
Write-Host ""
Write-Host "Verificando Azure Container Registry..." -ForegroundColor Yellow
$acrExists = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
if (-not $acrExists) {
    Write-Host "ERRO: ACR $AcrName não encontrado! Execute o script deploy-azure.ps1 primeiro para criar o ACR e fazer push das imagens." -ForegroundColor Red
    exit 1
}
Write-Host "ACR encontrado!" -ForegroundColor Green

# Obter credenciais do ACR
Write-Host "Obtendo credenciais do ACR..." -ForegroundColor Yellow
$acrServer = az acr show --name $AcrName --query loginServer --output tsv
$acrUsername = az acr credential show --name $AcrName --query username --output tsv
$acrPassword = az acr credential show --name $AcrName --query "passwords[0].value" --output tsv

Write-Host "ACR Server: $acrServer" -ForegroundColor White

# Deletar containers antigos se existirem
Write-Host ""
Write-Host "Verificando containers existentes..." -ForegroundColor Yellow
$backendExists = az container show --name $BackendContainer --resource-group $ResourceGroup 2>$null
if ($backendExists) {
    Write-Host "Deletando container backend antigo..." -ForegroundColor Yellow
    az container delete --name $BackendContainer --resource-group $ResourceGroup --yes
}

$frontendExists = az container show --name $FrontendContainer --resource-group $ResourceGroup 2>$null
if ($frontendExists) {
    Write-Host "Deletando container frontend antigo..." -ForegroundColor Yellow
    az container delete --name $FrontendContainer --resource-group $ResourceGroup --yes
}

# Criar Container Instance para Backend
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Criando Container Instance para Backend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Criando container backend..." -ForegroundColor Yellow
az container create `
    --resource-group $ResourceGroup `
    --name $BackendContainer `
    --image "$acrServer/pdf-compressor-backend:latest" `
    --registry-login-server $acrServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --dns-name-label "pdf-compressor-backend" `
    --ports 8000 `
    --cpu 1 `
    --memory 1.5 `
    --environment-variables `
        ENVIRONMENT=production `
        ALLOWED_HOSTS="pdf-compressor-backend.eastus.azurecontainer.io" `
        ALLOWED_ORIGINS="http://pdf-compressor-frontend.eastus.azurecontainer.io,https://pdf-compressor-frontend.eastus.azurecontainer.io" `
        MAX_FILE_SIZE=104857600

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar container backend!" -ForegroundColor Red
    exit 1
}

# Obter FQDN do backend
$backendFqdn = az container show --name $BackendContainer --resource-group $ResourceGroup --query "ipAddress.fqdn" --output tsv
$backendUrl = "http://${backendFqdn}:8000"

Write-Host "Backend criado com sucesso!" -ForegroundColor Green
Write-Host "Backend URL: $backendUrl" -ForegroundColor White

# Criar Container Instance para Frontend
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Criando Container Instance para Frontend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Criando container frontend..." -ForegroundColor Yellow
az container create `
    --resource-group $ResourceGroup `
    --name $FrontendContainer `
    --image "$acrServer/pdf-compressor-frontend:latest" `
    --registry-login-server $acrServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --dns-name-label "pdf-compressor-frontend" `
    --ports 80 `
    --cpu 1 `
    --memory 1 `
    --environment-variables `
        VITE_API_URL=$backendUrl

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar container frontend!" -ForegroundColor Red
    exit 1
}

# Obter FQDN do frontend
$frontendFqdn = az container show --name $FrontendContainer --resource-group $ResourceGroup --query "ipAddress.fqdn" --output tsv
$frontendUrl = "http://${frontendFqdn}"

Write-Host "Frontend criado com sucesso!" -ForegroundColor Green
Write-Host "Frontend URL: $frontendUrl" -ForegroundColor White

# Atualizar CORS do backend
Write-Host ""
Write-Host "Atualizando CORS do backend..." -ForegroundColor Yellow
Write-Host "NOTA: Para atualizar as variáveis de ambiente, o container será recriado..." -ForegroundColor Yellow

az container delete --name $BackendContainer --resource-group $ResourceGroup --yes

az container create `
    --resource-group $ResourceGroup `
    --name $BackendContainer `
    --image "$acrServer/pdf-compressor-backend:latest" `
    --registry-login-server $acrServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --dns-name-label "pdf-compressor-backend" `
    --ports 8000 `
    --cpu 1 `
    --memory 1.5 `
    --environment-variables `
        ENVIRONMENT=production `
        ALLOWED_HOSTS="pdf-compressor-backend.eastus.azurecontainer.io" `
        ALLOWED_ORIGINS="http://${frontendFqdn},https://${frontendFqdn}" `
        MAX_FILE_SIZE=104857600

Write-Host "Backend atualizado com CORS correto!" -ForegroundColor Green

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
Write-Host "IMPORTANTE: Os containers levam 1-2 minutos para iniciar." -ForegroundColor Yellow
Write-Host "Teste o health check primeiro: $backendUrl/health" -ForegroundColor Yellow
Write-Host ""
Write-Host "Custos Estimados (ACI - pay per use):" -ForegroundColor Cyan
Write-Host "  Backend (1 vCPU, 1.5GB RAM): ~$0.05/hora = ~$36/mês se rodando 24/7" -ForegroundColor White
Write-Host "  Frontend (1 vCPU, 1GB RAM): ~$0.04/hora = ~$29/mês se rodando 24/7" -ForegroundColor White
Write-Host "  ACR Basic: ~$5/mês" -ForegroundColor White
Write-Host "  Total aproximado: ~$70/mês (rodando 24/7)" -ForegroundColor White
Write-Host ""
Write-Host "DICA: Para economizar, delete os containers quando não estiver usando:" -ForegroundColor Yellow
Write-Host "  az container delete --name $BackendContainer --resource-group $ResourceGroup" -ForegroundColor White
Write-Host "  az container delete --name $FrontendContainer --resource-group $ResourceGroup" -ForegroundColor White
Write-Host ""
Write-Host "Para ver logs:" -ForegroundColor Cyan
Write-Host "  az container logs --name $BackendContainer --resource-group $ResourceGroup" -ForegroundColor White
Write-Host "  az container logs --name $FrontendContainer --resource-group $ResourceGroup" -ForegroundColor White
Write-Host ""
