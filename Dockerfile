# 1. Base image PowerShell
FROM mcr.microsoft.com/powershell:latest

# 2. Installer GnuPG
RUN apt-get update && apt-get install -y gnupg curl

# 3. Créer dossier pour les ISO
RUN mkdir /data

# 4. Copier le script dans le conteneur
COPY Verify-ParrotISO.ps1 /opt/Verify-ParrotISO.ps1

# 5. Définir le dossier de travail
WORKDIR /data

# 6. Entrypoint PowerShell avec passage d’arguments
ENTRYPOINT ["pwsh", "/opt/Verify-ParrotISO.ps1"]
