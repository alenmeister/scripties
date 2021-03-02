$PathToChrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
$Headless = '--headless'
$DisableGPU = '--disable-gpu'
$RemotePort = '--remote-debugging-port=9222'

$App = Start-Process -FilePath $PathToChrome -ArgumentList $Headless, $DisableGPU, $RemotePort, https://www.duckduckgo.com/ -PassThru
Write-Output $App.Id