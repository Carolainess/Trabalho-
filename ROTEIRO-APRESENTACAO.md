# Roteiro de apresentação — VAI E VOLTA

**Tempo total:** cerca de 12 minutos + perguntas
**Pessoa 1:** apresenta o problema, o site e o banco de dados
**Pessoa 2:** apresenta os empréstimos e os três conceitos (API REST, Docker e nuvem)

---

## Antes de começar (checklist)

- [ ] Rodar `docker compose down -v` e depois `docker compose up --build` para começar com os dados fictícios limpos.
- [ ] Abrir **http://localhost:8080** no navegador.
- [ ] Deixar duas janelas prontas: uma normal e uma anônima (para ter duas pessoas logadas ao mesmo tempo).
- [ ] Deixar o VS Code aberto com `docker-compose.yml`, `Dockerfile` e `Controllers/Api/ObjetosApiController.cs`.
- [ ] Ter uma foto no computador para cadastrar um objeto ao vivo.
- [ ] Se for mostrar a versão online, abrir o link do Render uns 5 minutos antes (ele "dorme").

---

## Parte 1 — Pessoa 1 (cerca de 5 min)

### 1. Abertura e problema (1 min)

> "Todo semestre alguém precisa de uma calculadora científica só para a prova, ou esquece o jaleco no dia do laboratório. E quase sempre tem um colega com esse objeto parado em casa. Hoje isso é resolvido no grupo do WhatsApp, a mensagem se perde e ninguém lembra com quem ficou o livro.
> O VAI E VOLTA organiza isso: é uma plataforma de empréstimo de objetos entre estudantes."

Mostrar a **página inicial**: slogan, "Como funciona" (os 4 passos) e os destaques.

### 2. Tecnologias e arquitetura (1 min)

> "Fizemos tudo em C# com ASP.NET Core MVC, numa aplicação só. O banco é PostgreSQL e a gente acessa ele pelo Entity Framework. A parte visual usa Bootstrap 5."

Mostrar rapidamente o diagrama de arquitetura no README e as pastas Controllers, Models, Views, Data e Services.

### 3. Banco de dados (1 min)

> "O banco tem só três tabelas: Usuario, Objeto e Emprestimo. Um usuário tem vários objetos, e cada objeto pode ter vários empréstimos ao longo do tempo, o que vira o histórico. As tabelas são criadas por migration e, quando o sistema sobe, ele já coloca dados de exemplo."

Mostrar `Models/Objeto.cs` e o diagrama do README.

### 4. Demonstração do site (2 min)

1. Ir em **Objetos**: mostrar os cards, **pesquisar** "livro" e clicar no filtro **Eletrônicos**.
2. Clicar em **Criar conta** e cadastrar uma pessoa nova (mostrar que, se deixar em branco, aparecem as mensagens de validação).
3. Clicar em **Anunciar**, cadastrar um objeto **com foto** e mostrar que ele já aparece no catálogo como **Disponível**.
4. Mostrar o **perfil** no menu do avatar.

> "Agora a [nome da Pessoa 2] vai mostrar a parte principal: o empréstimo."

---

## Parte 2 — Pessoa 2 (cerca de 7 min)

### 5. Fluxo de empréstimo (2 min)

Na **janela anônima**, entrar como **Lucas** (botão "Lucas" na tela de login).

1. Abrir o objeto que a Pessoa 1 acabou de cadastrar e clicar em **Enviar solicitação** com uma mensagem.
   > "O status mudou para **Aguardando aprovação**."
2. Voltar para a **janela da Pessoa 1**, atualizar: aparece a **bolinha** no menu Empréstimos.
3. Em **Empréstimos → Recebidos**, clicar em **Aprovar**.
   > "Quando o dono aprova, o objeto sai de disponível sozinho e fica **Emprestado**. Se outras pessoas tinham pedido o mesmo objeto, os pedidos delas são recusados automaticamente."
4. Abrir o catálogo e mostrar o selo **Emprestado**.
5. Clicar em **Recebi de volta**: o objeto volta a ficar **Disponível** e o empréstimo vai para **Devolvido**.

Rapidamente: entrar como **Administrador** e mostrar o **painel Admin** (números, todos os empréstimos, lista de usuários).
> "O administrador vê tudo e pode aprovar ou excluir qualquer coisa. Um usuário comum que tenta abrir essa página recebe 'Acesso não permitido'."

