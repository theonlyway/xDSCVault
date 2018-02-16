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

  if ($clientToken.auth.client_token -ne $null) 
  {
    $tokenResult = 'Token retrieved'
  }

  $returnValue = @{
    VaultMethod       = $VaultMethod
    VaultAddress      = $VaultAddress
    VaultPath         = $VaultPath
    VaultValue        = $VaultValue
    ApiPath           = ($VaultAddress + '/' + $ApiPrefix + '/' + $VaultPath)
    ClientToken       = $tokenResult
    currentVaultValue = $currentVaultValue.data.value
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

  if ($resourceData.data.value -eq $VaultValue) 
  {
    Write-Verbose -Message ($script:localizedData.VaultValueMatchesSupplied)
  }
}


Export-ModuleMember -Function *-TargetResource