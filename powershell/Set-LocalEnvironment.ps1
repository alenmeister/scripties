function Set-LocalEnvironment
{
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet("On", "Off")]
        [string] $Action
    )

    Begin {
        try {
            Write-Verbose -Message "Building Information Table..."
            $Projects = @(
                @{
                    Name = "BarApi" 
                    Process = (Get-Process -Name "dotnet" -ErrorAction SilentlyContinue)
                    Params = @{
                        FilePath  = "dotnet"
                        WorkingDirectory = "C:\Repositories\BarApi\src\BarApi"
                        ArgumentList = @(
                            "run"
                        )
                        NoNewWindow = $true
                    }
                },
                @{
                    Name = "FooWeb"
                    Process = (Get-Process -Name "node" -ErrorAction SilentlyContinue)
                    Params = @{
                        FilePath  = "npm"
                        WorkingDirectory = "C:\Repositories\FooWeb\src"
                        ArgumentList = @(
                            "start"
                        )
                        WindowStyle = "Hidden"
                    } 
                }
            )
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        } 
    }

    Process {
        Write-Verbose -Message "Processing Information Table..."
        try {
            foreach ($Project in $Projects) {
                switch ($Action) {
                    "On" { 
                        if ($null -eq $Project.Process) {
                            if (Test-Path -path $Project.Params.WorkingDirectory) {
                                Write-Host -ForegroundColor Green "Starting $($Project.Name)..."
                                $params = $Project.Params
                                Start-Process @params
                            } else {
                                Write-Host "Path: $($Project.Path) does not exist" -ForegroundColor Red
                            }
                        } else {
                            Write-Warning -message "$($Project.Name) is already running"
                        }
                    }
                    "Off" {
                        if ($null -ne $Project.Process) {
                            Write-Host -ForegroundColor Green "Stopping $($Project.Name)..."
                            $Project.Process | Stop-Process
                        } else {
                            Write-Warning -message "$($Project.Name) is not running"
                        }
                    }
                }            
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
} # End of function Set-LocalEnvironment