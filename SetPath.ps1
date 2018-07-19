# $Windows: SetPath.ps1, 2017/11/08 21:42:44 Alen Mistric Exp $

$NewPathEntries = (Get-Item -Path 'C:\Program Files\Java\jdk*\bin', 'C:\Program Files\apache-maven*\bin').FullName
[System.Collections.ArrayList]$OldPathEntries = [System.Environment]::GetEnvironmentVariable('Path', 'User').Split(';')

foreach ($Item in $NewPathEntries) {
    if ($OldPathEntries -notcontains $Item) {
        Write-Output "'$Item' added to environment variable %PATH%";
        # We don't want to return the index for each array value, hence the redirect to $null
        $OldPathEntries.Add($Item) > $null
    }
    else {
        Write-Output "'$Item' already in environment variable %PATH%";
    }
}

$NewPath = $OldPathEntries -Join ';'
[System.Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')

$JavaRootPath = (Get-Item -Path 'C:\Program Files\Java\jdk*').FullName
[System.Environment]::SetEnvironmentVariable('JAVA_HOME', $JavaRootPath, 'User')