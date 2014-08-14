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
        $Configuration.Ensure = 'Absent'
        Return $Configuration
    }
    else
    {
        $Configuration.Ensure = 'Present'
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
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

    Write-Verbose "[ChocoInstall] Start InstallPackage $pName"

    Set-ExecutionPolicy Unrestricted
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    
    choco install $pName
    
    #refresh path varaible in powershell, as choco doesn't, to pull in git
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

    if ($installedPackages.Count -eq 1)
    {
        return $true
    }

    return $false

    
}


Export-ModuleMember -Function *-TargetResource