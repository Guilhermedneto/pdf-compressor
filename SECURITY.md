# Guia de Segurança - PDF Compressor

## Vulnerabilidades Implementadas e Mitigadas

### 1. CORS (Cross-Origin Resource Sharing)

**Problema**: CORS aberto permite qualquer origem acessar a API.

**Solução Implementada**:
```python
# No app/main.py
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,  # Apenas origens específicas
    allow_methods=["GET", "POST"],  # Apenas métodos necessários
    max_age=3600,
)
```

**Configuração para Produção**:
```bash
ALLOWED_ORIGINS=https://your-frontend.azurewebsites.net
```

### 2. Trusted Host Protection

**Problema**: Ataques de Host Header Injection.

**Solução Implementada**:
```python
app.add_middleware(TrustedHostMiddleware, allowed_hosts=allowed_hosts)
```

**Configuração**:
```bash
ALLOWED_HOSTS=your-backend.azurewebsites.net,your-custom-domain.com
```

### 3. Documentação da API em Produção

**Problema**: Docs expostas publicamente revelam estrutura da API.

**Solução Implementada**:
```python
docs_url="/docs" if os.getenv("ENVIRONMENT") != "production" else None,
redoc_url="/redoc" if os.getenv("ENVIRONMENT") != "production" else None,
```

### 4. Validação de Arquivos

**Implementado em pdf_controller.py**:

✅ **Validação de tipo de arquivo**
```python
if not file.filename.lower().endswith('.pdf'):
    raise HTTPException(status_code=400, detail="Only PDF files are allowed")
```

✅ **Limite de tamanho**
```python
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB
```

✅ **Validação de conteúdo** (via PyMuPDF)
- Tenta abrir o arquivo com `fitz.open()` que valida se é PDF válido

### 5. Path Traversal Protection

**Implementado**:
```python
# Uso de Path() do pathlib para normalização
# UUID para nomes de arquivo evita path traversal
unique_filename = f"{Path(filename).stem}_{unique_id}{file_extension}"
```

### 6. Command Injection Protection

**No Ghostscript**:
```python
# Uso de lista de argumentos ao invés de string
cmd = [
    gs_cmd,
    '-sDEVICE=pdfwrite',
    # ... parâmetros fixos
    str(file_path)  # Path validado
]
subprocess.run(cmd, capture_output=True, timeout=120)
```

### 7. Resource Limits

**Timeouts**:
```python
# Timeout para Ghostscript
subprocess.run(cmd, capture_output=True, timeout=120)
```

**Cleanup**:
```python
# Limpeza de arquivos temporários
self.pdf_service.cleanup_file(uploaded_file_path)
```

## Configurações Adicionais Recomendadas para Produção

### 1. Rate Limiting

Adicione ao `requirements.txt`:
```
slowapi==0.1.9
```

Implemente em `app/main.py`:
```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/api/compress")
@limiter.limit("10/minute")
async def compress_pdf(...):
    ...
```

### 2. HTTPS Obrigatório

No Azure Web App:
```bash
az webapp update --resource-group <rg> --name <app> --https-only true
```

### 3. Variáveis de Ambiente Seguras

**Nunca commite** `.env` no Git!

Configure no Azure:
```bash
az webapp config appsettings set --resource-group pdf-compressor-rg \
  --name pdf-compressor-backend \
  --settings \
    ENVIRONMENT=production \
    ALLOWED_HOSTS=pdf-compressor-backend.azurewebsites.net \
    ALLOWED_ORIGINS=https://pdf-compressor-frontend.azurewebsites.net
```

### 4. Headers de Segurança

Já implementados no `nginx.conf`:
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

Adicione também:
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

### 5. Logging e Monitoramento

Adicione logs de segurança:
```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.post("/api/compress")
async def compress_pdf(file: UploadFile):
    logger.info(f"Compression request: {file.filename}, size: {file.size}")
    # ...
```

### 6. Azure Specific

**Application Insights**:
```bash
az webapp config appsettings set --resource-group pdf-compressor-rg \
  --name pdf-compressor-backend \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>
```

**Managed Identity**:
```bash
az webapp identity assign --resource-group pdf-compressor-rg \
  --name pdf-compressor-backend
```

## Checklist de Segurança Pré-Deploy

- [ ] Variável `ENVIRONMENT=production` configurada
- [ ] CORS restrito a domínios específicos
- [ ] Docs da API desabilitadas
- [ ] HTTPS obrigatório habilitado
- [ ] Rate limiting implementado
- [ ] Headers de segurança configurados
- [ ] Logs de auditoria habilitados
- [ ] Backup e retenção de logs configurados
- [ ] Alertas de monitoramento configurados
- [ ] Arquivos temporários com cleanup automático

## Vulnerabilidades Conhecidas e Limitações

### 1. Arquivos Temporários
**Risco**: Arquivos ficam no sistema de arquivos efêmero
**Mitigação**: Implementar cleanup após processamento
**Recomendação para Produção**: Usar Azure Blob Storage

### 2. Ghostscript
**Risco**: Vulnerabilidades conhecidas em versões antigas
**Mitigação**: Sempre usar imagem base atualizada do Docker
**Recomendação**: Atualizar regularmente a imagem base

### 3. Sem Autenticação
**Risco**: API pública sem autenticação
**Recomendação para Produção**: Implementar Azure AD ou API Keys

### 4. DoS via Upload
**Risco**: Upload de muitos arquivos grandes
**Mitigação Parcial**: Rate limiting + tamanho máximo
**Recomendação**: Azure Front Door com WAF

## Monitoramento de Segurança

### Logs a Monitorar
- Tentativas de upload de arquivos não-PDF
- Uploads acima do limite de tamanho
- Rate limiting triggers
- Erros 400/500
- Tempo de processamento anormal

### Alertas Sugeridos
- Taxa de erro > 5%
- Tempo de resposta > 30s
- Taxa de requests > threshold
- Uso de CPU/memória > 80%

## Compliance

### LGPD/GDPR
- Arquivos são deletados após processamento
- Não armazena dados pessoais
- Não faz logging de conteúdo dos arquivos

### Recomendações
- Adicionar política de privacidade
- Termo de uso explícito
- Tempo máximo de retenção de arquivos
