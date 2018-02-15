$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
-ChildPath 'CommonResourceHelper.psm1')

# Localized messages for verbose and error statements in this resource
$script:localizedData = Get-LocalizedData -ResourceName 'xDSCVault_Write'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Api","Cli")]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultValue
    )

  $returnValue = @{
    VaultMethod  = $VaultMethod
    WrappedToken = $WrappedToken
    RoleId       = $RoleId
    VaultAddress = $VaultAddress
    CliPath      = $CliPath
    ApiPrefix    = $ApiPrefix
    ApiPath      = ($VaultAddress + '/' + $ApiPrefix + '/' + $VaultPath)
  }

  $returnValue

}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Api","Cli")]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultValue,

        [System.String]
        $CliPath,

        [System.String]
        $ApiPrefix
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1


}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Api","Cli")]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultValue,

        [System.String]
        $CliPath,

        [System.String]
        $ApiPrefix
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

