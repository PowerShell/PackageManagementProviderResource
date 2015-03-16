#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

<# Run Test cases Pre-Requisite: 
  1. After download the OngetGet DSC resources modules, it is expected the following are available under your current directory. For example,

    C:\Program Files\WindowsPowerShell\Modules\OneGetResource\
        
        DSCResources
        Examples
        Test
        OneGetResource.psd1
#>

#Define the variables

$CurrentDirectory            = Split-Path -Parent $MyInvocation.MyCommand.Path

$script:LocalRepositoryPath  = "$CurrentDirectory\LocalRepository"
$script:LocalRepositoryPath1 = "$CurrentDirectory\LocalRepository1"
$script:LocalRepositoryPath2 = "$CurrentDirectory\LocalRepository2"
$script:LocalRepositoryPath3 = "$CurrentDirectory\LocalRepository3"
$script:LocalRepository      = "LocalRepository"
$script:InstallationFolder   = $null
$script:DestinationPath      = $null
$script:Module               = $null



#A DSC configuration for installing Pester
configuration Sample_InstallPester
{
    param
    (
        #Destination path for the package
        [Parameter(Mandatory)]
        [string]$DestinationPath       
    )

    Import-DscResource -Module OneGetResource

    Node "localhost"
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
            Ensure          = "Present"
            Name            = "Pester"
            DestinationPath = $DestinationPath
            DependsOn       = "[OneGetSource]SourceRepository"
            InstallationPolicy="Trusted"
        }                              
    } 
}

# A helper function to download and install the pester tool
Function InstallPester
{
    Write-Host "Deploying Pester tool to progarm files directory..."

    # Get the module path where to be installed
    $module = Get-Module -Name "OneGetResource" -ListAvailable

    # Compile it
    Sample_InstallPester -DestinationPath "$($module.ModuleBase)\test"

    # Run it
    Start-DscConfiguration -path .\Sample_InstallPester -wait -Verbose -force 

    $result = Get-DscConfiguration 
    
    #import the Pester tool. Note:$result.Name is something like 'Pester.3.3.5'
    Import-module "$($module.ModuleBase)\test\$($result[1].Name)\tools\Pester.psd1"
 }

# A helper function to setup a local repostiory/package resouce to speed up the test execution
Function SetupLocalRepository
{
    param
	(
        [Switch]$PSModule
    )

    Write-Host "SetupLocalRepository..."
    
    # Create the LocalRepository path if does not exist
    if (-not ( Test-Path -Path $script:LocalRepositoryPath))
    {
        New-Item -Path $script:LocalRepositoryPath -ItemType Directory -Force  
    }

    # UnRegister repository/sources
    UnRegisterAllSource

    # Register the local repository
    RegisterRepository -Name $script:LocalRepository -InstallationPolicy Trusted -Ensure Present

    # Create test modules for the test automation
    if ($PSModule)
    {
        # Set up for PSModule testing
        CreateTestModuleInLocalRepository -ModuleName "MyTestModule"  -ModuleVersion "1.1"    -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestModule"  -ModuleVersion "1.1.2"  -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestModule"  -ModuleVersion "3.2.1"  -LocalRepository $script:LocalRepository
    }
    else
    {
        #Setup for nuget and others testing
        CreateTestModuleInLocalRepository -ModuleName "MyTestPackage" -ModuleVersion "12.0.1"   -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestPackage" -ModuleVersion "12.0.1.1" -LocalRepository $script:LocalRepository
        CreateTestModuleInLocalRepository -ModuleName "MyTestPackage" -ModuleVersion "15.2.1"   -LocalRepository $script:LocalRepository
    }

    # Replica the repository    
    Copy-Item -Path $script:LocalRepositoryPath -Destination $script:LocalRepositoryPath1 -Recurse -force   
    Copy-Item -Path $script:LocalRepositoryPath -Destination $script:LocalRepositoryPath2 -Recurse -force     
    Copy-Item -Path $script:LocalRepositoryPath -Destination $script:LocalRepositoryPath3 -Recurse -force
}

# A setup helper function for a PSModule test
Function SetupPSModuleTest
{
    Write-Host "Calling SetupPSModuleTest ..."

    #Need to import resource MSFT_PSModule.psm1
    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_PSModule\MSFT_PSModule.psm1"  

    SetupLocalRepository -PSModule 

    # Install Pester and import it
    InstallPester      
}

# A setup helper function for a Nuget test
Function SetupNugetTest
{
    Write-Host "Calling SetupNugetTest ..."

    #Import MSFT_NugetPackage.psm1 module
    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_NugetPackage\MSFT_NugetPackage.psm1"
    
    $script:DestinationPath = "$CurrentDirectory\TestResult\NugetTest" 

    SetupLocalRepository

    # Install Pester and import it
    InstallPester
 }

