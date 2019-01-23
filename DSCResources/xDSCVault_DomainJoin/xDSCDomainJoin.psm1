[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$errorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $ApiPrefix = 'v1',

        [System.String]
        $AuthBackend = 'approle',

        [Parameter(Mandatory = $true)]
        [System.String]
        $Domain,

        [Parameter(Mandatory = $true)]
        [string]$CredentialVaultPath,

        [string]$JoinOU
    )

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorVaultPath

    $convertToCimCredential = New-CimInstance -ClassName MSFT_Credential -Property @{ Username = [string]$Credential.Username; Password = [string]$null } -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly

    $returnValue = @{
        Domain     = (gwmi win32_computersystem).Domain
        JoinOU     = $JoinOU
        Credential = [ciminstance]$convertToCimCredential
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Domain,

        [Parameter(Mandatory = $true)]
        [pscredential]$Credential,

        [string]$JoinOU
    )

    if ($JoinOU)
    {
        Add-Computer -DomainName $Domain -Credential $Credential -OUPath $JoinOU -Force -Restart
    }
    else
    {
        Add-Computer -DomainName $Domain -Credential $Credential -Force -Restart
    }


}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Domain,

        [Parameter(Mandatory = $true)]
        [pscredential]$Credential,

        [string]$JoinOU
    )

    if ($Domain.ToLower() -eq (gwmi win32_computersystem).Domain)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
