
<#
.Synopsys
The Get-TargetResource cmdlet.
#>
function Get-TargetResource
{
	param
	(
		[ValidateSet("Present", "Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$RepositoryLocal,

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$RepositoryRemote
	)

	#Needs to return a hashtable that returns the current
	#status of the configuration component
	$Configuration = @{
		RepositoryRemote = $RepositoryRemote
		RepositoryLocal = $RepositoryLocal
	
	}

	if (-not (IsGitInstalled) -and -not (Test-Path $RepositoryLocal) -and -not (isLocalGitUpToDate $repoUrl))
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

<#
.Synopsys
The Set-TargetResource cmdlet.
#>
function Set-TargetResource
{    
	param
	(
		[ValidateSet("Present", "Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$RepositoryLocal,

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$RepositoryRemote
	)

	GitCreatePullUpdate $ReposityoryRemote $RepositoryLocal
}

<#
.Synopsys
The Test-TargetResource cmdlet is used to validate if the resource is in a state as expected in the instance document.
#>
function Test-TargetResource
{
	param
	(
		[ValidateSet("Present", "Absent")]
		[System.String]
		$Ensure = "Present",

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$RepositoryLocal,

		[parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$RepositoryRemote
	)

	if (-not (IsGitInstalled))
	{
		Return $false
	}

	if (-not (Test-Path $RepositoryLocal))
	{
		Return $false
	}

	if (-Not (isLocalGitUpToDate $repoUrl))
	{
		Return $false
	}
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
	Try
	{
		Exec({git help})
		return $true
	}
	Catch
	{
		Write-Error "Git not installed"
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
	Try
	{
		Set-Location $repoLocal
		Exec({git status })
		if (-Not (isLocalGitUpToDate($repoUrl)))
		{
			Exec({git pull})
		}
	}
	Catch
	{
		Write-Host "Folder isn't a repository, kick off clone command"
		gitClone $repoUrl $repoLocal
	}
}

function GitClone
{
	param(
		[Parameter(Position=0,Mandatory=1)][string]$repoLocationRemote, 
		[Parameter(Position=1,Mandatory=1)][string]$repoLocationLocal
	) 

	if (Test-Path $repoLocationLocal)
	{
		$directoryInfo = Get-ChildItem $repoLocationLocal | Measure-Object

		if ($directoryInfo.Count -gt 0)
		{
			throw "Directory must be empty for git to create repository"
		}
	}

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
	

	Write-Host $output

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

function IsLocalGitUpToDate
{
	param(
		[Parameter(Position=0,Mandatory=1)][string]$repoLocation
	) 
	$local = git rev-parse HEAD | out-string
	$remote = git rev-parse origin/master | out-string

	if ($local -eq $remote)
	{
		return $true;
	}
	else
	{
		return $false
	}
}

#for testing
#if (-Not (IsGitInstalled))
#{
#	InstallGit
#}
#
#GitCreatePullUpdate
