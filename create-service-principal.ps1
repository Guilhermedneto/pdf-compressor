# Script para criar Service Principal para GitHub Actions

$SUBSCRIPTION_ID = "4131f35f-913b-418a-b156-942f25d671a7"
$RESOURCE_GROUP = "rg-estudo-api"
$SP_NAME = "github-actions-pdf-compressor"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Criando Service Principal para GitHub Actions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar login
az account show | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Faça login com 'az login'!" -ForegroundColor Red
    exit 1
}

Write-Host "Criando Service Principal..." -ForegroundColor Yellow
Write-Host ""

$credentials = az ad sp create-for-rbac `
    --name $SP_NAME `
    --role contributor `
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" `
    --sdk-auth

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao criar Service Principal!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Você pode não ter permissões para criar Service Principals." -ForegroundColor Yellow
    Write-Host "Entre em contato com o administrador da assinatura." -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Service Principal criado com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "COPIE TODO O JSON ABAIXO:" -ForegroundColor Yellow
Write-Host ""
Write-Host $credentials -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Copie TODO o JSON acima (incluindo as chaves { })" -ForegroundColor White
Write-Host ""
Write-Host "2. Acesse: https://github.com/Guilhermedneto/pdf-compressor/settings/secrets/actions" -ForegroundColor White
Write-Host ""
Write-Host "3. Clique em 'New repository secret'" -ForegroundColor White
Write-Host ""
Write-Host "4. Configure:" -ForegroundColor White
Write-Host "   Name: AZURE_CREDENTIALS" -ForegroundColor Gray
Write-Host "   Value: Cole o JSON copiado" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Clique em 'Add secret'" -ForegroundColor White
Write-Host ""
Write-Host "6. Depois, faça commit e push do código:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Add GitHub Actions CI/CD workflow'" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host ""
