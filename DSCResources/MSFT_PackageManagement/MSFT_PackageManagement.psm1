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
# This PS DSC resource enables installing a package. The resource uses Install-Package cmdlet
# to install the package from various providers/sources.

Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_PackageManagement.strings.psd1

Import-Module -Name "$PSScriptRoot\..\OneGetHelper.psm1"

function Get-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        $RequiredVersion,
        
        [Parameter()]
        $MinimumVersion,

        [Parameter()]
        $MaximumVersion,

        [Parameter()]
        $Source,

        [Parameter()]
        [System.String]
        $ProviderName        
    )
    
    $ensure = "Absent"

    $PSBoundParameters.Remove("Source")

    Write-Verbose -Message ($localizedData.StartGetPackageSource -f $($Name))

    #check if the package source already registered on the computer
    $result = PackageManagement\Get-Package @PSBoundParameters -ForceBootstrap -ErrorAction SilentlyContinue -WarningAction SilentlyContinue  
        

    if ($result.count -gt 0)
    {
        Write-Verbose -Message ($localizedData.PackageSourceFound -f $($Name))
        $ensure = "Present"
    }
    else
    {
        Write-Verbose -Message ($localizedData.PackageSourceNotFound -f $($Name))
    }

    Write-Debug -Message "Source $($Name) is $($ensure)"
                         
    
    if ($ensure -eq 'Absent')
    {
        return @{
            Ensure       = $ensure
            Name         = $Name
            ProviderName = $ProviderName
        }
    }
    else
    {
        #Sometimes Get-PackageSource can return duplicate entries. Below is the workaround to the bug. 
        #Once the bug gets fixed, remove the below if ($source.count -gt 1) block 

        if ($result.count -gt 1)
        {
            $result =$source[0]
        }

        return @{
            Ensure             = $ensure
            Name               = $Name
            ProviderName       = $ProviderName
            Source             = $result.source
        }
    } 
}

function Test-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        $RequiredVersion,
        
        [Parameter()]
        $MinimumVersion,

        [Parameter()]
        $MaximumVersion,

        [Parameter()]
        $Source,

        [Parameter()]
        [System.String]
        $ProviderName        
    )


}

function Set-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        $RequiredVersion,
        
        [Parameter()]
        $MinimumVersion,

        [Parameter()]
        $MaximumVersion,

        [Parameter()]
        $Source,

        [Parameter()]
        [System.String]
        $ProviderName        
    )

    #TOD  
 }

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource

