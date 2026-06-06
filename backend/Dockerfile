# Etapa 1 — Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copiar archivos de proyecto y restaurar dependencias
COPY CoWork.Domain/CoWork.Domain.csproj         CoWork.Domain/
COPY CoWork.Application/CoWork.Application.csproj CoWork.Application/
COPY CoWork.Infrastructure/CoWork.Infrastructure.csproj CoWork.Infrastructure/
COPY CoWork.API/CoWork.API.csproj               CoWork.API/

RUN dotnet restore CoWork.API/CoWork.API.csproj

# Copiar todo el código y compilar
COPY . .
RUN dotnet publish CoWork.API/CoWork.API.csproj -c Release -o /app/publish

# Etapa 2 — Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 5209
ENTRYPOINT ["dotnet", "CoWork.API.dll"]