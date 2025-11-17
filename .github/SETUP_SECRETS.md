# Configuração de Secrets para GitHub Actions

Para o CI/CD funcionar, você precisa configurar as credenciais do Azure no GitHub.

## Passo 1: Criar Service Principal no Azure

Execute o script PowerShell que já está pronto:

```powershell
.\create-service-principal.ps1
```

Ou manualmente no PowerShell:

```powershell
# Substitua pelo seu Subscription ID
$SUBSCRIPTION_ID = "4131f35f-913b-418a-b156-942f25d671a7"

# Criar Service Principal
az ad sp create-for-rbac `
  --name "github-actions-pdf-compressor" `
  --role contributor `
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-estudo-api `
  --output json
```

**IMPORTANTE**: Copie TODA a saída JSON. Ela será algo assim:

```json
{
  "clientId": "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx",
  "clientSecret": "xxxxx~xxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "4131f35f-913b-418a-b156-942f25d671a7",
  "tenantId": "511345d7-a395-4ae8-af2d-68a44ae59be7",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## Passo 2: Adicionar Secret no GitHub

1. Acesse seu repositório no GitHub: https://github.com/Guilhermedneto/pdf-compressor

2. Vá em **Settings** → **Secrets and variables** → **Actions**

3. Clique em **New repository secret**

4. Configure o secret:
   - **Name**: `AZURE_CREDENTIALS`
   - **Value**: Cole TODO o JSON que você copiou no Passo 1

5. Clique em **Add secret**

## Passo 3: Testar o Workflow

Agora que o secret está configurado, você pode testar o deploy:

### Opção A: Push para o GitHub
```bash
git add .
git commit -m "Add GitHub Actions workflow for CI/CD"
git push origin main
```

O workflow será executado automaticamente em cada push para a branch `main`.

### Opção B: Executar Manualmente
1. Vá em **Actions** no GitHub
2. Selecione o workflow "Deploy to Azure Container Instances"
3. Clique em **Run workflow**
4. Aguarde o deploy completar (3-5 minutos)

## Passo 4: Verificar Deploy

Após o workflow completar:

1. Vá em **Actions** → selecione a execução mais recente
2. Veja os logs para obter as URLs:
   - Frontend: `http://pdf-compressor-frontend.eastus.azurecontainer.io`
   - Backend: `http://pdf-compressor-backend.eastus.azurecontainer.io:8000`

3. Teste o health check:
   ```bash
   curl http://pdf-compressor-backend.eastus.azurecontainer.io:8000/health
   ```

## Verificar Logs dos Containers

```bash
# Backend
az container logs --name pdf-compressor-backend-aci --resource-group rg-estudo-api

# Frontend
az container logs --name pdf-compressor-frontend-aci --resource-group rg-estudo-api
```

## Custos

Os containers vão rodar 24/7 após o deploy. Custos estimados:
- Backend: ~$36/mês
- Frontend: ~$29/mês
- ACR: ~$5/mês
- **Total**: ~$70/mês

### Para Economizar

Você pode parar os containers quando não estiver usando:

```bash
az container stop --name pdf-compressor-backend-aci --resource-group rg-estudo-api
az container stop --name pdf-compressor-frontend-aci --resource-group rg-estudo-api
```

E iniciá-los novamente quando precisar:

```bash
az container start --name pdf-compressor-backend-aci --resource-group rg-estudo-api
az container start --name pdf-compressor-frontend-aci --resource-group rg-estudo-api
```

## Troubleshooting

### Erro: "Resource 'Microsoft.ContainerInstance/containerGroups' was disallowed by policy"
- Solução: Sua assinatura pode ter políticas que bloqueiam ACI. Entre em contato com o administrador.

### Erro: "Image pull failed"
- Solução: Verifique se o ACR está acessível e as credenciais estão corretas.

### Containers não iniciam
- Verifique os logs com `az container logs`
- Verifique se as imagens foram enviadas corretamente para o ACR

### CORS errors no frontend
- O workflow já configura CORS automaticamente
- Se ainda tiver problemas, verifique as variáveis de ambiente do backend
