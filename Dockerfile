# ============================================================
#  VAI E VOLTA — imagem Docker da aplicação ASP.NET Core
#  Etapa 1 compila o projeto; etapa 2 só roda (imagem menor)
# ============================================================

# ---------- Etapa 1: build ----------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copia só o .csproj primeiro: se ele não mudar, o Docker reaproveita os pacotes baixados
COPY VaiEVolta/VaiEVolta.csproj VaiEVolta/
RUN dotnet restore VaiEVolta/VaiEVolta.csproj

COPY VaiEVolta/ VaiEVolta/
RUN dotnet publish VaiEVolta/VaiEVolta.csproj -c Release -o /app/publish --no-restore

# ---------- Etapa 2: execução ----------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_HTTP_PORTS=8080 \
    TZ=America/Sao_Paulo

COPY --from=build /app/publish .

# Pastas onde a aplicação grava as fotos e as chaves do login
RUN mkdir -p /app/wwwroot/uploads /app/chaves

EXPOSE 8080
ENTRYPOINT ["dotnet", "VaiEVolta.dll"]
