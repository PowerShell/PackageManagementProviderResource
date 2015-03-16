# DSC configuration for NuGet

configuration Sample_NuGet_InstallPackage
{
    param
    (
        #Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost',

        #Name of the package to be installed
        [Parameter(Mandatory)]
        [string]$Name,

        #Destination path for the package
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        
        #Version of the package to be installed
        [string]$RequiredVersion,

        #Source location where the package download from
        [string]$Source,

        #Whether the source is Trusted or Untrusted
        [string]$InstallationPolicy
    )

    Import-DscResource -Module OneGetResource

    Node $NodeName
    {
        
        #register package source       
        OneGetSource SourceRepository
        {

            Ensure      = "Present"
            Name        = "MyNuget"
            ProviderName= "Nuget"
            SourceUri   = "http://nuget.org/api/v2/"  
            InstallationPolicy ="Trusted"
        }   
        
        #Install a package from Nuget repository
        NugetPackage Nuget
        {
            Ensure          = "Present" 
            Name            = $Name
            DestinationPath = $DestinationPath
            RequiredVersion = "2.0.1"
            DependsOn       = "[OneGetSource]SourceRepository"
        }                               
    } 
}


#Compile it
Sample_NuGet_InstallPackage -Name "JQuery" -DestinationPath "$env:HomeDrive\test\test"

#Run it
Start-DscConfiguration -path .\Sample_NuGet_InstallPackage -wait -Verbose -force 
