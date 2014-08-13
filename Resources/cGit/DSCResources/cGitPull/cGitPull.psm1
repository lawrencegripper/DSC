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

        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryLocal,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryRemote,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"

    )

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        RepositoryRemote = $RepositoryRemote
        RepositoryLocal = $RepositoryLocal
        Name = $Name
    }

    if (-not (IsGitInstalled) -and -not (Test-Path $RepositoryLocal) -and -not (isLocalGitUpToDate $RepositoryLocal))
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

        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryLocal,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryRemote,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )
    
    if (-not (IsGitInstalled))
    {
        InstallGit
    }
    GitCreatePullUpdate $RepositoryRemote $RepositoryLocal
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

        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryLocal,

        [ValidateNotNullOrEmpty()]
        [System.String]
        $RepositoryRemote,

        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    if (-not (IsGitInstalled))
    {
        Return $false
    }

    if (-not (Test-Path $RepositoryLocal))
    {
        Return $false
    }

    if (-Not (IsLocalGitUpToDate $RepositoryLocal))
    {
        Return $false
    }

    Return $true
}


function InstallGit
{
    Set-ExecutionPolicy Unrestricted
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    choco install git
    #refresh path varaible in powershell, as choco doesn't, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function IsGitInstalled
{
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    Try
    {
        Exec({git help})
        return $true
    }
    Catch
    {
        #Write-Host "Git not installed"
        return $false
    }
    

}

function GitCreatePullUpdate
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$repoLocationRemote, 
            [Parameter(Position=1,Mandatory=1)][string]$repoLocationLocal
        ) 
    $repoUrl = $repoLocationRemote
    $repoLocal = $repoLocationLocal
    if (Test-Path $repoLocationLocal)
    {
        $directoryInfo = Get-ChildItem $repoLocationLocal | Measure-Object

        if ($directoryInfo.Count -gt 0)
        {
            throw "Directory must be empty for git to create repository"
        }
    }
    else
    {
        New-Item -ItemType directory -Path $repoLocal
    }

    Set-Location $repoLocal
    $output = ExecGitCommand status
    if ($output -contains '*Not a git repository*')
    {
        gitClone $repoUrl $repoLocal
    }
    else
    {
        if (-Not (isLocalGitUpToDate($repoLocal)))
        {
            ExecGitCommand pull
        }
    }

}

function GitClone
{
    param(
        [Parameter(Position=0,Mandatory=1)][string]$repoLocationRemote, 
        [Parameter(Position=1,Mandatory=1)][string]$repoLocationLocal
    ) 



    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $true 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = 'git' 
    $psi.Arguments = "clone "+ $repoLocationRemote +" "+ $repoLocationLocal 
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
    

    #Write-Host $output

}

function Exec
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ($msgs.error_bad_command -f $cmd)
    )
    & $cmd
    if ($lastexitcode -ne 0) {
        throw ("Exec: " + $errorMessage)
    }
}

function ExecGitCommand
{
    param(
        [Parameter(Position=1,Mandatory=0)][string]$args
    )
    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $true 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = 'git' 
    $psi.Arguments = "clone "+ $repoLocationRemote +" "+ $repoLocationLocal 
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
    return $output
}

function IsLocalGitUpToDate
{
    param(
        [Parameter(Position=0,Mandatory=1)][string]$repoLocation
    ) 

    Set-Location $repoLocation

    $local = ExecGitCommand 'rev-parse HEAD'
    $remote = ExecGitCommand 'rev-parse origin/master'

    if ($local -eq $remote)
    {
        return $true;
    }
    else
    {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource