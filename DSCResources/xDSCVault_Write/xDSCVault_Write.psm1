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
        [System.String]
        $VaultAddress,

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $VaultValue,

        [System.String]
        $ApiPrefix = 'v1',
    
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $RandomSecret,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $ForceUpdate,

        [System.String]
        $AuthBackend = 'approle'
    )

    Write-Verbose -Message ($script:localizedData.ObtainClientToken)
    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend

    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $VaultPath -ApiPrefix $ApiPrefix
  
    if ($clientToken.auth.client_token -ne $null) 
    {
        $clientTokenResult = 'Client token retrieved'
    }
    else 
    {
        $clientTokenResult = 'Error obtaining client token'
    }
  
    if ($currentVaultValue -ne 404) 
    {
        $currentVaultValueOutput = $currentVaultValue.data.value
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
        VaultAddress      = $VaultAddress
        VaultPath         = $VaultPath
        VaultValue        = $VaultValue
        ApiPath           = ($VaultAddress + '/' + $ApiPrefix + '/' + $VaultPath)
        ClientToken       = $clientTokenResult
        CurrentVaultValue = $currentVaultValueOutput
        ReadResultStatus  = $readResult
        RandomSecret      = $RandomSecret
        ForceUpdate       = $ForceUpdate
        AuthBackend       = $AuthBackend
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

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $VaultValue,

        [System.String]
        $ApiPrefix = 'v1',

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $RandomSecret,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $ForceUpdate,

        [System.String]
        $AuthBackend = 'approle'
    )

    $resourceData = Get-TargetResource @PSBoundParameters

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    
    if ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $true -and $resourceData.RandomSecret -eq $true) 
    {
        Write-Verbose -Message ($script:localizedData.ValueEmptywithRandomSecretTrue)
        if ([string]::IsNullOrEmpty($resourceData.CurrentVaultValue) -ne $true -and $resourceData.RandomSecret -eq $true -and $resourceData.ForceUpdate -eq $false) 
        {
            Write-Verbose -Message ($script:localizedData.ValueEmptywithRandomSecretTrueNoForce)
        }
        elseif ([string]::IsNullOrEmpty($resourceData.CurrentVaultValue) -ne $true -and $resourceData.RandomSecret -eq $true -and $resourceData.ForceUpdate -eq $true) 
        {
            Write-Verbose -Message ($script:localizedData.ValueEmptywithRandomSecretTrueWithForce)
            Write-VaultData -VaultAddress $resourceData.VaultAddress -VaultPath $resourceData.VaultPath -Value (Get-StrongPassword -Length 20 -NumberOfSpecialCharacters 2) -ClientToken $clientToken.auth.client_token -Verbose
        }
        if ([string]::IsNullOrEmpty($resourceData.CurrentVaultValue) -eq $true -and $resourceData.RandomSecret -eq $true -and $resourceData.ForceUpdate -eq $false) 
        {
            Write-Verbose -Message ($script:localizedData.AllValuesEmptywithRandomSecretTrueNoForce)
            Write-VaultData -VaultAddress $resourceData.VaultAddress -VaultPath $resourceData.VaultPath -Value (Get-StrongPassword -Length 20 -NumberOfSpecialCharacters 2) -ClientToken $clientToken.auth.client_token -Verbose
        }
    }
    elseif ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $false -and $resourceData.RandomSecret -eq $true) 
    {
        Write-Error -Message ($script:localizedData.VaultValueTruewithRandomSecretTrue)
    }
    elseif ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $true -and $resourceData.RandomSecret -eq $false) 
    {
        Write-Error -Message ($script:localizedData.VaultValueFalsewithRandomSecretFalse)
    }
    elseif ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $false -and $resourceData.RandomSecret -eq $false) 
    {
        Write-Verbose -Message ($script:localizedData.VaultValueTruewithRandomSecretFalse)
        if ($resourceData.VaultValue -eq $resourceData.CurrentVaultValue) 
        {
            Write-Verbose -Message ($script:localizedData.VaultValueMatchesSupplied -f $VaultPath)
        }
        elseif ($resourceData.VaultValue -ne $resourceData.CurrentVaultValue) 
        {
            Write-Verbose -Message ($script:localizedData.VaultValueDoesNotMatchSupplied -f $VaultPath)
            Write-VaultData -VaultAddress $resourceData.VaultAddress -VaultPath $resourceData.VaultPath -Value $resourceData.VaultValue -ClientToken $clientToken.auth.client_token -Verbose
        }
    }
    else 
    {
        Write-Verbose -Message ($script:localizedData.UnknownError)
        return $false  
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

        [parameter(Mandatory = $true)]
        [System.String]
        $VaultPath,

        [System.String]
        $VaultValue = [string]::Empty,

        [System.String]
        $ApiPrefix = 'v1',

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $RandomSecret,

        [parameter(Mandatory = $true)]
        [System.Boolean]
        $ForceUpdate,

        [System.String]
        $AuthBackend = 'approle'
    )

    $resourceData = Get-TargetResource @PSBoundParameters
   
    if ($resourceData.ReadResultStatus -eq 404) 
    {
        Write-Verbose -Message ($script:localizedData.Returned404 -f $VaultPath)
        return $false
    }
    
    if ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $true -and $resourceData.RandomSecret -eq $true) 
    {
        Write-Verbose -Message ($script:localizedData.ValueEmptywithRandomSecretTrue)
        if ([string]::IsNullOrEmpty($resourceData.CurrentVaultValue) -ne $true -and $resourceData.RandomSecret -eq $true -and $resourceData.ForceUpdate -eq $false) 
        {
            Write-Verbose -Message ($script:localizedData.ValueEmptywithRandomSecretTrueNoForce)
            return $true
        }
        elseif ([string]::IsNullOrEmpty($resourceData.CurrentVaultValue) -ne $true -and $resourceData.RandomSecret -eq $true -and $resourceData.ForceUpdate -eq $true) 
        {
            Write-Verbose -Message ($script:localizedData.ValueEmptywithRandomSecretTrueWithForce)
            return $false
        }
        if ([string]::IsNullOrEmpty($resourceData.CurrentVaultValue) -eq $true -and $resourceData.RandomSecret -eq $true -and $resourceData.ForceUpdate -eq $false) 
        {
            Write-Verbose -Message ($script:localizedData.AllValuesEmptywithRandomSecretTrueNoForce)
            return $true
        }
    }
    elseif ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $false -and $resourceData.RandomSecret -eq $true) 
    {
        Write-Error -Message ($script:localizedData.VaultValueTruewithRandomSecretTrue)
    }
    elseif ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $true -and $resourceData.RandomSecret -eq $false) 
    {
        Write-Error -Message ($script:localizedData.VaultValueFalsewithRandomSecretFalse)
    }
    elseif ([string]::IsNullOrEmpty($resourceData.VaultValue) -eq $false -and $resourceData.RandomSecret -eq $false) 
    {
        Write-Verbose -Message ($script:localizedData.VaultValueTruewithRandomSecretFalse)

        if ($resourceData.VaultValue -eq $resourceData.CurrentVaultValue) 
        {
            Write-Verbose -Message ($script:localizedData.VaultValueMatchesSupplied -f $VaultPath)
            return $true        
        }
        elseif ($resourceData.VaultValue -ne $resourceData.CurrentVaultValue) 
        {
            Write-Verbose -Message ($script:localizedData.VaultValueDoesNotMatchSupplied -f $VaultPath)
            return $false
        }
    }
    else 
    {
        Write-Verbose -Message ($script:localizedData.UnknownError)
        return $false  
    }
}


Export-ModuleMember -Function *-TargetResource

