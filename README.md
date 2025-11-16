# PDF Compressor

Uma aplicação web moderna para comprimir arquivos PDF de forma rápida e eficiente.

## Tecnologias

### Backend
- **FastAPI** - Framework web de alta performance
- **Python 3.8+** - Linguagem de programação
- **PyPDF2** - Biblioteca para manipulação de PDFs
- **Uvicorn** - Servidor ASGI

### Frontend
- **React 18** - Biblioteca JavaScript para interfaces
- **Vite** - Build tool e dev server
- **Tailwind CSS** - Framework CSS utilitário
- **Axios** - Cliente HTTP
- **Lucide React** - Ícones modernos

## Estrutura do Projeto

```
pdf-compressor/
├── backend/                    # API FastAPI
│   ├── app/
│   │   ├── controllers/       # Controladores (MVC)
│   │   ├── models/            # Modelos de dados
│   │   ├── services/          # Lógica de negócio
│   │   ├── routes/            # Rotas da API
│   │   └── main.py            # Arquivo principal
│   ├── uploads/               # Arquivos enviados (temporário)
│   ├── compressed/            # PDFs comprimidos
│   └── requirements.txt       # Dependências Python
│
└── frontend/                   # Aplicação React
    ├── src/
    │   ├── components/        # Componentes React
    │   ├── pages/             # Páginas
    │   ├── services/          # Serviços (API)
    │   └── main.jsx           # Ponto de entrada
    └── package.json           # Dependências Node
```

## Instalação

### Pré-requisitos

- Python 3.8 ou superior
- Node.js 18 ou superior
- npm ou yarn

### Backend

1. Navegue até a pasta do backend:
```bash
cd backend
```

2. Crie um ambiente virtual Python:
```bash
python -m venv venv
```

3. Ative o ambiente virtual:
   - Windows:
   ```bash
   venv\Scripts\activate
   ```
   - Linux/Mac:
   ```bash
   source venv/bin/activate
   ```

4. Instale as dependências:
```bash
pip install -r requirements.txt
```

### Frontend

1. Navegue até a pasta do frontend:
```bash
cd frontend
```

2. Instale as dependências:
```bash
npm install
```

## Executando a Aplicação

### Backend

1. Certifique-se de estar na pasta `backend` com o ambiente virtual ativado

2. Execute o servidor:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

O backend estará disponível em: `http://localhost:8000`

- Documentação interativa (Swagger): `http://localhost:8000/docs`
- Documentação alternativa (ReDoc): `http://localhost:8000/redoc`

### Frontend

1. Em um novo terminal, navegue até a pasta `frontend`

2. Execute o servidor de desenvolvimento:
```bash
npm run dev
```

O frontend estará disponível em: `http://localhost:3000`

## Uso

1. Abra o navegador em `http://localhost:3000`
2. Arraste e solte um arquivo PDF ou clique para selecioná-lo
3. Clique em "Comprimir PDF"
4. Aguarde o processamento
5. Visualize as estatísticas de compressão
6. Baixe o arquivo comprimido

## Funcionalidades

- Upload de arquivos PDF via drag & drop ou seleção
- Compressão automática de PDFs
- Visualização de estatísticas:
  - Tamanho original
  - Tamanho comprimido
  - Taxa de compressão
- Download do arquivo comprimido
- Interface moderna e responsiva
- Feedback visual durante o processamento

## API Endpoints

### POST /api/compress
Comprime um arquivo PDF

**Request:**
- Method: POST
- Content-Type: multipart/form-data
- Body: file (PDF)

**Response:**
```json
{
  "filename": "document_compressed_uuid.pdf",
  "original_size": 1048576,
  "compressed_size": 524288,
  "compression_ratio": 50.0,
  "download_url": "/api/download/document_compressed_uuid.pdf"
}
```

### GET /api/download/{filename}
Baixa um arquivo PDF comprimido

**Request:**
- Method: GET
- Params: filename (string)

**Response:**
- Content-Type: application/pdf
- Body: arquivo PDF

## Desenvolvimento

### Backend - Padrão MVC

- **Models**: Definem a estrutura de dados (Pydantic)
- **Controllers**: Manipulam requisições e respostas
- **Services**: Contêm a lógica de negócio (compressão)
- **Routes**: Definem os endpoints da API

### Frontend - Componentes

- **FileUpload**: Componente de upload com drag & drop
- **ProgressBar**: Barra de progresso animada
- **ResultCard**: Exibição de resultados
- **Header/Footer**: Layout da aplicação

## Build para Produção

### Backend
```bash
# Instalar dependências
pip install -r requirements.txt

# Executar com Gunicorn (produção)
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

### Frontend
```bash
# Build
npm run build

# Preview
npm run preview
```

## Melhorias Futuras

- [ ] Suporte para múltiplos arquivos
- [ ] Diferentes níveis de compressão
- [ ] Autenticação de usuários
- [ ] Histórico de compressões
- [ ] Compressão em lote
- [ ] Suporte para outros formatos
- [ ] Armazenamento em nuvem

## Licença

MIT

## Autor

Desenvolvido com FastAPI e React
