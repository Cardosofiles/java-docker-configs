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
