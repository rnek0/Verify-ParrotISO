<#
.SYNOPSIS
    Vérifie l'intégrité et l'authenticité d'une image ISO de Parrot Security OS.

.DESCRIPTION
    Ce script PowerShell télécharge les fichiers nécessaires (ISO, hash signé, clé GPG),
    vérifie la signature GPG du fichier de hash, calcule le hash SHA512 de l'image ISO,
    et compare les deux pour confirmer que le fichier est authentique et non altéré.

.PARAMETER Force
    Force le téléchargement des fichiers même s'ils existent déjà localement.

.PARAMETER DryRun
    Simule l'exécution du script sans effectuer de téléchargement ni de modification.

.EXAMPLE
    .\Verify-ParrotISO.ps1
    Vérifie l'image ISO en utilisant les fichiers déjà présents ou les télécharge si absents.

.EXAMPLE
    .\Verify-ParrotISO.ps1 -Force
    Force le téléchargement des fichiers avant de procéder à la vérification.

.EXAMPLE
    .\Verify-ParrotISO.ps1 -DryRun
    Simule l'exécution sans téléchargement ni vérification réelle.

.NOTES
    Auteur : rnek0 & Copilot
    Date   : Août 2025
    Version: 1.0

.REQUIREMENTS
    - PowerShell 5.0+
    - gpg (GnuPG)
    - Get-FileHash
    - Invoke-WebRequest
    - Select-String
#>

param (
    [switch]$Force,
    [switch]$DryRun
)

# 🧪 Vérification de la version de PowerShell (>= 7.0)
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ Ce script nécessite PowerShell 7.0 ou supérieur." -ForegroundColor Red
    exit 1
}

# Vérification des droits d'administrateur
function Test-IsAdministrator {
    # Cas Docker : on ignore la vérification
    # Vérifie si on est dans Docker (Linux)
    $IsDocker = Test-Path "/.dockerenv"
    if ($IsDocker) {
        Write-Host "🛡️ Exécution dans un conteneur Docker — vérification d'administrateur ignorée."
        return $true
    }

    # Cas Windows
    if ($IsWindows) {
        try {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        catch {
            Write-Warning "⚠️ Impossible de vérifier les privilèges administrateur sur Windows : $_"
            return $false
        }
    }

    # Cas Linux/macOS
    if ($IsLinux -or $IsMacOS) {
        return ($env:USER -eq "root")
    }

    # OS non supporté
    Write-Warning "❌ Système d'exploitation non reconnu. Vérification des privilèges impossible."
    return $false
}


if (-not $DryRun -and -not (Test-IsAdministrator)) {
    Write-Host "❌ Ce script doit être exécuté en tant qu’administrateur pour fonctionner normalement." -ForegroundColor Yellow
    Write-Host "   Relancez PowerShell en mode Administrateur, puis réexécutez la commande." -ForegroundColor Yellow
    exit 1
}


# Vérification des dépendances
function Test-Command($command) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Erreur : la commande '$command' est introuvable. Veuillez l’installer." -ForegroundColor Red
        exit 1
    }
}

Test-Command "gpg"
Test-Command "Get-FileHash"
Test-Command "Invoke-WebRequest"
Test-Command "Select-String"

Write-Host "✅ Tous les outils nécessaires sont disponibles.`n"

# URLs et fichiers
$isoUrl = "https://deb.parrot.sh/parrot/iso/6.4/Parrot-security-6.4_amd64.iso"
$hashesUrl = "https://deb.parrot.sh/parrot/iso/6.4/signed-hashes.txt"
$keyUrl = "https://deb.parrot.sh/parrot/misc/archive.gpg"

$isoFile = "Parrot-security-6.4_amd64.iso"
$hashesFile = "signed-hashes.txt"
$keyFile = "archive.gpg"

# Téléchargement conditionnel des fichiers
Write-Host "🔄 Téléchargement des fichiers nécessaires..."
function Search-IfMissing {
    param (
        [string]$Url,
        [string]$OutFile
    )

    if ($DryRun) {
        Write-Host "🧪 [DryRun] Simulation du téléchargement de $OutFile depuis $Url"
    }
    elseif ($Force -or -not (Test-Path $OutFile)) {
        Write-Host "📥 Téléchargement de $OutFile..."
        Invoke-WebRequest -Uri $Url -OutFile $OutFile
    }
    else {
        Write-Host "✅ $OutFile déjà présent, téléchargement ignoré."
    }
}

Search-IfMissing -Url $isoUrl -OutFile $isoFile
Search-IfMissing -Url $hashesUrl -OutFile $hashesFile
Search-IfMissing -Url $keyUrl -OutFile $keyFile

