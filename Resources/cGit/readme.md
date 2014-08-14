Community Git DSC Resource - @lawrencegripper
=============================

This resource is aimed at keeping a git repository up to date. Currently early beta version.  

The resource checks the status of the repository, pulling updates and keeping local files in sync with remote commits. 

If the repository isn't setup it will also clone to local. 

N.B This Repository will use Chocolately to install GIT if required from https://chocolatey.org/packages/git.install

Developed with PowerShell VS Extentsions, this is why there is a .sln and proj file. Extension can be found here, http://visualstudiogallery.msdn.microsoft.com/c9eb3ba8-0c59-4944-9a62-6eee37294597