### 6. Conceito 1 — API REST (2 min)

Ainda logada como **Administrador**, digitar no navegador **http://localhost:8080/Home/Api** (essa página não fica no menu).

> "Tudo o que o site faz também está disponível em JSON pela API REST. Cada recurso tem uma URL e o verbo HTTP diz a ação: GET consulta, POST cria, PUT atualiza e DELETE remove."

1. Clicar em `GET /api/objetos`: mostrar o JSON.
2. Clicar em `POST /api/objetos` e enviar: **201 Created**.
3. Escolher `DELETE`, trocar a URL para `/api/objetos/2` (o livro de Algoritmos, que está emprestado) e enviar: aparece **409 Conflict**.
   > "A API responde com o código certo para cada situação: 404 quando não existe, 401 sem login, 403 sem permissão e 409 quando a ação não faz sentido."

Mostrar em 15 segundos o `ObjetosApiController.cs`, apontando os atributos `[HttpGet]`, `[HttpPost]`, `[HttpPut]` e `[HttpDelete]`.

### 7. Conceito 2 — Docker (1 min 30 s)

Mostrar o `docker-compose.yml` e rodar no terminal:

```bash
docker ps
```

> "São dois contêineres: um com a aplicação e outro com o PostgreSQL. Com um único comando, `docker compose up`, qualquer pessoa sobe o sistema inteiro sem instalar .NET nem PostgreSQL. O banco tem um healthcheck, então o site só inicia quando o banco está pronto, e os volumes guardam os dados mesmo se o contêiner for apagado."

Mostrar o `Dockerfile`:
> "Ele tem duas etapas: uma compila o projeto e a outra só roda, por isso a imagem final fica menor."

### 8. Conceito 3 — Computação em nuvem (1 min 30 s)

Mostrar o `render.yaml` e o trecho do `Program.cs` com `PORT` e `DATABASE_URL`.

> "A aplicação está pronta para a nuvem. Em vez de deixar endereço do banco e porta escritos no código, ela lê tudo de variáveis de ambiente, que é o jeito que serviços como Render, Railway e Azure trabalham. Tem o endereço `/health`, que a nuvem usa para saber se o site está no ar, e o `render.yaml` descreve o site e o banco: o Render lê esse arquivo e cria tudo sozinho. Ao publicar, as migrations rodam e o banco já nasce com as tabelas."

Abrir **http://localhost:8080/health** (ou o link publicado, se tiverem feito o deploy).

### 9. Encerramento (30 s) — as duas juntas

> **Pessoa 1:** "Então o VAI E VOLTA resolve um problema real do dia a dia da faculdade..."
> **Pessoa 2:** "...usando API REST, Docker e uma aplicação preparada para a nuvem. Obrigada!"

---

## Perguntas que o professor pode fazer

**Por que uma aplicação só e não microsserviços?**
Porque o sistema é pequeno. Dividir em vários serviços traria complexidade (vários bancos, comunicação entre serviços) sem benefício real. A API REST já permite que outros sistemas usem os dados.

**Como a disponibilidade muda sozinha?**
No `EmprestimoService`. Ao aprovar, ele marca `Disponivel = false`; ao confirmar a devolução, marca `true` de novo. O site e a API usam o mesmo serviço.

**Como funciona o login?**
Autenticação por cookie do ASP.NET Core. A senha é salva como hash. O cookie guarda o id e o perfil (Usuario ou Administrador), e as rotas são protegidas com `[Authorize]`.

**O que é uma migration?**
Um arquivo que descreve as mudanças no banco em C#. O Entity Framework transforma em SQL e cria ou altera as tabelas. Assim o banco evolui junto com o código.

**Qual a diferença entre a imagem e o contêiner?**
A imagem é o "molde" gerado pelo Dockerfile. O contêiner é a imagem rodando. O compose cria um contêiner a partir da nossa imagem e outro a partir da imagem oficial do PostgreSQL.

**O que acontece se o banco cair?**
O `/health` passa a responder "Unhealthy" e a nuvem percebe. Ao iniciar, a aplicação também tenta se conectar ao banco várias vezes antes de desistir.
