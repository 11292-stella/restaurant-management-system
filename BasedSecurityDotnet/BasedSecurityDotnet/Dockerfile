# --- Stage 1: build & publish ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copiamo solo il .csproj prima del resto del codice: se non cambiano le
# dipendenze, Docker riusa la cache di "dotnet restore" anche quando modifichi
# solo un file .cs, invece di riscaricare i pacchetti NuGet a ogni build
COPY *.csproj ./
RUN dotnet restore

# Ora copiamo tutto il resto del progetto e compiliamo
COPY . .
RUN dotnet publish -c Release -o /app/publish --no-restore

# --- Stage 2: runtime (immagine finale, molto più leggera dell'SDK) ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 8080

ENTRYPOINT ["dotnet", "BasedSecurityDotnet.dll"]