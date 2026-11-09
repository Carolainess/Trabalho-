# 📚 Biblioteca Simples

Aplicação web para gerenciar o acervo de uma pequena biblioteca: cadastrar
livros, buscar por título ou autor, editar, excluir e controlar os
empréstimos (marcar um livro como emprestado e depois como devolvido).

Fiz este projeto como trabalho prático da disciplina de Contêineres no curso
de Ciência da Computação da FEMA (Assis/SP). A ideia do trabalho era montar
uma aplicação com **frontend, backend e banco de dados, cada um no seu
próprio contêiner**, todos subindo juntos com Docker Compose.

## Funcionalidades

- Cadastro de livros com título, autor, ISBN e ano de publicação
- Busca por título ou autor (a lista atualiza enquanto você digita)
- Filtro por situação: todos, só disponíveis ou só emprestados
- Edição e exclusão de livros
- Registro de empréstimo e devolução com um clique
- O banco já começa com alguns livros de exemplo, pra tela não abrir vazia

## Tecnologias

| Serviço    | Tecnologia                               | O que faz                                                   |
|------------|------------------------------------------|-------------------------------------------------------------|
| `frontend` | HTML, CSS e JavaScript puro + Nginx 1.27 | Interface que roda no navegador                             |
| `backend`  | Python 3.12 + Flask + psycopg2           | API REST com as regras de negócio, conversa com o banco     |
| `database` | PostgreSQL 16                            | Guarda os dados dos livros                                  |

## Arquitetura

```
Navegador  →  frontend (Nginx, porta 8080)
Navegador  →  backend  (Flask, porta 5000)  →  database (PostgreSQL, porta 5432)
```

A página é entregue pelo contêiner do Nginx, mas o JavaScript roda no
navegador de quem está usando. Por isso o navegador chama a API pela porta
publicada no computador (`localhost:5000`), e não pelo nome interno do
serviço. Já o backend, que está dentro da rede do Docker, acessa o banco
direto pelo nome `database`.

## Estrutura do projeto

```
biblioteca-docker/
├── docker-compose.yml      # sobe os 3 serviços juntos
├── .env.example            # modelo das variáveis de ambiente
├── database/
│   ├── Dockerfile
│   └── init.sql            # cria a tabela "livros" e insere os exemplos
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app.py              # API Flask
└── frontend/
    ├── Dockerfile
    ├── index.html
    ├── style.css
    └── script.js
```

## Conceitos de Docker usados

- **Um Dockerfile por serviço:** cada pasta (`database`, `backend`,
  `frontend`) tem o seu, com a imagem base e o que precisa ser copiado ou
  instalado.
- **Docker Compose:** o `docker-compose.yml` sobe os três contêineres de uma
  vez, na ordem certa (`depends_on`), com as portas e variáveis de cada um.
- **Rede entre contêineres:** o Compose cria a rede `rede_biblioteca`, e
  dentro dela o backend encontra o banco só pelo nome do serviço
  (`DB_HOST=database`), sem precisar de IP.
- **Volume:** o volume `dados_biblioteca` guarda os dados do PostgreSQL fora
  do contêiner, então os livros cadastrados continuam lá mesmo depois de um
  `docker compose down`.
- **Variáveis de ambiente:** usuário, senha e nome do banco ficam no arquivo
  `.env`, e não escritos no código.

## Como rodar

### Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows
  ou macOS) ou Docker Engine + Docker Compose (Linux)
- Git, para clonar o repositório

### 1. Clone o repositório

```bash
git clone https://github.com/<seu-usuario>/biblioteca-docker.git
cd biblioteca-docker
```

### 2. Crie o arquivo `.env`

O `.env` não vai para o GitHub (ele está no `.gitignore`), então é preciso
criar o seu a partir do modelo:

```bash
# Linux / macOS
cp .env.example .env
```

```powershell
# Windows (PowerShell)
copy .env.example .env
```

Os valores que já vêm no modelo funcionam normalmente. Se quiser, troque a
senha antes de subir.

### 3. Suba os contêineres

```bash
docker compose up --build
```

> Em versões mais antigas do Docker o comando é `docker-compose up --build`
> (com hífen).

Na primeira vez o Docker monta as três imagens, cria a rede e o volume e
sobe os contêineres na ordem banco → backend → frontend. O PostgreSQL roda o
`init.sql` sozinho e já cria a tabela com os livros de exemplo.

### 4. Acesse

- Aplicação: <http://localhost:8080>
- API: <http://localhost:5000/livros>

### 5. Para parar

Aperte `Ctrl+C` no terminal onde os contêineres estão rodando, ou, em outro
terminal:

```bash
docker compose down
```

Isso remove os contêineres, mas mantém o volume. Na próxima vez que subir,
os livros continuam lá.

## Endpoints da API

| Método | Rota                       | Descrição                                                        |
|--------|----------------------------|------------------------------------------------------------------|
| GET    | `/livros`                  | Lista os livros (aceita `?busca=` e `?disponivel=true\|false`)   |
| GET    | `/livros/<id>`             | Mostra um livro                                                  |
| POST   | `/livros`                  | Cadastra um livro (`titulo` e `autor` são obrigatórios)          |
| PUT    | `/livros/<id>`             | Atualiza título, autor, ISBN e ano                               |
| PATCH  | `/livros/<id>/emprestar`   | Marca o livro como emprestado                                    |
| PATCH  | `/livros/<id>/devolver`    | Marca o livro como disponível de novo                            |
| DELETE | `/livros/<id>`             | Remove o livro do acervo                                         |
| GET    | `/health`                  | Confere se a API está no ar                                      |

Exemplo de cadastro pelo terminal:

```bash
curl -X POST http://localhost:5000/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo": "Vidas Secas", "autor": "Graciliano Ramos", "ano_publicacao": 1938}'
```

## Problemas comuns

- **`port is already allocated`:** outro programa já está usando a porta
  8080 ou 5000 no seu computador. Feche esse programa ou troque o número da
  esquerda no `docker-compose.yml` (por exemplo `"8081:80"`) e acesse pela
  porta nova.
- **O banco não sobe e reclama de senha:** provavelmente o arquivo `.env`
  não foi criado. Volte ao passo 2.
- **A página abre, mas a lista de livros não carrega:** veja se o contêiner
  `biblioteca_backend` está rodando com `docker ps` e se
  <http://localhost:5000/livros> responde no navegador.
- **Quero começar do zero, apagando os dados:**
  ```bash
  docker compose down -v
  docker compose up --build
  ```
  O `-v` apaga o volume, então o `init.sql` roda de novo na próxima subida.

## Autora

Carolaine Silva Serrano — Ciência da Computação, FEMA
