# VAI E VOLTA

> **Compartilhe o que você tem. Encontre o que precisa.**

Plataforma web de empréstimo de objetos entre estudantes da faculdade. Quem tem um livro, uma calculadora, um jaleco ou um carregador parado anuncia, e quem precisa pede emprestado por alguns dias.

Projeto desenvolvido em dupla para a disciplina, usando **ASP.NET Core MVC, Entity Framework Core, PostgreSQL e Docker**.

---

## 1. Objetivo

Criar uma plataforma simples e bonita onde estudantes possam:

- anunciar objetos que podem emprestar, com foto e descrição;
- encontrar objetos no catálogo, pesquisando pelo nome ou filtrando por categoria;
- pedir um objeto emprestado e combinar a data de devolução;
- aprovar ou recusar os pedidos que recebem;
- acompanhar quem está com o quê.

## 2. Problema que resolve

Todo semestre a mesma cena se repete: alguém precisa de uma calculadora científica só para a prova, esqueceu o jaleco no dia da aula de laboratório ou precisa de um livro caro que vai usar por duas semanas. Enquanto isso, outro colega tem exatamente esse objeto parado em casa.

Hoje isso é resolvido em grupos de WhatsApp: a mensagem se perde, ninguém lembra com quem ficou o livro e não existe controle de devolução. O VAI E VOLTA organiza isso: cada objeto tem dono, status e histórico de empréstimos.

## 3. Tecnologias

| Camada | Tecnologia |
|---|---|
| Linguagem | C# (.NET 8) |
| Framework web | ASP.NET Core MVC (Controllers + Views Razor) |
| API | API REST integrada ao próprio ASP.NET Core (`[ApiController]`) |
| Banco de dados | PostgreSQL 16 |
| Acesso a dados | Entity Framework Core 8 + Npgsql (com migrations) |
| Login | Autenticação por cookie + senha com hash (PasswordHasher) |
| Interface | HTML5, CSS3, JavaScript, Bootstrap 5.3, Bootstrap Icons, fonte Plus Jakarta Sans |
| Contêineres | Docker e Docker Compose |
| Nuvem | Configuração pronta para Render.com (`render.yaml`) |

**Identidade visual:** azul-marinho (`#1b3561`), laranja (`#f37021`) e branco, as mesmas cores do Portal Acadêmico da FEMA. As cores ficam em variáveis no topo do `wwwroot/css/site.css`, então dá para trocar todas de uma vez.

Todas as bibliotecas de interface estão dentro do projeto (`wwwroot/lib`), então o site funciona mesmo sem internet.

## 4. Arquitetura

Usamos **uma única aplicação ASP.NET Core MVC** (sem microsserviços). Ela atende tanto as páginas do site quanto a API REST, e conversa com o PostgreSQL pelo Entity Framework.

```
            Navegador (site)            Postman / outro app
                   │                           │
                   │ páginas HTML              │ JSON
                   ▼                           ▼
   ┌───────────────────────────────────────────────────────┐
   │             Aplicação ASP.NET Core MVC                │
   │                                                       │
   │  Controllers (MVC)          Controllers/Api (REST)    │
   │  Home, Conta, Objetos,      /api/objetos              │
   │  Emprestimos, Admin         /api/emprestimos          │
   │          │                         │                  │
   │          └────────┬────────────────┘                  │
   │                   ▼                                   │
   │      Services: EmprestimoService (regras)             │
   │                FotoService (upload de fotos)          │
   │                   │                                   │
   │      Data: AppDbContext (Entity Framework Core)       │
   └───────────────────┬───────────────────────────────────┘
                       ▼
               ┌───────────────┐
               │  PostgreSQL   │
               └───────────────┘
```

As regras de empréstimo ficam no `EmprestimoService`, e tanto as telas quanto a API usam ele. Assim a regra é escrita uma vez só: aprovar um pedido pelo site ou pela API tem exatamente o mesmo efeito.

### Organização das pastas

