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
        $VaultPath
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $returnValue = @{
    VaultMethod = [System.String]
    VaultAddress = [System.String]
    VaultPath = [System.String]
    CliPath = [System.String]
    ApiPrefix = [System.String]
    ApiPath = [System.String]
    DomainName = [System.String]
    ParentDomainName = [System.String]
    DomainNetBIOSName = [System.String]
    DatabasePath = [System.String]
    LogPath = [System.String]
    SysvolPath = [System.String]
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
        [ValidateSet("Api","Cli")]
        [System.String]
        $VaultMethod,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $CliPath,

        [System.String]
        $ApiPrefix,

        [System.String]
        $DomainName,

        [System.String]
        $ParentDomainName,

        [System.String]
        $DomainNetBIOSName,

        [System.String]
        $DatabasePath,

        [System.String]
        $LogPath,

        [System.String]
        $SysvolPath
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

        [System.String]
        $CliPath,

        [System.String]
        $ApiPrefix,

        [System.String]
        $DomainName,

        [System.String]
        $ParentDomainName,

        [System.String]
        $DomainNetBIOSName,

        [System.String]
        $DatabasePath,

        [System.String]
        $LogPath,

        [System.String]
        $SysvolPath
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

