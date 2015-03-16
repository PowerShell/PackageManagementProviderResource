# DSC configuration for NuGet

configuration Sample_InstallPester
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
            Name        = "Mynuget"
            ProviderName= "Nuget"
            SourceUri   = "http://nuget.org/api/v2/"  
            InstallationPolicy ="Trusted"
        }   
        
        #Install a package from Nuget repository
        NugetPackage Nuget
        {
            Ensure          = "present" 
            Name            = $Name
            DestinationPath = $DestinationPath
            DependsOn       = "[OneGetSource]SourceRepository"
            InstallationPolicy="Trusted"
        }                              
    } 
}


#Compile it
Sample_InstallPester -Name "Pester" -DestinationPath "$env:HomeDrive\test\test" 

#Run it
Start-DscConfiguration -path .\Sample_InstallPester -wait -Verbose -force 
