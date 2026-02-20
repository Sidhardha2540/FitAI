$keytoolPath = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
$keystorePath = "C:\Users\saikr\.android\debug.keystore"

if (-not (Test-Path $keystorePath)) {
    Write-Host "Debug keystore not found. Creating a new one..."
    
    # Create the .android directory if it doesn't exist
    $androidDir = "C:\Users\saikr\.android"
    if (-not (Test-Path $androidDir)) {
        New-Item -ItemType Directory -Path $androidDir | Out-Null
    }
    
    # Generate a new debug keystore
    & $keytoolPath -genkey -v -keystore $keystorePath -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
}

# Get the output of keytool
$output = & $keytoolPath -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android | Out-String

# Find the SHA1 line
$sha1Match = $output | Select-String -Pattern "SHA1: ([0-9A-F:]+)"
if ($sha1Match) {
    $sha1 = $sha1Match.Matches.Groups[1].Value
    Write-Host "`n===================== COPY THIS SHA-1 FINGERPRINT ====================="
    Write-Host "SHA1: $sha1"
    Write-Host "====================================================================`n"
    
    # Also output the SHA1 without colons for Firebase
    $sha1NoColons = $sha1 -replace ":", ""
    Write-Host "For Firebase (without colons): $sha1NoColons"
    Write-Host "====================================================================`n"
} else {
    Write-Host "Could not find SHA-1 fingerprint in the output."
    Write-Host "Full output:"
    Write-Host $output
} 