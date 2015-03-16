configuration Sample_PSModule
{
    param
    (
	#Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost',

        #The name of the module
        [Parameter(Mandatory)]
        [string]$Name,

        #The required version of the module
        [string]$RequiredVersion,

        #Repository name  
        [string]$Repository,

        #Whether you trust the repository
        [string]$InstallationPolicy
    )


    Import-DscResource -Module OneGetResource

    Node $NodeName
    {               
        #Install a package from the Powershell gallery
        PSModule MyPSModule
        {
            Ensure            = "present" 
            Name              = $Name
            RequiredVersion   = "0.2.16.3"  
            Repository        = "PSGallery"
            InstallationPolicy="trusted"     
        }                               
    } 
}


#Compile it
Sample_PSModule -Name "xjea" 

#Run it
Start-DscConfiguration -path .\Sample_PSModule -wait -Verbose -force 
