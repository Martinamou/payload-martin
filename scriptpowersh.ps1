# Téléchargement de nircmd
$Url = "https://www.nirsoft.net/utils/nircmd.zip"
$ZipPath = "$env:USERPROFILE\nircmd.zip"
$ExtractPath = "$env:USERPROFILE\nircmd"

# Télécharger le fichier zip de nircmd
Invoke-WebRequest -Uri $Url -OutFile $ZipPath

# Extraire le fichier zip
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath

# Lancer nircmd pour mettre le volume à 100%
Start-Process "$ExtractPath\nircmd.exe" -ArgumentList "setsysvolume 65535"  # Valeur maximale de volume

# Attendre un peu avant d'ouvrir la vidéo pour s'assurer que nircmd a le temps de se lancer
Start-Sleep -Seconds 3

# Ouvrir la vidéo YouTube dans le navigateur par défaut
Start-Process "https://www.youtube.com/watch?v=bhSB8EEnCAM"

# Attendre 5 secondes avant de continuer, pour s'assurer que la vidéo se lance correctement
Start-Sleep -Seconds 5

# Ajouter la référence à System.Windows.Forms pour utiliser SendKeys
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Keyboard {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint MapVirtualKey(uint uCode, uint uMapType);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
}
"@

# Code pour appuyer sur la barre d'espace
$VK_SPACE = 0x20  # Code virtuel pour la barre d'espace

# Appuyer sur la barre d'espace
[Keyboard]::keybd_event($VK_SPACE, 0, 0, 0)

# Relâcher la barre d'espace
[Keyboard]::keybd_event($VK_SPACE, 0, 2, 0)

# Attendre 2 secondes après l'appui de la barre d'espace
Start-Sleep -Seconds 2

# Ajouter le type System.Windows.Forms pour afficher la fenêtre
Add-Type -AssemblyName "System.Windows.Forms"

# Créer une fenêtre en plein écran
$Form = New-Object System.Windows.Forms.Form
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$Form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$Form.BackColor = [System.Drawing.Color]::Black
$Form.ForeColor = [System.Drawing.Color]::White
$Form.TopMost = $true

# Créer un tableau de mots à afficher
$words = @("Martin", "est", "mon", "dieu")

# Variables pour le centrage vertical
$verticalOffset = 0
$labelHeight = 250  # Augmenter l'espacement vertical

# Créer un label pour chaque mot
foreach ($word in $words) {
    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = $word
    $Label.AutoSize = $true
    $Label.Font = New-Object System.Drawing.Font("Arial", 150, [System.Drawing.FontStyle]::Bold) # Texte plus grand
    $Label.ForeColor = [System.Drawing.Color]::Red # Couleur du texte en rouge
    $Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    # Assigner la position horizontale centrée
    $Label.Width = $Label.PreferredWidth
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $centerX = ($screenWidth - $Label.Width) / 2
    $Label.Location = New-Object System.Drawing.Point($centerX, $verticalOffset)

    # Ajouter le label au formulaire
    $Form.Controls.Add($Label)

    # Mettre à jour l'offset vertical pour placer le mot suivant sous le précédent
    $verticalOffset += $labelHeight
}

# Afficher la fenêtre
$Form.ShowDialog()

# Attendre un peu avant de tenter de supprimer les fichiers
Start-Sleep -Seconds 5

# Nettoyer les fichiers et répertoires
try {
    # Terminer le processus nircmd si nécessaire
    Stop-Process -Name "nircmd" -Force -ErrorAction SilentlyContinue

    # Supprimer le fichier zip téléchargé
    Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue

    # Supprimer le répertoire nircmd et son contenu
    Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Erreur lors de la suppression des fichiers ou répertoires : $_"
}