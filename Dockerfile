# Etapa 1: Construir la app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY . .
RUN dotnet publish -c Release -o out

# Etapa 2: Imagen final con runtime y SQL Server
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final

# Instalar SQL Server Express
RUN apt-get update && \
    apt-get install -y curl gnupg && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 mssql-tools unixodbc-dev && \
    ACCEPT_EULA=Y apt-get install -y mssql-server && \
    apt-get clean

ENV SA_PASSWORD="YourStrong!Passw0rd"
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Express

WORKDIR /app

# Copia base de datos y backend
COPY --from=build /app/out .
COPY sqlserver/ /var/opt/mssql/data/

# Iniciar SQL Server y luego el backend
CMD /bin/bash -c "/opt/mssql/bin/sqlservr & sleep 20 && dotnet BlazorBackCRUD.dll"