```
vaievolta/
├── Dockerfile                 → imagem da aplicação
├── docker-compose.yml         → aplicação + PostgreSQL
├── render.yaml                → publicação na nuvem (Render)
├── README.md
├── ROTEIRO-APRESENTACAO.md
└── VaiEVolta/
    ├── Program.cs             → configuração (banco, login, porta da nuvem)
    ├── Controllers/
    │   ├── HomeController.cs        → página inicial, página da API, erros
    │   ├── ContaController.cs       → cadastro, login, logout, perfil
    │   ├── ObjetosController.cs     → catálogo, detalhes, cadastrar/editar/excluir
    │   ├── EmprestimosController.cs → solicitar, aprovar, recusar, devolver
    │   ├── AdminController.cs       → painel do administrador
    │   └── Api/                     → endpoints REST (JSON)
    ├── Models/                → Usuario, Objeto, Emprestimo (+ ViewModels e DTOs)
    ├── Data/                  → AppDbContext, conexão e dados fictícios
    ├── Migrations/            → criação das tabelas
    ├── Services/              → regras de empréstimo e upload de fotos
    ├── Views/                 → telas Razor
    └── wwwroot/               → CSS, JS, imagens, bibliotecas
```

## 5. Banco de dados

São só **três entidades**:

```
┌──────────────────┐        ┌──────────────────────┐        ┌──────────────────────────┐
│     Usuario      │        │        Objeto        │        │        Emprestimo        │
├──────────────────┤        ├──────────────────────┤        ├──────────────────────────┤
│ Id (PK)          │◄──┐    │ Id (PK)              │◄───────│ ObjetoId (FK)            │
│ Nome             │   └────│ DonoId (FK)          │        │ Id (PK)                  │
│ Email (único)    │        │ Nome                 │   ┌────│ SolicitanteId (FK)       │
│ SenhaHash        │◄───────┼──────────────────────┼───┘    │ Mensagem                 │
│ Curso            │        │ Descricao            │        │ DataSolicitacao          │
│ Telefone         │        │ Categoria            │        │ DataPrevistaDevolucao    │
│ Perfil           │        │ FotoUrl              │        │ DataResposta             │
│ CriadoEm         │        │ Disponivel           │        │ DataDevolucao            │
└──────────────────┘        │ CriadoEm             │        │ Status                   │
                            └──────────────────────┘        └──────────────────────────┘
```

**Relacionamentos**

- Um **Usuario** pode ter vários **Objetos** (ele é o dono).
- Um **Objeto** pode ter vários **Emprestimos** ao longo do tempo (histórico).
- Um **Usuario** pode fazer vários **Emprestimos** (ele é o solicitante).

**Enumerações**

- `Perfil`: Usuario ou Administrador.
- `Categoria`: Livros, Eletrônicos, Material de estudo, Laboratório, Esporte e lazer, Outros.
- `StatusEmprestimo`: Aguardando aprovação, Emprestado, Devolvido, Recusado.

**Situação do objeto** (aparece nos cards): **Disponível**, **Aguardando aprovação**, **Emprestado** ou **Devolvido** (no histórico). Ela é calculada a partir dos empréstimos e muda sozinha:

| Ação | O que acontece no banco |
|---|---|
| Alguém solicita | cria um Emprestimo com status *Aguardando aprovação* |
| Dono aprova | status vira *Emprestado*, o objeto fica `Disponivel = false` e outros pedidos pelo mesmo objeto são recusados |
| Dono recusa | status vira *Recusado* |
| Dono confirma devolução | status vira *Devolvido* e o objeto volta a `Disponivel = true` |

**Migrations e dados fictícios**

A migration `CriacaoInicial` cria as tabelas. Quando a aplicação inicia, ela aplica as migrations sozinha (`Database.MigrateAsync()`) e, se o banco estiver vazio, insere 5 usuários, 10 objetos com ilustrações e alguns empréstimos em vários status (`Data/SeedData.cs`).

## 6. Contas de demonstração

| Perfil | E-mail | Senha |
|---|---|---|
| Administrador | admin@vaievolta.com | Admin@123 |
| Estudante | carol@vaievolta.com | Senha@123 |
| Estudante | ana@vaievolta.com | Senha@123 |
| Estudante | lucas@vaievolta.com | Senha@123 |
| Estudante | bruna@vaievolta.com | Senha@123 |

Na tela de login há botões que preenchem essas contas automaticamente.

## 7. Funcionalidades

- **Página inicial:** apresentação, como funciona, números da plataforma e destaques.
- **Cadastro, login e logout**, com validação dos formulários e senha guardada como hash.
- **Perfil:** dados da pessoa e resumo (objetos anunciados, empréstimos feitos).
- **Usuário x administrador:** o administrador tem um painel próprio, vê todos os empréstimos, pode aprovar pedidos, editar ou excluir qualquer objeto e promover usuários.
- **Objetos:** cadastrar com foto (JPG, PNG ou WEBP até 5 MB), editar, pausar o anúncio e excluir.
- **Catálogo:** cards com foto, pesquisa por nome, filtro por categoria e chave "Só disponíveis".
- **Detalhes:** foto grande, descrição, dono, quantas vezes já foi emprestado e o formulário de solicitação.
- **Empréstimos:** abas "Recebidos" e "Meus pedidos", com aprovar, recusar, confirmar devolução e cancelar pedido.
- **Proteção das rotas:** páginas de empréstimos e cadastro exigem login; o painel exige perfil de administrador; só o dono (ou o admin) altera um objeto.
- **Tratamento de erros:** páginas amigáveis para 404, 403 e 500, e mensagens de erro claras nas ações.

