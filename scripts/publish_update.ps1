# Zanny Collection — Upload APK & Publish v1.0.3 Update
# Run this from the project root after the worker is deployed.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$workerUrl   = "https://zanny-collection-api.zannykenya254.workers.dev"
$version     = "1.0.10"
$build       = 22
$changelog   = "Implement native push notification options for product drops, automatic FCM broadcast alerts for app updates, and static analysis compilation checks."
$adminSecret = "ZannyAdmin2024Secret"

$latestApk = Get-ChildItem -Path "build/app/outputs/flutter-apk" -Filter "zanny_collection_v${version}_*.apk" | Sort-Object LastWriteTime | Select-Object -Last 1
if ($null -eq $latestApk) {
    Write-Host "   ERROR: No zanny_collection_v${version}_*.apk found in build/app/outputs/flutter-apk" -ForegroundColor Red
    exit 1
}
$apkPath     = $latestApk.FullName
$apkKey      = $latestApk.Name

Write-Host "`n==> Checking admin secret header auth..." -ForegroundColor Cyan
# Use X-Admin-Secret header (no DB login required)
$authHeaders = @{ 'X-Admin-Secret' = $adminSecret }
Write-Host "   Admin secret configured." -ForegroundColor Green

Write-Host "`n==> Step 2: Uploading APK ($apkPath) to R2 via /api/upload ..." -ForegroundColor Cyan
if (-not (Test-Path $apkPath)) {
    Write-Host "   ERROR: APK not found at $apkPath" -ForegroundColor Red
    exit 1
}

try {
    $apkBytes    = [System.IO.File]::ReadAllBytes((Resolve-Path $apkPath))
    $boundary    = [System.Guid]::NewGuid().ToString("N")
    $header      = "--$boundary`r`nContent-Disposition: form-data; name=`"key`"`r`n`r`n$apkKey`r`n"
    $header     += "--$boundary`r`nContent-Disposition: form-data; name=`"file`"; filename=`"$apkKey`"`r`nContent-Type: application/vnd.android.package-archive`r`n`r`n"
    $footer      = "`r`n--$boundary--`r`n"
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
    $footerBytes = [System.Text.Encoding]::UTF8.GetBytes($footer)
    $body        = New-Object byte[] ($headerBytes.Length + $apkBytes.Length + $footerBytes.Length)
    [System.Buffer]::BlockCopy($headerBytes, 0, $body, 0,                               $headerBytes.Length)
    [System.Buffer]::BlockCopy($apkBytes,    0, $body, $headerBytes.Length,             $apkBytes.Length)
    [System.Buffer]::BlockCopy($footerBytes, 0, $body, $headerBytes.Length + $apkBytes.Length, $footerBytes.Length)

    $uploadResp = Invoke-RestMethod `
        -Uri "$workerUrl/api/upload" `
        -Method Post `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $body `
        -Headers $authHeaders
    Write-Host "   APK uploaded: key=$($uploadResp.key)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR uploading APK: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n==> Step 3: Publishing version.json (v$version build $build) ..." -ForegroundColor Cyan
$versionPayload = @{
    version   = $version
    build     = $build
    apk_url   = "$workerUrl/api/images/$apkKey"
    changelog = $changelog
} | ConvertTo-Json

try {
    $versionResp = Invoke-RestMethod `
        -Uri "$workerUrl/api/version" `
        -Method Put `
        -ContentType "application/json" `
        -Body $versionPayload `
        -Headers $authHeaders
    Write-Host "   version.json updated: $($versionResp | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR updating version.json: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Done! v$version (build $build) is now live." -ForegroundColor Green
Write-Host "   APK URL: $workerUrl/api/images/$apkKey" -ForegroundColor White
Write-Host "   Your phone will receive the update notification the next time it checks." -ForegroundColor White