# A setup helper function for a OnegetSource test
Function SetupOneGetSourceTest
 {
    Write-Host "Calling SetupOneGetSourceTest ..."

    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_OneGetSource\MSFT_OneGetSource.psm1"

    SetupLocalRepository

    # Install Pester and import it
    InstallPester 
 }

#A help function to regsiter a module
Function Import-ModulesToSetupTest
{
    param
    (
    	[parameter(Mandatory = $true)]
		[System.String]
		$ModuleChildPath

    )
  
    Write-Verbose "Calling Import-ModulesToSetupTest"

    $moduleChildPath="DSCResources\$($ModuleChildPath)"

    $script:Module = Get-Module -Name "OneGetResource" -ListAvailable

    $modulePath = Microsoft.PowerShell.Management\Join-Path -Path $script:Module.ModuleBase -ChildPath $moduleChildPath

    Import-Module -Name "$($modulePath)"  
    
    #The modules in the below tests will be installed at the same location as OneGetResource. e.g., c:\Program Files\WindowsPowerShell\Modules
    $script:InstallationFolder = Split-Path -Path $script:Module.ModuleBase -Parent   
 }

#A helper function to register/unregister the psrepository 
function RegisterRepository
{
    param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String]
		$SourceLocation=$script:LocalRepositoryPath,   #Need to update this once we move on to Nuget API V3
   
   		[System.String]
		$PublishLocation=$script:LocalRepositoryPath,

        [ValidateSet("Trusted","Untrusted")]
		[System.String]
		$InstallationPolicy="Trusted",

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure="Present"
	)

    Write-Verbose -Message "RegisterRepository called" 

    # Calling the following to trigger Bootstrap provider for the first use OneGet
    Get-PackageSource -ProviderName Nuget -ForceBootstrap -WarningAction Ignore 

    $psrepositories = PowerShellGet\get-PSRepository
    $registeredRepository = $null

    #Check if the repository has been registered already
    foreach ($repository in $psrepositories)
    {
        # The PSRepository is considered as "exists" if either the Name or Source Location are in used
        $isRegistered = ($repository.SourceLocation -ieq $SourceLocation) -or ($repository.Name -ieq $Name) 

        if ($isRegistered)
        {
            $registeredRepository = $repository
            break;
        }
    }

    if($Ensure -ieq "Present")
    {       
        # If the repository has already been registered, unregister it.
        if ($isRegistered -and ($null -ne $registeredRepository))
        {
            Unregister-PSRepository -Name $registeredRepository.Name
        }       

        PowerShellGet\Register-PSRepository -Name $Name -SourceLocation $SourceLocation -PublishLocation $PublishLocation -InstallationPolicy $InstallationPolicy
    }
    else
    {
        # The repository has already been registered
        if (-not $isRegistered)
        {
            return
        }

        PowerShellGet\UnRegister-PSRepository -Name $Name
    }            
}

#Reset back the test machine enviorment
function RestoreRepository
{
    param
	(
        [parameter(Mandatory = $true)]
		[Hashtable]
		$RepositoryInfo
	)

    Write-Verbose -Message "RestoreRepository called"  
       
    foreach ($repository in $RepositoryInfo.Keys)
    {
        try
        {
            $null = PowerShellGet\Register-PSRepository -Name $RepositoryInfo[$repository].Name `
                                            -SourceLocation $RepositoryInfo[$repository].SourceLocation `
                                            -PublishLocation $RepositoryInfo[$repository].PublishLocation `
                                            -InstallationPolicy $RepositoryInfo[$repository].InstallationPolicy `
                                            -ErrorAction SilentlyContinue 
        }
        #Ignore if the repository already registered
        catch
        {
            if ($_.FullyQualifiedErrorId -ine "PackageSourceExists")
            {
                throw
            }
        }                                    
    }   
}

#Some psmodule tests require no other repositories are registered, the below function helps to do so
function CleanupRepository
{
    Write-Verbose -Message "CleanupRepository called" 

    $returnVal = @{}
    $psrepositories = PowerShellGet\get-PSRepository

    foreach ($repository in $psrepositories)
    {
        #Save the info for later restore process
        $repositoryInfo = @{"Name"=$repository.Name; `
                            "SourceLocation"=$repository.SourceLocation; `
                            "PublishLocation"=$repository.PublishLocation;`
                            "InstallationPolicy"=$repository.InstallationPolicy}

        $returnVal.Add($repository.Name, $repositoryInfo);

        try
        {
            $null = Unregister-PSRepository -Name $repository.Name -ErrorAction SilentlyContinue 
        }
        catch
        {
            if ($_.FullyQualifiedErrorId -ine "RepositoryCannotBeUnregistered")
            {
                throw
            }
        }         
    }   
    
    Return $returnVal   
}

#A test helper to register a package source
function RegisterPackageSource
{
    param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

        #Source location. It can be source name or uri
		[System.String]
		$SourceUri,

		[System.Management.Automation.PSCredential]
		$Credential,
    
		[System.String]
        [ValidateSet("Trusted","Untrusted")]
		$InstallationPolicy ="Untrusted",

		[System.String]
		$ProviderName="Nuget",

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure="Present"
	)

    Write-Verbose -Message "Calling RegisterPackageSource"

    #import the OngetSource module
    Import-ModulesToSetupTest -ModuleChildPath  "MSFT_OneGetSource\MSFT_OneGetSource.psm1"
    
    if($Ensure -ieq "Present")
    {       
        # If the repository has already been registered, unregister it.
        UnRegisterSource -Name $Name -ProviderName $ProviderName -SourceUri $SourceUri       

        MSFT_OneGetSource\Set-TargetResource -Name $name `
                                             -providerName $ProviderName `
                                             -SourceUri $SourceUri `
                                             -SourceCredential $Credential `
                                             -InstallationPolicy $InstallationPolicy `
                                             -Verbose `
                                             -Ensure Present
    }
    else
    {
        # The repository has already been registered
        UnRegisterSource -Name $Name -ProviderName $ProviderName -SourceUri $SourceUri
    } 
    
    # remove the OngetSource module, after we complete the register/unregister task
    Remove-Module -Name  "MSFT_OneGetSource"  -Force -ErrorAction SilentlyContinue         
}

#A test helper to unregister a package source
Function UnRegisterSource
{
    param
    (
        [parameter(Mandatory = $true)]
		[System.String]
		$Name,

        [System.String]
		$SourceUri,

    	[System.String]
		$ProviderName="Nuget"
    )

    $getResult = MSFT_OneGetSource\Get-TargetResource -Name $name -providerName $ProviderName -SourceUri $SourceUri -Verbose

    if ($getResult.Ensure -ieq "Present")
    {
        #Unregister it
        MSFT_OneGetSource\Set-TargetResource -Name $name -providerName $ProviderName -SourceUri $SourceUri -Verbose -Ensure Absent               
    }
}

#A test helper to unregister a package source
Function UnRegisterAllSource
{
    $sources = OneGet\Get-PackageSource

    foreach ($source in $sources)
    {
        try
        {
            #Unregister whatever can be unregistered
            OneGet\Unregister-PackageSource -Name $source.Name -providerName $source.ProviderName -ErrorAction SilentlyContinue  2>&1   
        }
        catch
        {
            if ($_.FullyQualifiedErrorId -ine "RepositoryCannotBeUnregistered")
            {
                throw
            }
        }         
    }
}


#A test helper to get a credential
function Get-Credential($user, $password)
{
    $secPassword = ConvertTo-SecureString $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($user, $secPassword)
    $cred
}

# A helper function to create test modules for testing purpose
function CreateTestModuleInLocalRepository
{
    param(
        [System.String]
        $ModuleName, 

        [System.String]
        $ModuleVersion,

        [System.String]
        $LocalRepository
    )

    # Return if the package already exists
    if (Test-path -path "$($script:Module.ModuleBase)\test\$($LocalRepository)\$($ModuleName).$($ModuleVersion).nupkg")
    {
        return
    }

    # Get the parent 'OneGetResource' module path
    $parentModulePath = Microsoft.PowerShell.Management\Split-Path -Path $script:Module.ModuleBase -Parent

    $modulePath = Microsoft.PowerShell.Management\Join-Path -Path $parentModulePath -ChildPath "$ModuleName"

    New-Item -Path $modulePath -ItemType Directory -Force

    $modulePSD1Path = "$modulePath\$ModuleName.psd1"

    # Create the module manifest
    Microsoft.PowerShell.Core\New-ModuleManifest -Path $modulePSD1Path -Description "$ModuleName" -ModuleVersion $ModuleVersion

    try
    {
        # Publish the module to your local repository
        PowerShellGet\Publish-Module -Path $modulePath -NuGetApiKey "Local-Repository-NuGet-ApiKey" -Repository $LocalRepository -Verbose -ErrorAction SilentlyContinue         
    }
    catch
    { 
        # Ignore the particular error
        if ($_.FullyQualifiedErrorId -ine "ModuleVersionShouldBeGreaterThanGalleryVersion,Publish-Module")
        {
            throw
        }               
    }

    # Remove the module under modulepath once we published it to the local repository
    Microsoft.PowerShell.Management\Remove-item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
}
