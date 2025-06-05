# Trabalho Final - DevOps: Containerização e Orquestração de Sistema de Chat

Este documento detalha a solução desenvolvida para o trabalho final da disciplina de DevOps, focando na containerização e orquestração de um sistema de chat baseado em microserviços.




## 🚀 Comandos de Build

Para construir as imagens Docker customizadas para cada microserviço, navegue até o diretório raiz do projeto (`trabalho_final`) onde o arquivo `docker-compose.yml` está localizado. O Docker Compose gerenciará o processo de build automaticamente ao iniciar os serviços, mas você pode construir as imagens explicitamente usando o seguinte comando. Este comando lerá as definições de `build` dentro do `docker-compose.yml` e executará os `Dockerfiles` correspondentes localizados nos subdiretórios `auth-api`, `record-api` e `receive-send-api`.

```bash
# Execute no diretório /home/ubuntu/trabalho_final/
docker compose build
# Ou, se estiver usando a versão v1 do Docker Compose:
# docker-compose build
```

Este processo garantirá que todas as dependências especificadas nos Dockerfiles sejam baixadas e instaladas, e que as imagens estejam prontas para serem executadas como containers.




## ⚙️ Comandos de Deploy

O deploy da aplicação é simplificado pelo uso do script `deploy.sh`, que orquestra a inicialização dos serviços definidos no `docker-compose.yml`. Para executar o deploy, certifique-se de que você está no diretório raiz do projeto (`trabalho_final`) e que o script `deploy.sh` possui permissão de execução. Caso não tenha, conceda a permissão com `chmod +x deploy.sh`. Em seguida, execute o script da seguinte forma:

```bash
# Execute no diretório /home/ubuntu/trabalho_final/
./deploy.sh
```

Este script realizará as seguintes ações:
1.  Verificará a presença do Docker e Docker Compose no ambiente.
2.  Navegará para o diretório correto.
3.  Carregará variáveis de ambiente de um arquivo `.env`, se existente.
4.  Executará `docker compose build` (ou `docker-compose build`) para construir ou atualizar as imagens, se necessário.
5.  Executará `docker compose up -d` (ou `docker-compose up -d`) para iniciar todos os serviços em background.
6.  Aguardará e verificará o status de saúde dos serviços essenciais (Redis e PostgreSQL) que possuem `healthcheck` configurado no `docker-compose.yml`.
7.  Exibirá logs recentes dos containers para verificação inicial.
8.  Informará os endpoints disponíveis para acesso às APIs e serviços.

Para parar todos os serviços e remover os containers, redes e volumes (exceto os volumes nomeados, que persistem por padrão), utilize o comando:

```bash
# Execute no diretório /home/ubuntu/trabalho_final/
docker compose down
# Ou, se estiver usando a versão v1 do Docker Compose:
# docker-compose down
```




## 📊 Diagrama da Arquitetura e Fluxos de Rede

A arquitetura da solução é composta por múltiplos containers Docker orquestrados pelo Docker Compose, comunicando-se através de uma rede interna customizada (`chat_network`). Abaixo, apresentamos uma descrição textual dos componentes e suas interações. Para uma visualização gráfica, recomenda-se o uso de ferramentas como Mermaid ou draw.io, baseando-se na descrição a seguir.

*   **Rede:** Uma rede do tipo `bridge` chamada `chat_network` isola os containers da aplicação, permitindo a comunicação entre eles através dos nomes dos serviços definidos no `docker-compose.yml`.
*   **Cliente (Usuário/Postman):** Interage com as APIs expostas através das portas mapeadas no host (e.g., `localhost:8080`, `localhost:3000`, `localhost:5001`).
*   **Auth-API (PHP):** Container `auth_api_php`, executando em Apache/PHP. Recebe requisições de registro e login. Conecta-se ao serviço `db` (PostgreSQL) na rede `chat_network` para persistir e consultar dados de usuários.
*   **Receive-Send-API (Node.js):** Container `receive_send_api_node`, executando Node.js. Recebe requisições para enviar e receber mensagens. Interage com o serviço `redis` para operações rápidas (como notificações ou status online, dependendo da implementação) e potencialmente com `auth-api` para validação de token e `record-api` para solicitar o armazenamento de mensagens. Comunica-se com outros serviços via `chat_network` usando os nomes dos serviços (e.g., `http://auth-api`, `http://record-api:5001`, `redis`).
*   **Record-API (Python):** Container `record_api_python`, executando Python (Flask/FastAPI). Responsável por armazenar e recuperar o histórico de mensagens. Conecta-se ao serviço `db` (PostgreSQL) para persistência de longo prazo das mensagens e ao serviço `redis` para caching ou outras operações, se aplicável. Comunica-se via `chat_network`.
*   **Database (PostgreSQL):** Container `postgres_db`, executando PostgreSQL. Armazena dados persistentes (usuários, mensagens) no volume nomeado `postgres_data`. Acessível internamente na rede `chat_network` pelo nome `db` na porta `5432`.
*   **Cache (Redis):** Container `redis_cache`, executando Redis. Usado para caching, gerenciamento de sessões, filas de mensagens ou outras tarefas que exigem acesso rápido a dados temporários. Acessível internamente na rede `chat_network` pelo nome `redis` na porta `6379`.
*   **Volume (postgres_data):** Volume Docker nomeado que garante a persistência dos dados do PostgreSQL mesmo que o container `db` seja removido e recriado.

