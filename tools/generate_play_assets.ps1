$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$src = "assets/app_icon.png"
$iconOut = "assets/play_store_icon_512.png"
$featureOut = "assets/feature_graphic_1024x500.png"

if (!(Test-Path $src)) {
  throw "Source icon not found: $src"
}

function New-SquareIcon {
  param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$Size,
    [Parameter(Mandatory = $true)][string]$BackgroundHex
  )

  $img = [System.Drawing.Image]::FromFile($InputPath)
  $bmp = New-Object System.Drawing.Bitmap $Size, $Size
  $g = [System.Drawing.Graphics]::FromImage($bmp)

  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml($BackgroundHex))

  $ratio = [Math]::Min(($Size * 1.0) / $img.Width, ($Size * 1.0) / $img.Height)
  $w = [int]($img.Width * $ratio)
  $h = [int]($img.Height * $ratio)
  $x = [int](($Size - $w) / 2)
  $y = [int](($Size - $h) / 2)

  $g.DrawImage($img, $x, $y, $w, $h)
  $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $g.Dispose()
  $bmp.Dispose()
  $img.Dispose()
}

function New-FeatureGraphic {
  param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][int]$Width,
    [Parameter(Mandatory = $true)][int]$Height,
    [Parameter(Mandatory = $true)][string]$BackgroundHex
  )

  $img = [System.Drawing.Image]::FromFile($InputPath)
  $bmp = New-Object System.Drawing.Bitmap $Width, $Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)

  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml($BackgroundHex))

  # Center icon on feature canvas with balanced padding.
  $targetH = [int]($Height * 0.72)
  $ratio = ($targetH * 1.0) / $img.Height
  $w = [int]($img.Width * $ratio)
  $h = [int]($img.Height * $ratio)
  $x = [int](($Width - $w) / 2)
  $y = [int](($Height - $h) / 2)

  $g.DrawImage($img, $x, $y, $w, $h)
  $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $g.Dispose()
  $bmp.Dispose()
  $img.Dispose()
}

New-SquareIcon -InputPath $src -OutputPath $iconOut -Size 512 -BackgroundHex "#1E2A88"
New-FeatureGraphic -InputPath $src -OutputPath $featureOut -Width 1024 -Height 500 -BackgroundHex "#1E2A88"

Write-Output "Created $iconOut"
Write-Output "Created $featureOut"
