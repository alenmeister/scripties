#Requires -Version 5

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Output "PowerShell 5 or later is required to run this installation."
    Write-Output "Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell"
    break
}

function env($name,$val='__get') {
    $target = 'User';
    if ($val -eq '__get') { [environment]::getEnvironmentVariable($name,$target) }
    else { [environment]::setEnvironmentVariable($name,$val,$target) }
}

function ensure($dir) { 
    if (!(Test-Path $dir)) { 
        mkdir $dir > $null 
    }; 
    Resolve-Path $dir
}

function friendly_path($path) {
    $h = (Get-PsProvider 'FileSystem').home; if(!$h.endswith('\')) { $h += '\' }
    if ($h -eq '\') { return $path }
    return "$path" -replace ([regex]::escape($h)), "~\"
}

function fullpath($path) { # should be ~ rooted
    $executionContext.sessionState.path.getUnresolvedProviderPathFromPSPath($path)
}

function ensure_in_path($dir) {
    $path = env 'PATH'
    $dir = fullpath $dir
    if ($path -notmatch [regex]::escape($dir)) {
        Write-Output "Adding $(friendly_path $dir) to your path."
        env 'PATH' "$dir;$path" # for future sessions...
        $env:PATH = "$dir;$env:PATH" # for this session
    }
}

function strip_filename($path) {
    $path -replace [regex]::escape((Split-Path $path -Leaf))
}

function download($url,$to) {
    $wc = New-Object Net.Webclient
    $wc.headers.add('Referer', (strip_filename $url))
    $wc.downloadFile($url,$to)
}

# Prepare for install
$basedir = 'C:\tools'
$dir = ensure $basedir

# Download OpenSSH zip
$zipurl = 'https://www.purehype.no/archive/openssh-portable/master.zip'
$zipfile = "$dir\openssh.zip"
Write-Output 'Downloading OpenSSH...'
download $zipurl $zipfile

Write-Output 'Extracting...'
Add-Type -Assembly "System.IO.Compression.FileSystem"
[IO.Compression.ZipFile]::ExtractToDirectory($zipfile, "$dir")
Rename-Item -Path "$dir\OpenSSH-Win64" -NewName "OpenSSH" -Force
Remove-Item $zipfile -Recurse -Force
ensure_in_path "$dir\OpenSSH"

Write-Output 'Installing OpenSSH...'
powershell.exe -ExecutionPolicy Bypass -File "$dir\OpenSSH\install-sshd.ps1"

# Download MinGit zip
$dir = "$basedir\MinGit"
$zipurl = 'https://www.purehype.no/archive/git-for-windows/master.zip'
$zipfile = "$dir\mingit.zip"
Write-Output 'Downloading MinGit...'
New-Item $dir -Type Directory -Force | Out-Null
download $zipurl $zipfile

Write-Output 'Extracting...'
[IO.Compression.ZipFile]::ExtractToDirectory($zipfile, "$dir")
Remove-Item $zipfile -Recurse -Force
ensure_in_path "$dir\cmd"

Write-Host 'OpenSSH and MinGit were installed successfully!'