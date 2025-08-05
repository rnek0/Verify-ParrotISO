# 1. Base image PowerShell
FROM mcr.microsoft.com/powershell:latest

# 2. Installer GnuPG
RUN apt-get update && apt-get install -y gnupg curl

# 3. Créer dossier pour les ISO
RUN mkdir /data

# 4. Configurer GnuPG pour utiliser un serveur de clés
# Créer le dossier .gnupg et configurer le serveur de clés
RUN mkdir -p /root/.gnupg && \
  echo "keyserver hkps://keyserver.ubuntu.com\n\
  auto-key-locate clear,nodefault,wkd,keyserver\n\
  auto-key-retrieve" > /root/.gnupg/gpg.conf
# Configurer les permissions pour GnuPG
RUN chmod 700 /root/.gnupg && \
  chmod 600 /root/.gnupg/gpg.conf

# 5. Copier le script dans le conteneur
COPY Verify-ParrotISO.ps1 /opt/Verify-ParrotISO.ps1

# 6. Définir le dossier de travail
WORKDIR /data

# 7. Entrypoint PowerShell avec passage d’arguments
ENTRYPOINT ["pwsh", "/opt/Verify-ParrotISO.ps1"]
