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
configuration Sample_Install_Package
{
    param
    (
    #Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost',

        #The name of the module
        [Parameter(Mandatory)]
        [string]$Package
    )


    Import-DscResource -Module PackageManagementProviderResource

    Node $NodeName
    {               
        #Install a package from the Powershell gallery
        PackageManagement MyPackage
        {
            Ensure            = "present" 
            Name              = $Name
        }                               
    } 
}


#Compile it
Sample_Install_Package -Name "Json" 

#Run it
Start-DscConfiguration -path .\Sample_Install_Package -wait -Verbose -force 
