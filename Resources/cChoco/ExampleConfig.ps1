Configuration myChocoConfig
{
   Import-DscResource -Module cChoco  
   Import-DscResource -Module cGit  
   Node "localhost"
   {
      LocalConfigurationManager
      {
          ConfigurationMode = "ApplyAndAutoCorrect"
          ConfigurationModeFrequencyMins = 30 #must be a multiple of the RefreshFrequency and how often configuration is checked
      }
      cChocoInstall installGit
      {
        
        Ensure = "Present"
        Name = "installGit"
      }
      cGitPull pullRepo
      {
        Name = 'test'
        RepositoryLocal = "c:\temp\gitdsc\"
        RepositoryRemote = 'https://github.com/lawrencegripper/FluentMongoIntegrationTesting'
        Ensure = 'Present'
        DependsOn = "[cChocoInstall]installGit"
      }
      
   }
} 

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose