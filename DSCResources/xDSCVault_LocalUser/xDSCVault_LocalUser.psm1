$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

# Localized messages for verbose and error statements in this resource
$script:localizedData = Get-LocalizedData -ResourceName 'xDSCVault_LocalUser'
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Api", "Cli")]
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
        $UserName,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Disabled,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordChangeNotAllowed,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordChangeRequired,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordNeverExpires
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $returnValue = @{
    VaultMethod = [System.String]
    VaultAddress = [System.String]
    VaultPath = [System.String]
    VaultValue = [System.String]
    CliPath = [System.String]
    ApiPrefix = [System.String]
    ApiPath = [System.String]
    UserName = [System.String]
    Description = [System.String]
    Disabled = [System.Boolean]
    Ensure = [System.String]
    FullName = [System.String]
    PasswordChangeNotAllowed = [System.Boolean]
    PasswordChangeRequired = [System.Boolean]
    PasswordNeverExpires = [System.Boolean]
    }

    $returnValue
    #>
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Api", "Cli")]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $VaultValue,

        [System.String]
        $CliPath,

        [System.String]
        $ApiPrefix,

        [parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        [System.String]
        $Description,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Disabled,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $FullName,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordChangeNotAllowed,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordChangeRequired,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordNeverExpires
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
        [ValidateSet("Api", "Cli")]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $VaultValue,

        [System.String]
        $CliPath,

        [System.String]
        $ApiPrefix,

        [parameter(Mandatory = $true)]
        [System.String]
        $UserName,

        [System.String]
        $Description,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $Disabled,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $FullName,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordChangeNotAllowed,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordChangeRequired,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $PasswordNeverExpires
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

