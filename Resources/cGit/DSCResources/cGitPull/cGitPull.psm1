$scriptLocationOfGitExe = $null

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

		[parameter(Mandatory=$false)]
        [System.String]
        $LocationOfGitExe

    )

	$scriptLocationOfGitExe = $LocationOfGitExe

    Write-Verbose "[GITPULL] Start Get-TargetResource"


	

    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Configuration = @{
        RepositoryRemote = $RepositoryRemote
        RepositoryLocal = $RepositoryLocal
        Name = $Name
    }

    if (-not (IsGitInstalled) -or -not (Test-Path $RepositoryLocal) -or -not (isLocalGitUpToDate $RepositoryLocal))
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

		[parameter(Mandatory=$false)]
        [System.String]
        $LocationOfGitExe

    )

	$scriptLocationOfGitExe = $LocationOfGitExe
    Write-Verbose "[GITPULL] Start Set-TargetResource"
    
    if (-not (IsGitInstalled))
    {
        throw "Git isn't installed"
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

		[parameter(Mandatory=$false)]
        [System.String]
        $LocationOfGitExe

    )

	$scriptLocationOfGitExe = $LocationOfGitExe

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

function IsGitInstalled
{
    Write-Verbose "[GITPULL] Start IsGitInstalled"

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

	if (DoesCommandExist git)
	{
		Write-Verbose "[GITPULL] Git found in enviroment path"
		return $true
	}

	if (-not ($scriptLocationOfGitExe -eq $null) -and (Test-Path $scriptLocationOfGitExe))
	{
		Write-Verbose "[GITPULL] Git found at specified path"
		return $true
	}

	Write-Verbose "[GITPULL] Git not found in enviroment path or gitExePath"
	return $false

    #Try
    #{
    #    Exec({git help})
    #    return $true
    #}
    #Catch
    #{
    #    Write-Verbose "[GITPULL] Git not installed"
    #    return $false
    #}
}

function DoesCommandExist
{
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'

    try 
    {
        if(Get-Command $command)
        {
            return $true
        }
    }
    Catch 
    {
        return $false
    }
    Finally {
        $ErrorActionPreference=$oldPreference
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
    if ((Test-Path $repoLocationLocal))
    {
        $directoryInfo = Get-ChildItem $repoLocationLocal | Measure-Object

        if ($directoryInfo.Count -gt 0 -and -not (IsAGitRepository $RepositoryLocal))
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
        $cloneOutput = gitClone $repoUrl $repoLocal
        Write-Verbose "[GITPULL] $cloneOutput"
    }
    else
    {
        if (-Not (isLocalGitUpToDate($repoLocal)))
        {
            Write-Verbose "[GITPULL] Not up to date, initiating pull"
            $pullOutput = ExecGitCommand "pull"
            Write-Verbose "[GITPULL] $pullOutput"
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

    $command = "clone "+ $repoLocationRemote +" "+ $repoLocationLocal + " -v" 

    $output = ExecGitCommand $command
    

    Return $output

}

function ExecGitCommand
{
    param(
        [Parameter(Position=1,Mandatory=0)][string]$args
    )

    $location = Get-Location
    Write-Verbose "[GITPULL] Exec Git Command Prep Setting Current Location: $location"

	#default to git command from enviroment path
	$gitCmd = "git"
	if ($scriptLocationOfGitExe -ne $null)
	{
		#if specified use specific location
		$gitCmd = $scriptLocationOfGitExe
	}

	#envoke git in new process to capture output
    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $true 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = $gitCmd 
    $psi.WorkingDirectory = $location.ToString()
    $psi.Arguments = $args
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $process.WaitForExit()
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()

    Write-Verbose "[GITPULL] Exec Git Command: $args"

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
        Write-Verbose "Remote matches local: Reseting to head just to be sure files are unchanged $resetOutput"
        return $true;
    }
    else
    {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource