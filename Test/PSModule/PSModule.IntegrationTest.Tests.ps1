
$CurrentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

.  "$CurrentDirectory\..\OneGetTestHelper.ps1"

# Calling the setup function 
SetupPSModuleTest

Describe -Name "PSModule Integration Test" -Tags "RI" {

    BeforeEach {
    }

    AfterEach {
    }

    It "Start-DSC & Get-DSCconfiguration:Check Present" {
        
       # Compile the sample configuration to MOF and run Start-DscConfiguration
       $module=Get-Module -Name "OneGetResource" -ListAvailable
       & "$($module.ModuleBase)\Examples\Sample_PSModule.ps1"

        $getResult = Get-DscConfiguration 

        # Validate the returned results

        $getResult.Ensure | should be "Present"
        $getResult.Name | should be "xjea"
        $getResult.InstalledVersion | should be "0.2.16.3"
        $getResult.InstallationPolicy | should be "Untrusted"
        $getResult.ModuleType | should be "Manifest"


        # Check if the module exists. Source here is the installed path
        
        Test-Path $getResult.ModuleBase | should be $true

        # Calling Test to validate if it is true
        $testResult = Test-DscConfiguration
            
        $testResult | should be $true
    }
}


