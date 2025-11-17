# Script para Limpar Recursos Pagos do Azure
# PDF Compressor - Limpeza do grupo rg-estudo-api

param(
    [string]$ResourceGroup = "rg-estudo-api"
)

Write-Host "========================================" -ForegroundColor Red
Write-Host "LIMPEZA DE RECURSOS DO AZURE" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Grupo de Recursos: $ResourceGroup" -ForegroundColor Yellow
Write-Host ""

# Verificar se está logado
az account show | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Faça login com 'az login'!" -ForegroundColor Red
    exit 1
}

# Listar recursos atuais
Write-Host "Recursos atuais no grupo:" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroup --output table

Write-Host ""
Write-Host "ATENÇÃO: Todos os recursos acima serão deletados!" -ForegroundColor Red
$confirm = Read-Host "Deseja continuar? (digite 'SIM' para confirmar)"

if ($confirm -ne "SIM") {
    Write-Host "Operação cancelada." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Deletando recursos..." -ForegroundColor Yellow
Write-Host ""

# Deletar Container Instances (se existirem)
Write-Host "Verificando Container Instances..." -ForegroundColor Yellow
$containers = az container list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($container in $containers) {
    if ($container) {
        Write-Host "  Deletando container: $container" -ForegroundColor Yellow
        az container delete --name $container --resource-group $ResourceGroup --yes
    }
}

# Deletar Web Apps (se existirem)
Write-Host "Verificando Web Apps..." -ForegroundColor Yellow
$webapps = az webapp list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($webapp in $webapps) {
    if ($webapp) {
        Write-Host "  Deletando web app: $webapp" -ForegroundColor Yellow
        az webapp delete --name $webapp --resource-group $ResourceGroup
    }
}

# Deletar App Service Plans (se existirem)
Write-Host "Verificando App Service Plans..." -ForegroundColor Yellow
$plans = az appservice plan list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($plan in $plans) {
    if ($plan) {
        Write-Host "  Deletando app service plan: $plan" -ForegroundColor Yellow
        az appservice plan delete --name $plan --resource-group $ResourceGroup --yes
    }
}

# Deletar Container Registry (se existir)
Write-Host "Verificando Container Registry..." -ForegroundColor Yellow
$acrs = az acr list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($acr in $acrs) {
    if ($acr) {
        Write-Host "  Deletando ACR: $acr" -ForegroundColor Yellow
        az acr delete --name $acr --resource-group $ResourceGroup --yes
    }
}

# Deletar Function Apps (se existirem)
Write-Host "Verificando Function Apps..." -ForegroundColor Yellow
$functionapps = az functionapp list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($functionapp in $functionapps) {
    if ($functionapp) {
        Write-Host "  Deletando function app: $functionapp" -ForegroundColor Yellow
        az functionapp delete --name $functionapp --resource-group $ResourceGroup
    }
}

# Deletar Storage Accounts (se existirem)
Write-Host "Verificando Storage Accounts..." -ForegroundColor Yellow
$storages = az storage account list --resource-group $ResourceGroup --query "[].name" --output tsv
foreach ($storage in $storages) {
    if ($storage) {
        Write-Host "  Deletando storage account: $storage" -ForegroundColor Yellow
        az storage account delete --name $storage --resource-group $ResourceGroup --yes
    }
}

# Verificar recursos restantes
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "LIMPEZA CONCLUÍDA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Recursos restantes:" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroup --output table

Write-Host ""
Write-Host "Grupo de recursos está limpo e pronto para novo deploy!" -ForegroundColor Green
Write-Host ""
