# Présentation de Verify-ParrotISO.ps1

Verify-ParrotISO.ps1 a été conçu avec l'idée de vérifier l'intégrité d'un fichier ISO et éviter d'avoir a saturer le serveur de demandes innecessaires.
Ce script PowerShell importe une clé GPG, tente de récupérer automatiquement la clé de signature si elle manque, puis vérifie la signature du fichier signed-hashes.txt. En cas d’échec, le script s’arrête et renvoie une erreur.

En cas de doute n'hesitez pas d'aller directement sur <https://parrotsec.org/> et faire comme vous faites d'habitude.

## Prérequis  

- Windows 10 ou 11
- winget installé (disponible par défaut sur les dernières versions de Windows)
- Droits suffisants pour exécuter des scripts PowerShell

### 1. Installation de GnuPG

Ouvrez une console PowerShell en mode administrateur et lancez :

```powershell
winget install GnuPG.GnuPG
```

### 2. Configuration de GnuPG

Créez (ou éditez) le fichier gpg.conf dans %APPDATA%\gnupg\gpg.conf avec les lignes suivantes :

```conf
keyserver hkps://keyserver.ubuntu.com
auto-key-locate clear,nodefault,wkd,keyserver
auto-key-retrieve
```

Ces options permettent à GnuPG de repérer et d’importer automatiquement la clé de signature via WKD ou keyserver.ubuntu.com lors de la vérification. 
Cela signifie :

- clear,nodefault : désactive les méthodes implicites.
- wkd : tente d’abord la récupération via WKD.
- keyserver : si WKD échoue, utilise le keyserver défini.


## Utilisation du script

Placez votre clé archive.gpg et le script PowerShell dans le même dossier. Le script peut télécharger les fichiers requis.

Ouvrez PowerShell dans ce dossier en mode administrateur.

Lancez le script :

```powershell
.\Verify-ParrotISO.ps1 
```

Vous pouvez activer le mode « DryRun » pour simuler les opérations sans modifier votre trousseau :

```powershell
.\Verify-ParrotISO.ps1 -DryRun $true
```

Force le téléchargement des fichiers avant de procéder à la vérification.

```powershell
.\Verify-ParrotISO.ps1 -Force
```

## Comportement attendu

- Import de la clé archive.gpg dans votre trousseau GPG.
- Récupération automatique de la clé de signature si elle manque.
- Vérification de la signature de signed-hashes.txt.
- Arrêt du script en cas d’échec de la vérification.

## Personnalisation

Pour changer de serveur de clés, éditez la ligne keyserver dans gpg.conf.

Adaptez le keyId dans le script si vous utilisez un autre signataire.

## Support 

Si vous rencontrez des problèmes ou avez des suggestions, ouvrez une issue sur le dépôt GitHub ou contactez l’auteur directement.