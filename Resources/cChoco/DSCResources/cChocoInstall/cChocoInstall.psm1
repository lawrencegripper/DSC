function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"

    )

    Write-Verbose "[CHOCOINSTALL] Start Get-TargetResource"


    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        Name = $Name
    }

    if (-not (IsPackageInstalled $Name))
    {
        $Configuration.Ensure = "Absent"
        Return $Configuration
    }
    else
    {
        $Configuration.Ensure = "Present"
        Return $Configuration

    }
}

function Set-TargetResource
{
    [CmdletBinding()]    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )
    Write-Verbose "[CHOCOINSTALL] Start Set-TargetResource"
    
    if (-not (IsPackageInstalled $Name))
    {
        InstallPackage $Name
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose "[CHOCOINSTALL] Start Test-TargetResource"

    if (-not (IsPackageInstalled $Name))
    {
        Return $false
    }

    Return $true
}


function InstallPackage
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName
        ) 

    $sb = {
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine')

        Write-Verbose '[ChocoInstall] Start InstallPackage'
        Write-Verbose  $pName

        Set-ExecutionPolicy Unrestricted
        iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    
        choco install $pName
    }

    #Execute using start process to ensure choco can get to where it needs and avoid issues with Write-Host etc
    $installOutput = ExecPowerShellScriptBlock $sb

    Write-Verbose "[ChocoInstall] output $installOutput"

    #refresh path varaible in powershell, as choco doesn"t, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function IsPackageInstalled
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$pName
        ) 
    Write-Verbose "[ChocoInstall] Start IsPackageInstalled $pName"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    
    Write-Verbose "[ChocoInstall] Start IsPackageInstalled $env:path"

    $installedPackages = choco list -lo | Where-object { $_.Contains($pName) }

    if ($installedPackages.Count -gt 1)
    {
        return $true
    }

    return $false

    
}


function ExecPowerShellScriptBlock
{
    param(
        [Parameter(Position=1,Mandatory=0)][scriptblock]$block
    )

    $location = Get-Location
    Write-Verbose "[ChocoInstall] ExecPowerShellScriptBlock Prep Setting Current Location: $location"

    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $true 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = "powershell " 
    $psi.WorkingDirectory = $location.ToString()
    $psi.Arguments = "-ExecutionPolicy Bypass -Command & {$block}" 
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()

    Write-Verbose "[ChocoInstall] Exec powershell Command - $block"

    return $output
}

##attempting to work around the issues with Chocolatey calling Write-host in its scripts. 
function global:Write-Host
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Object]
        $Object,
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $ForegroundColor,
        [ConsoleColor]
        $BackgroundColor

    )

    #Override default Write-Host...
    Write-Verbose $Object
}


Export-ModuleMember -Function *-TargetResource