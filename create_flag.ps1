Add-Type -AssemblyName System.Drawing

$width = 300
$height = 200
$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Rot (oben)
$redBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(238, 51, 51))
$graphics.FillRectangle($redBrush, 0, 0, $width, $height/3)

# Weiß (Mitte)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$graphics.FillRectangle($whiteBrush, 0, $height/3, $width, $height/3)

# Grün (unten)
$greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(46, 139, 87))
$graphics.FillRectangle($greenBrush, 0, 2*$height/3, $width, $height/3)

# Goldener Kreis in der Mitte
$yellowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 199, 0))
$centerX = $width / 2
$centerY = $height / 2
$radius = 40
$graphics.FillEllipse($yellowBrush, $centerX - $radius, $centerY - $radius, $radius * 2, $radius * 2)

$bitmap.Save('assets/images/ala_rengin.png')
$bitmap.Dispose()
$graphics.Dispose()
Write-Host 'Ala rengin Flagge erstellt!'