## 8. Endpoints REST

Base: `http://localhost:8080`. Todas as respostas são em JSON. Os endpoints com 🔒 exigem login (a API usa o mesmo cookie do site; para testar no Postman, chame primeiro `POST /api/auth/login`).

Também dá para testar tudo pelo próprio site, abrindo o endereço **http://localhost:8080/Home/Api** (a página não aparece no menu, só pelo endereço).

### Objetos

| Método | Endpoint | Descrição | Respostas |
|---|---|---|---|
| GET | `/api/objetos` | Lista objetos. Filtros: `?busca=`, `?categoria=`, `?disponiveis=true` | 200 |
| GET | `/api/objetos/{id}` | Busca um objeto | 200, 404 |
| POST 🔒 | `/api/objetos` | Cadastra um objeto | 201, 400, 401 |
| PUT 🔒 | `/api/objetos/{id}` | Atualiza (só dono ou admin) | 200, 400, 403, 404 |
| DELETE 🔒 | `/api/objetos/{id}` | Exclui (só dono ou admin; não exclui se estiver emprestado) | 204, 403, 404, 409 |

Exemplo de corpo para POST/PUT:

```json
{
  "nome": "Régua T de desenho técnico",
  "descricao": "Régua T de 80 cm, ótima para Desenho Técnico.",
  "categoria": "MaterialDeEstudo",
  "disponivel": true
}
```

### Empréstimos

| Método | Endpoint | Descrição | Respostas |
|---|---|---|---|
| GET 🔒 | `/api/emprestimos` | Empréstimos em que você participa (admin vê todos). Filtro: `?status=Emprestado` | 200 |
| GET 🔒 | `/api/emprestimos/{id}` | Busca um empréstimo | 200, 403, 404 |
| POST 🔒 | `/api/emprestimos` | Solicita um empréstimo | 201, 400 |
| PUT 🔒 | `/api/emprestimos/{id}/aprovar` | Aprova (dono ou admin) | 200, 400 |
| PUT 🔒 | `/api/emprestimos/{id}/recusar` | Recusa (dono ou admin) | 200, 400 |
| PUT 🔒 | `/api/emprestimos/{id}/devolver` | Confirma a devolução | 200, 400 |
| DELETE 🔒 | `/api/emprestimos/{id}` | Cancela um pedido ainda aguardando (quem pediu) | 204, 400 |

```json
{
  "objetoId": 4,
  "dataPrevistaDevolucao": "2026-11-20",
  "mensagem": "Posso pegar para a aula de quinta?"
}
```

### Autenticação

| Método | Endpoint | Descrição |
|---|---|---|
| POST | `/api/auth/login` | `{ "email": "...", "senha": "..." }` devolve o cookie de sessão |
| POST | `/api/auth/logout` | Encerra a sessão |
| GET 🔒 | `/api/auth/eu` | Mostra quem está logado |

### Status

`GET /health` responde `Healthy` quando a aplicação e o banco estão no ar (usado pela nuvem).

## 9. Como executar com Docker

**Pré-requisito:** Docker Desktop instalado e aberto.

```bash
# dentro da pasta vaievolta (onde está o docker-compose.yml)
docker compose up --build
```

Na primeira vez demora alguns minutos para baixar as imagens. Quando aparecer `Banco de dados pronto.` no terminal, acesse:

**http://localhost:8080**

Comandos úteis:

```bash
docker ps                          # ver os 2 contêineres rodando
docker compose logs -f app         # ver o log da aplicação
docker compose down                # parar
docker compose down -v             # parar e apagar o banco (volta aos dados fictícios)
```

### Rodar sem Docker (Visual Studio / VS Code)

1. Tenha o .NET 8 SDK e um PostgreSQL rodando na porta 5432 (usuário e senha `postgres`).
   Dica: dá para subir só o banco com `docker compose up banco`.
2. Na pasta `VaiEVolta`: `dotnet run`
3. Acesse o endereço que aparecer no terminal.

### Migrations