O fluxo principal de uma mensagem seria: O cliente envia a mensagem para `Receive-Send-API`. Esta API valida o usuário (possivelmente consultando `Auth-API`), processa a mensagem, talvez a coloque no `Redis` para entrega rápida ou notificação, e instrui a `Record-API` a armazená-la no `PostgreSQL`.




## ✅ Casos de Teste

Os testes automatizados são essenciais para garantir o correto funcionamento das APIs e a integração entre os microserviços. Os principais fluxos a serem testados incluem o registro de usuários, autenticação, envio e recebimento de mensagens, e consulta ao histórico. Foram preparados comandos `cURL` que podem ser facilmente importados para ferramentas como o Postman para execução.

O arquivo `postman_tests.txt` (incluído neste pacote) contém exemplos detalhados de comandos `cURL` para os seguintes cenários:

1.  **Registro de Novo Usuário:** Verifica se a `Auth-API` consegue criar um novo usuário no banco de dados.
2.  **Autenticação de Usuário:** Testa se um usuário registrado consegue obter um token de autenticação (e.g., JWT) da `Auth-API`.
3.  **Envio de Mensagem:** Valida se um usuário autenticado consegue enviar uma mensagem através da `Receive-Send-API`, que deve interagir com os demais serviços (Redis, Record-API) conforme a lógica implementada.
4.  **Consulta de Mensagens:** Verifica se um usuário autenticado consegue recuperar mensagens recebidas ou o histórico de conversas, seja através da `Receive-Send-API` ou da `Record-API`.

Para executar os testes, importe os comandos do arquivo `postman_tests.txt` para o Postman. Lembre-se de substituir placeholders como `SEU_TOKEN_AQUI` pelo token real obtido após o login e ajustar os IDs de destinatário conforme necessário. É recomendado configurar um ambiente no Postman para gerenciar variáveis como a URL base das APIs e o token de autenticação.




## ⚠️ Pontos de Falha e Soluções

Um sistema distribuído como este, baseado em microserviços e containers, possui diversos pontos potenciais de falha. A identificação e o planejamento para essas falhas são cruciais para a robustez da aplicação.

*   **Falha na Inicialização de um Container:** Um container pode falhar ao iniciar devido a erros no Dockerfile, falta de recursos (memória/CPU), problemas de permissão, ou erros na própria aplicação ao iniciar. 
    *   **Solução:** Verifique os logs do container específico usando `docker logs <container_id_ou_nome>`. Analise o Dockerfile em busca de erros de sintaxe ou comandos inválidos. Certifique-se de que a máquina host possui recursos suficientes. Verifique as permissões de arquivos e diretórios montados como volumes. Depure o código da aplicação para identificar erros de inicialização.

*   **Problemas de Conexão com o Banco de Dados:** As APIs podem não conseguir se conectar ao PostgreSQL devido a credenciais incorretas, o serviço do banco de dados não estar pronto (`healthy`), ou problemas de rede.
    *   **Solução:** Verifique se as variáveis de ambiente (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`) estão corretamente definidas no `docker-compose.yml` e sendo lidas pelas APIs. Utilize a diretiva `depends_on` com `condition: service_healthy` no `docker-compose.yml` para garantir que as APIs só iniciem após o banco estar pronto. Verifique os logs do container do PostgreSQL e da API que falhou a conexão. Certifique-se de que ambos os containers estão na mesma rede (`chat_network`).

*   **Problemas de Conexão com o Redis:** Similar ao banco de dados, a conexão com o Redis pode falhar por motivos de rede ou por o serviço Redis não estar disponível.
    *   **Solução:** Verifique as variáveis de ambiente (`REDIS_HOST`, `REDIS_PORT`). Use `depends_on` com `condition: service_healthy` para serviços que dependem criticamente do Redis. Verifique os logs do container do Redis e da API correspondente. Confirme que estão na mesma rede.

*   **Falha na Comunicação entre Microserviços:** Uma API pode não conseguir se comunicar com outra (e.g., Receive-Send-API não consegue chamar Auth-API) devido a nomes de serviço incorretos, portas erradas, ou a API de destino não estar rodando ou respondendo.
    *   **Solução:** Verifique se os nomes dos serviços usados nas URLs de comunicação interna (e.g., `http://auth-api`, `http://record-api:5001`) correspondem exatamente aos nomes definidos no `docker-compose.yml`. Certifique-se de que a API de destino está rodando (`docker ps`) e respondendo (verifique seus logs). Utilize `depends_on` se houver dependências estritas de inicialização.

*   **Perda de Dados (Volume Não Configurado):** Se o volume nomeado para o PostgreSQL não for configurado corretamente, os dados serão perdidos sempre que o container do banco for recriado.
    *   **Solução:** Garanta que a seção `volumes` no `docker-compose.yml` define um volume nomeado (e.g., `postgres_data:`) e que o serviço `db` monta este volume no diretório correto (`/var/lib/postgresql/data`).

*   **Recursos Insuficientes no Host:** Se a máquina que executa o Docker não tiver memória ou CPU suficientes, os containers podem ficar lentos, travar ou serem mortos pelo sistema operacional.
    *   **Solução:** Monitore o uso de recursos do host. Considere definir limites de recursos (memory, cpus) para os containers no `docker-compose.yml` para evitar que um serviço consuma todos os recursos. Se necessário, aumente os recursos da máquina host.

Implementar healthchecks robustos, monitoramento (logs centralizados, métricas) e estratégias de retentativa no código das APIs pode mitigar muitos desses problemas.

