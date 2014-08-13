
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
	$repoUrl = "https://github.com/lawrencegripper/FluentMongoIntegrationTesting"
	$repoLocal = "c:\temp\git"
	Try
	{
		#$sb = {
		#	param ($repoLocationLocal)
		#	git status $repoLocationLocal
		#  }
	    #Exec(& $sb $repoLocal)
		Set-Location $repoLocal
		Exec({git status })
		if (-Not (isLocalUpToDate($repoUrl)))
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
	$output = $process.StandardOutput.ReadToEnd()
	
	#$result = git clone $repoLocationRemote $repoLocationLocal | Out-String 

	Write-Host $output

	
	#$sb = {
	#		param ($repoLocationRemote, $repoLocationLocal)
	#	  }
	# Exec(& $sb $repoLocationRemote $repoLocationLocal)
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

function IsLocalUpToDate
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


if (-Not (IsGitInstalled))
{
	InstallGit
}

GitCreatePullUpdate