A migration inicial já está na pasta `Migrations`. Se vocês alterarem algum Model, criem uma nova:

```bash
dotnet tool install --global dotnet-ef        # só na primeira vez
dotnet ef migrations add NomeDaAlteracao
```

Se der qualquer problema com a migration inicial, basta apagar a pasta `Migrations` e gerar de novo com `dotnet ef migrations add CriacaoInicial`.

## 10. Os três conceitos acadêmicos

### Conceito 1 — API REST

**Onde está:** `Controllers/Api/ObjetosApiController.cs`, `EmprestimosApiController.cs` e `AuthApiController.cs`.

- Cada recurso tem uma URL (`/api/objetos`, `/api/emprestimos`).
- O verbo HTTP indica a ação: **GET** consulta, **POST** cria, **PUT** atualiza e **DELETE** remove.
- Os dados vão e voltam em **JSON**.
- Os **códigos de status** dizem o que aconteceu: 200 OK, 201 Created, 204 No Content, 400 dados inválidos, 401 sem login, 403 sem permissão, 404 não encontrado e 409 conflito (por exemplo, excluir um objeto que está emprestado).
- A API é **stateless**: cada requisição carrega o cookie que identifica quem está chamando.
- Há uma página escondida do menu (**/Home/Api**) que documenta os endpoints e deixa testar na hora.

### Conceito 2 — Docker

**Onde está:** `Dockerfile`, `docker-compose.yml` e `.dockerignore`.

- O `Dockerfile` tem **duas etapas**: a primeira usa a imagem do SDK para compilar; a segunda usa só o runtime do ASP.NET, deixando a imagem final menor.
- O `docker-compose.yml` sobe **dois contêineres**: `app` (o site) e `banco` (PostgreSQL 16).
- O `healthcheck` faz a aplicação esperar o banco ficar pronto antes de iniciar.
- Os **volumes** guardam os dados do banco, as fotos enviadas e as chaves do login, então nada se perde quando o contêiner é recriado.
- A string de conexão é passada por **variável de ambiente** (`ConnectionStrings__Padrao`), sem precisar mudar código.

### Conceito 3 — Computação em nuvem

**Onde está:** `render.yaml`, `Program.cs` e `Data/ConexaoBanco.cs`.

A aplicação está preparada para ser publicada em um provedor de nuvem (PaaS) como Render, Railway ou Azure App Service:

- **Configuração por variáveis de ambiente** (princípio do *12-Factor App*): a porta vem de `PORT` e o banco de `DATABASE_URL`, que é o formato que esses serviços fornecem.
- **Health check** em `/health`: a nuvem consulta esse endereço para saber se o site está saudável e reiniciá-lo se precisar.
- **Proxy reverso / HTTPS:** a nuvem entrega o site com HTTPS na frente da aplicação. O `UseForwardedHeaders` faz o ASP.NET entender isso.
- **Banco gerenciado:** em vez de instalar o PostgreSQL, usamos o banco oferecido pelo provedor.
- **Infraestrutura como código:** o `render.yaml` descreve o site e o banco. O Render lê esse arquivo e cria tudo sozinho.
- **Migrations automáticas na inicialização**: ao publicar, as tabelas e os dados de demonstração são criados sem nenhum passo manual.

#### Passo a passo para publicar no Render (gratuito)

1. Suba esta pasta para um repositório no GitHub.
2. Crie uma conta em [render.com](https://render.com) e entre com o GitHub.
3. Clique em **New → Blueprint** e escolha o repositório.
4. O Render lê o `render.yaml`, cria o PostgreSQL e o site e liga os dois.
5. Aguarde o deploy (alguns minutos). O site fica em `https://vaievolta.onrender.com` (ou nome parecido).

> No plano gratuito o site "dorme" depois de um tempo sem acesso e demora uns 30 segundos para acordar. As fotos enviadas ficam no disco do contêiner e podem sumir quando ele é recriado; os dados do banco continuam salvos. Para a apresentação, o ideal é abrir o site alguns minutos antes.

## 11. Segurança (resumo)

- Senhas guardadas com **hash** (nunca em texto puro).
- Formulários protegidos contra **CSRF** (token antifalsificação em todos os POST).
- Rotas protegidas com `[Authorize]` e `[Authorize(Roles = "Administrador")]`.
- Cada ação confere se a pessoa é dona do objeto antes de alterar.
- Upload aceita só imagens e no máximo 5 MB; o arquivo recebe um nome aleatório.
- Redirecionamentos só para endereços do próprio site.

---

Projeto acadêmico · FEMA · 2026
