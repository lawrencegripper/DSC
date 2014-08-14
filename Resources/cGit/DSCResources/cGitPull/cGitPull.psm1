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

    Write-Verbose "[GITPULL] Start Get-TargetResource"


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
    Write-Verbose "[GITPULL] Start Set-TargetResource"
    
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

    Write-Verbose "[GITPULL] Start Test-TargetResource"

    if (-not (IsGitInstalled))
    {
        Return $false
    }

    if (-not (Test-Path $RepositoryLocal))
    {
        Return $false
    }

    if (-Not (IsAGitRepository $RepositoryLocal))
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
    Write-Verbose "[GITPULL] Start InstallGit"

    Set-ExecutionPolicy Unrestricted
    iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    choco install git
    #refresh path varaible in powershell, as choco doesn't, to pull in git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
}

function IsGitInstalled
{
    Write-Verbose "[GITPULL] Start IsGitInstalled"

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

    Try
    {
        Exec({git help})
        return $true
    }
    Catch
    {
        Write-Verbose "[GITPULL] Git not installed"
        return $false
    }
    

}

function GitCreatePullUpdate
{
    param(
            [Parameter(Position=0,Mandatory=1)][string]$repoLocationRemote, 
            [Parameter(Position=1,Mandatory=1)][string]$repoLocationLocal
        ) 

    Write-Verbose "[GITPULL] Start GitCreatePullUpdate"

    $repoUrl = $repoLocationRemote
    $repoLocal = $repoLocationLocal
    if ((Test-Path $repoLocationLocal) -and -not (IsAGitRepository $RepositoryLocal))
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
    
    if (-not (IsAGitRepository $repoLocal))
    {
		Write-Verbose "[GITPULL] Not a repo, initiating clone"
        gitClone $repoUrl $repoLocal
    }
    else
    {
        if (-Not (isLocalGitUpToDate($repoLocal)))
        {
			Write-Verbose "[GITPULL] Not up to date, initiating pull"
            ExecGitCommand "pull"
        }
    }

}

function GitClone
{
    param(
        [Parameter(Position=0,Mandatory=1)][string]$repoLocationRemote, 
        [Parameter(Position=1,Mandatory=1)][string]$repoLocationLocal
    ) 

    Write-Verbose "[GITPULL] Start Clone"

	$command = "clone "+ $repoLocationRemote +" "+ $repoLocationLocal 

    $output = ExecGitCommand $command
    

    Write-Verbose $output

}

function Exec
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ($msgs.error_bad_command -f $cmd)
    )
    Write-Verbose "[GITPULL] Exec"
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
    Write-Verbose "[GITPULL] Exec Git Command"

	$location = Get-Location
	Write-Verbose $location

    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $true 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = "git" 
	$psi.WorkingDirectory = $location.ToString()
    $psi.Arguments = $args
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()

	Write-Verbose "[GITPULL] Exec Git Command - $args"

    return $output
}

function IsAGitRepository
{
	param(
        [Parameter(Position=0,Mandatory=1)][string]$repoLocation
    ) 

	Write-Verbose "[GITPULL] Start IsAGitRepository $repoLocation"

	Set-Location $repoLocation
	$output = ExecGitCommand "status"
    if ($output.Contains("fatal"))
    {
		Write-Verbose "[GITPULL] false $output"
		Return $false
	}
	else
	{
		Write-Verbose "[GITPULL] true $output"

		Return $true
	}

}

function IsLocalGitUpToDate
{
    param(
        [Parameter(Position=0,Mandatory=1)][string]$repoLocation
    ) 
    Write-Verbose "[GITPULL] Start IsLocalGitUpToDate $repoLK"
    
	Set-Location $repoLocation

	$update = ExecGitCommand "fetch origin"

	Write-Verbose "[GITPULL] Fetch Origin $update"

    $local = ExecGitCommand "rev-parse HEAD"
    $remote = ExecGitCommand "rev-parse origin/master"

    Write-Verbose "Local Commit vs Remote commit $local  $remote"

    if ($local -eq $remote)
    {
        $resetOutput = ExecGitCommand "reset --hard Head"
        Write-Verbose "Reset to head $resetOutput"
        return $true;
    }
    else
    {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource