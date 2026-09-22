$ErrorActionPreference = 'Stop'

$listing = $PSScriptRoot
$repo = (Resolve-Path (Join-Path $listing '../..')).Path
$sourceIcon = Join-Path $repo 'assets/branding/iccasa_app_icon.png'
$iconOutput = Join-Path $listing 'store-icon.png'
$featureSource = Join-Path $listing 'feature-graphic.html'
$featureOutput = Join-Path $listing 'feature-graphic.png'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$chromeProfile = Join-Path $env:TEMP 'iccasa-play-assets'

if (-not (Test-Path -LiteralPath $chrome)) {
    throw 'Chrome is required to render the feature graphic.'
}

$featureUrl = ([System.Uri](Resolve-Path $featureSource).Path).AbsoluteUri
& $chrome --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files `
    "--user-data-dir=$chromeProfile" `
    --force-device-scale-factor=1 --window-size=1024,500 `
    "--screenshot=$featureOutput" $featureUrl
if (-not (Test-Path -LiteralPath $featureOutput)) {
    throw 'Feature graphic rendering failed.'
}

Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Image]::FromFile($sourceIcon)
$icon = [System.Drawing.Bitmap]::new(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($icon)
try {
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($source, 0, 0, 512, 512)
    $icon.Save($iconOutput, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $graphics.Dispose()
    $icon.Dispose()
    $source.Dispose()
}

$feature = [System.Drawing.Image]::FromFile($featureOutput)
$storeIcon = [System.Drawing.Image]::FromFile($iconOutput)
try {
    if ($feature.Width -ne 1024 -or $feature.Height -ne 500 -or
        $feature.PixelFormat -ne [System.Drawing.Imaging.PixelFormat]::Format24bppRgb) {
        throw 'Feature graphic must be 1024 x 500 RGB PNG.'
    }
    if ($storeIcon.Width -ne 512 -or $storeIcon.Height -ne 512 -or
        $storeIcon.PixelFormat -ne [System.Drawing.Imaging.PixelFormat]::Format32bppArgb) {
        throw 'Store icon must be 512 x 512 32-bit PNG.'
    }
} finally {
    $feature.Dispose()
    $storeIcon.Dispose()
}

if ((Get-Item -LiteralPath $iconOutput).Length -gt 1MB) {
    throw 'Store icon exceeds Google Play 1 MB limit.'
}

Write-Host 'Google Play feature graphic and store icon validated.'
