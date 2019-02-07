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
        [System.String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $JoinOU
    )

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $VaultPath -ApiPrefix $ApiPrefix

    if ($clientToken.auth.client_token -ne $null)
    {
        $clientTokenResult = ConvertTo-SecureString -String $clientToken.auth.client_token -AsPlainText -Force
    }
    else
    {
        $clientTokenResult = 'Error obtaining client token'
    }

    if ($currentVaultValue -ne 404)
    {
        $currentVaultValueOutput = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    }
    else
    {
        $currentVaultValueOutput = $null
    }

    if ($currentVaultValue -eq 404)
    {
        $readResult = $currentVaultValue
    }
    else
    {
        $readResult = 200
    }

    $returnValue = @{
        Domain     = (gwmi win32_computersystem).Domain
        JoinOU     = $JoinOU
        Credential = $currentVaultValueOutput
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
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
        [System.String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $JoinOU
    )

    $resourceData = Get-TargetResource @PSBoundParameters

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($UserName, $resourceData.CurrentVaultValue)

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
        [System.String]
        $UserName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $JoinOU
    )

    $resourceData = Get-TargetResource @PSBoundParameters

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
