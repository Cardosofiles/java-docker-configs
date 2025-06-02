# 🚀 Configurações para aplicação com Java, Spring Boot, Open API (swagger) PostgreSQL com container Docker com script de restart do Container 🔥

Este repositório guarda arquivos de dependência e configuração de aplicação java com persistência em
um banco de dados postgres via Dockerfile e docker-compose.yml

- Configuração do PgAdmin(server.json)
- Configuração do application.properties
- Configuração da imagem com Dockerfile
- Configuração do container com o docker-compose
- Configuração das dependências no arquivo pom.yml

---

## 📁 Estrutura

- Script: `restar-docker.sh`
- Local: `~/bin/restart-docker.sh`

---

## 📜 Conteúdo do Script

```bash
#!/bin/bash

# Cores
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${RED}🧨 Parando containers existentes...${RESET}"
docker compose down

echo -e "${BLUE}🚀 Rebuild e inicialização em background...${RESET}"
docker compose up -d --build

echo -e "${GREEN}✅ Containers atualizados e rodando!${RESET}"

echo -e "${YELLOW}📜 Exibindo logs em tempo real da aplicação:${RESET}"
echo -e "${BLUE}(Pressione Ctrl+C para parar de visualizar os logs)\n${RESET}"

sleep 2

docker exec -it todolist-api tail -f /logs/app.log
```

---

## ✅ Como Instalar e Usar

### 1. 📥 Criar o script

- Crie um diretório mkdir bin

```bash
nano ~/restart-docker.sh
```

Cole o conteúdo acima e salve (`Ctrl+O`, `Enter`, `Ctrl+X`).

---

### 2. 🔓 Dar permissão de execução

```bash
chmod +x ~/restart-docker.sh
```

---

### 3. ⚙️ Tornar o script global

Edite o arquivo `.zshrc` ou `.bashrc`:

```bash
nano ~/.zshrc
```

Adicione esta linha ao final:

```bash
alias restart-docker="~/bin/restart-docker.sh"
```

Salve e recarregue o terminal:

```bash
source ~/.zshrc
```

---

### 4. 🚀 Usar o comando

Navegue até o diretório do seu projeto e rode:

```bash
restart-docker
```

---

## 🧠 Dica

Você pode personalizar este script para incluir validações, log de histórico, commits convencionais, entre outros.

---

## 📌 Requisitos

- Docker e Docker compose instalado
- Terminal WSL (Ubuntu)

---

## Configuração do PgAdmin(server.json)

```bash
{
  "Servers": {
    "1": {
      "Name": "Local PostgreSQL",
      "Group": "Servers",
      "Host": "db",
      "Port": 5432,
      "Username": "docker",
      "SSLMode": "prefer",
      "MaintenanceDB": "goal_track_db"
    }
  }
}
```

### Configuração do application.properties

```bash
# Datasource
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}

# Hibernate (ajuste se desejar gerar automaticamente a estrutura do banco)
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

# Swagger (opcional, caso use springdoc-openapi)
springdoc.api-docs.enabled=true
springdoc.swagger-ui.enabled=true
```

### Configuração da imagem com Dockerfile

```bash
# Etapa 1: Build da aplicação com cache de dependências
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# Define diretório de trabalho
WORKDIR /app

# Copia apenas os arquivos de configuração do Maven (para cache de dependências)
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Faz o download das dependências antes de copiar o código (melhor cache)
RUN ./mvnw dependency:go-offline -B

# Agora copia o restante do projeto
COPY . .

# Compila o projeto e gera o JAR (sem rodar os testes)
RUN ./mvnw clean package -DskipTests

# Etapa 2: Imagem final com o JAR
FROM eclipse-temurin:17-jdk

WORKDIR /app

# Copia o JAR gerado da etapa anterior
COPY --from=builder /app/target/*.jar app.jar

# Exponha a porta padrão do Spring Boot
EXPOSE 8080

# Comando de inicialização
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Configuração do container com o docker-compose

```bash
version: "3.8"

services:
  app:
    build: .
    container_name: spring-app
    env_file:
      - .env
    depends_on:
      - db
    ports:
      - "8080:8080"
    networks:
      - backend
    environment:
      SPRING_DATASOURCE_URL: ${SPRING_DATASOURCE_URL}
      SPRING_DATASOURCE_USERNAME: ${SPRING_DATASOURCE_USERNAME}
      SPRING_DATASOURCE_PASSWORD: ${SPRING_DATASOURCE_PASSWORD}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  db:
    image: postgres:15
    container_name: postgres-db
    restart: always
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    env_file:
      - .env
    environment:
      POSTGRES_USER: ${SPRING_DATASOURCE_USERNAME}
      POSTGRES_PASSWORD: ${SPRING_DATASOURCE_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  swagger-ui:
    image: swaggerapi/swagger-ui
    container_name: swagger-ui
    restart: always
    ports:
      - "9000:8080"
    environment:
      SWAGGER_JSON: /app/swagger.yaml
    volumes:
      - ./docs/swagger.yaml:/app/swagger.yaml
    networks:
      - backend

  pgadmin:
    image: dpage/pgadmin4
    container_name: pgadmin
    restart: always
    ports:
      - "5050:80"
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
    depends_on:
      - db
    volumes:
      - pgadmin-data:/var/lib/pgadmin
      - ./pgadmin/servers.json:/pgadmin4/servers.json
    networks:
      - backend

volumes:
  pgdata:
  pgadmin-data:

networks:
  backend:

```

### Configuração das dependências no arquivo pom.yml

```bash
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
  <version>2.5.0</version>
</dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
</dependency>


<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-devtools</artifactId>
  <scope>runtime</scope>
</dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
</dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<dependency>
  <groupId>io.jsonwebtoken</groupId>
  <artifactId>jjwt-api</artifactId>
  <version>0.11.5</version>
</dependency>

<dependency>
  <groupId>io.jsonwebtoken</groupId>
  <artifactId>jjwt-impl</artifactId>
  <version>0.11.5</version>
  <scope>runtime</scope>
</dependency>

<dependency>
  <groupId>io.jsonwebtoken</groupId>
  <artifactId>jjwt-jackson</artifactId>
  <version>0.11.5</version>
  <scope>runtime</scope>
</dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-test</artifactId>
  <scope>test</scope>
</dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

```
