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
    [ValidateSet('Api','Cli')]
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
    $ApiPrefix = 'v1'
  )

  Write-Verbose -Message ($script:localizedData.ObtainClientToken)
  $clientToken = Start-VaultAuth -VaultAddress $VaultAddress

  $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $VaultPath
  
  if ($clientToken.auth.client_token -ne $null) {
    $clientTokenResult = 'Client token retrieved' 
  }
  else {
    $clientTokenResult = 'Error obtaining client token'   
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
    VaultMethod       = $VaultMethod
    VaultAddress      = $VaultAddress
    VaultPath         = $VaultPath
    VaultValue        = $VaultValue
    ApiPath           = ($VaultAddress + '/' + $ApiPrefix + '/' + $VaultPath)
    ClientToken       = $clientTokenResult
    CurrentVaultValue = $currentVaultValue.data.value
    ReadResultStatus  = $readResult
  }

  $returnValue
}


function Set-TargetResource
{
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('Api','Cli')]
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
    $ApiPrefix = 'v1'
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
    [ValidateSet('Api','Cli')]
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
    $ApiPrefix = 'v1'
  )

  $resourceData = Get-TargetResource -VaultMethod $VaultMethod -VaultAddress $VaultAddress -VaultPath $VaultPath -VaultValue $VaultValue -ApiPrefix $ApiPrefix

  if ($VaultMethod -eq 'Api') 
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
     
    if ($resourceData.CurrentVaultValue -eq $VaultValue) 
    {
      Write-Verbose -Message ($script:localizedData.VaultValueMatchesSupplied -f $VaultPath)
      return $true
    }
    elseif ($resourceData.CurrentVaultValue -ne $VaultValue -and $resourceData.CurrentVaultValue -ne $null) 
    {
      Write-Verbose -Message ($script:localizedData.VaultValueDoesNotMatchSupplied -f $VaultPath)
      return $false
    }
    elseif (if $resourceData.ReadResultStatus -eq 404) 
    {
      Write-Verbose -Message ($script:localizedData.Returned404 -f $VaultPath)
      return $false
    }
    else 
    {
      Write-Verbose -Message ($script:localizedData.UnknownError)
      return $false  
    }
  }
  else 
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
  }
}


Export-ModuleMember -Function *-TargetResource