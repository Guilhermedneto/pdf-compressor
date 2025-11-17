# Guia de Instalação e Deploy - Passo a Passo

## Passo 1: Instalar Azure CLI

### 1.1 Baixar o Instalador
1. Acesse: https://aka.ms/installazurecli
2. Baixe o instalador MSI para Windows (Azure CLI)
3. Execute o instalador baixado
4. Siga o assistente de instalação (pode manter todas as opções padrão)
5. Clique em "Install" e aguarde a conclusão

### 1.2 Verificar Instalação
Após a instalação, **FECHE E REABRA** o PowerShell/Terminal e execute:

```powershell
az --version
```

Se aparecer a versão do Azure CLI, está instalado corretamente!

## Passo 2: Verificar Docker Desktop

Certifique-se que o Docker Desktop está rodando:

```powershell
docker --version
docker ps
```

Se aparecer a versão e a lista de containers (mesmo que vazia), está OK!

## Passo 3: Executar o Script de Deploy

Navegue até o diretório do projeto:

```powershell
cd "c:\Users\guilh\OneDrive\Desktop\Estudo\Comprimir - PDF"
```

Execute o script de deploy:

```powershell
.\deploy-azure.ps1
```

## O que o script vai fazer:

1. ✅ Verificar Azure CLI e Docker
2. 🔐 Solicitar login na Azure (vai abrir o navegador)
3. 📦 Criar Azure Container Registry (ACR)
4. 🐳 Build das imagens Docker (backend e frontend)
5. ⬆️ Push das imagens para o ACR
6. 🚀 Criar App Service Plan
7. 🌐 Criar Web Apps (backend e frontend)
8. ⚙️ Configurar variáveis de ambiente
9. 🔒 Habilitar HTTPS
10. 🎉 Exibir URLs da aplicação

## Tempo estimado:
- Instalação Azure CLI: 2-3 minutos
- Execução do script: 10-15 minutos (dependendo da internet)

## Após o Deploy

O script vai exibir as URLs:
- **Frontend**: https://pdf-compressor-frontend.azurewebsites.net
- **Backend**: https://pdf-compressor-backend.azurewebsites.net
- **Health Check**: https://pdf-compressor-backend.azurewebsites.net/health

**IMPORTANTE**: Aguarde 2-3 minutos após o script terminar para os containers iniciarem completamente na Azure.

## Verificar Logs (se necessário)

Se houver algum problema, você pode ver os logs:

### Logs do Backend:
```powershell
az webapp log tail --name pdf-compressor-backend --resource-group rg-estudo-api
```

### Logs do Frontend:
```powershell
az webapp log tail --name pdf-compressor-frontend --resource-group rg-estudo-api
```

## Testar a Aplicação

1. Acesse a URL do frontend
2. Faça upload de um PDF
3. Selecione a qualidade de compressão
4. Baixe o arquivo comprimido

## Problemas Comuns

### "Azure CLI não encontrado" após instalação
- **Solução**: Feche TODOS os terminais/PowerShell abertos e abra um novo

### "Docker não está rodando"
- **Solução**: Abra o Docker Desktop e aguarde ele iniciar completamente

### "Nome do ACR já existe"
- **Solução**: Edite o script e mude a variável `$AcrName` para um nome único (ex: `pdfcompressor2024acr`)

### Build do Docker falha
- **Solução**: Certifique-se que está no diretório raiz do projeto onde estão as pastas `backend` e `frontend`

### App não responde após deploy
- **Solução**: Aguarde 2-3 minutos e tente novamente. Os containers precisam de tempo para iniciar.

## Custos Azure (Estimativa)

- **ACR Basic**: ~$5/mês
- **App Service Plan B1**: ~$13/mês
- **Total**: ~$18/mês

Para deletar tudo e evitar custos:
```powershell
az webapp delete --name pdf-compressor-backend --resource-group rg-estudo-api
az webapp delete --name pdf-compressor-frontend --resource-group rg-estudo-api
az appservice plan delete --name pdf-compressor-plan --resource-group rg-estudo-api
az acr delete --name pdfcompressoracr --resource-group rg-estudo-api
```

## Próximos Passos

Após o deploy bem-sucedido, você pode:
- ✅ Testar a aplicação
- ✅ Configurar domínio customizado
- ✅ Implementar Application Insights para monitoramento
- ✅ Configurar backup automático
- ✅ Implementar autenticação (Azure AD)

---

**Está pronto para começar?**

Execute os comandos na ordem e acompanhe o progresso!
