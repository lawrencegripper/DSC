function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PackageName,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"

    )

    Write-Verbose "[CHOCOINSTALL] Start Get-TargetResource"


    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        PackageName = $PackageName
    }

    if (-not (IsPackageInstalled $PackageName))
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
        $PackageName,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )
    Write-Verbose "[CHOCOINSTALL] Start Set-TargetResource"
    
    if (-not (IsPackageInstalled $PackageName))
    {
        InstallPackage $PackageName
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
        $PackageName,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose "[CHOCOINSTALL] Start Test-TargetResource"

    if (-not (IsPackageInstalled))
    {
        Return $false
    }

    Return $true
}


function InstallPackage
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$packageName
        ) 

    Write-Verbose "[ChocoInstall] Start InstallPackage $packageName"

    Set-ExecutionPolicy Unrestricted
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    
    choco install $packageName
    
    #refresh path varaible in powershell, as choco doesn't, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function IsPackageInstalled
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$packageName
        ) 
    Write-Verbose "[ChocoInstall] Start IsPackageInstalled $packageName"

    $installedPackages = choco list -lo | Where-object { $_.Contains($packageName) }

    if ($installedPackages.Count -eq 1)
    {
        return $true
    }

    return $false

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}


Export-ModuleMember -Function *-TargetResource