# Importation de la clé dans archive.gpg
Write-Host "`n🔑 Importation de la clé GPG dans $keyFile ..."
if (-not $DryRun) { gpg --import $keyFile }

# Fonction pour récupérer la clé GPG avec fallback
# Si la récupération via WKD échoue, on essaie les keyservers
function Get-GpgKeyWithFallback {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Email,

        [Parameter(Mandatory = $true)]
        [string]$KeyID
    )

    Write-Host "🔍 Tentative de récupération de la clé pour $Email via WKD..."
    gpg --locate-keys $Email
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Clé récupérée via WKD."
        return
    }

    Write-Host "⚠️ Échec via WKD. Tentative via keyservers..."

    $keyservers = @(
        "hkps://keyserver.ubuntu.com",
        "hkps://keys.openpgp.org",
        "hkps://pgp.mit.edu"
    )

    foreach ($server in $keyservers) {
        Write-Host "🔄 Tentative via $server..."
        gpg --keyserver $server --recv-keys $KeyID
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Clé récupérée via $server."
            return
        }
    }

    Write-Host "❌ Échec de la récupération de la clé via tous les serveurs." -ForegroundColor Red
    exit 1
}


# Vérification de la signature
if ($DryRun) {
    Write-Host "`n🧪 [DryRun] Simulation de la vérification de la signature"
}
else {
    Write-Host "`n✅ Vérification de la signature du fichier signed-hashes.txt…"
    if (-not (Test-Path $hashesFile)) {
        Write-Host "❌ Le fichier $hashesFile est introuvable. Téléchargement nécessaire." -ForegroundColor Red
        Search-IfMissing -Url $hashesUrl -OutFile $hashesFile
    }
    # Récupération manuelle de la clé via un keyserver
    Write-Host "🔄 Import de la clé de signature pour Parrot Security OS..."
    #Get-GpgKeyWithFallback -Email "team@parrotsec.org" -KeyID "B711822346552E4D92DA02DF7A8286AF0E81EE4A"
    Get-GpgKeyWithFallback -Email "team@parrotsec.org" -KeyID "7A8286AF0E81EE4A"


    
    # Vérification de la signature
    gpg --verify $hashesFile
    # On vérifie le code de sortie de la commande gpg
    # Si la signature est valide, le code de sortie est 0   
    # Si échec, on stoppe tout
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n❌ La signature PGP n’a pas pu être vérifiée. Arrêt du script." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ La signature du fichier $hashesFile est valide." -ForegroundColor Green
}

# Extraction du hash attendu
Write-Host "`n🔍 Extraction du hash attendu (SHA512)…"
if ($DryRun) {
    Write-Host "🧪 [DryRun] Simulation de l'extraction du hash SHA512 pour $isoFile"
    $expectedHash = "<simulation>"
}
else {
    # On ne garde que la ligne SHA512 : 128 hex digits + espace(s) + nom du fichier
    $pattern = '^[0-9A-Fa-f]{128}\s+' + [regex]::Escape($isoFile) + '$'
    $line = Get-Content $hashesFile | Where-Object { $_ -match $pattern }
    if (-not $line) {
        Write-Host "❌ Impossible de trouver le SHA512 dans $hashesFile." -ForegroundColor Red
        exit 1
    }

    # On splitte la ligne unique et on prend la première colonne
    $expectedHash = ($line -split '\s+')[0]
}

# Calcul du hash réel
if ($DryRun) {
    Write-Host "`n🧪 [DryRun] Simulation du calcul du hash SHA512"
    $computedHash = "<simulation>"
}
else {
    Write-Host "`n🔄 Calcul du hash réel du fichier ISO..."
    $computedHash = (Get-FileHash -Path $isoFile -Algorithm SHA512).Hash
}

# Comparaison des hash
Write-Host "`n🔐 Comparaison des hash..."
if ($DryRun) {
    Write-Host "`n🧪 [DryRun] Simulation de la comparaison : attendu=$expectedHash vs calculé=$computedHash"
}
elseif ([string]::Equals($computedHash, $expectedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "`n✅ Le fichier ISO est intègre et signé par Parrot Security." -ForegroundColor Green
}
else {
    Write-Host "`n❌ Le hash ne correspond pas. Le fichier peut être corrompu ou falsifié." -ForegroundColor Red
    exit 1
}

# 🦜 Easter Egg
function Show-Parrot {
    @"
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/

 🦜 Parrot Security OS — Stay safe, stay curious!
"@ | Write-Host -ForegroundColor Cyan
}

Show-Parrot
