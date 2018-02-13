$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
-ChildPath 'CommonResourceHelper.psm1')

# Localized messages for verbose and error statements in this resource
$script:localizedData = Get-LocalizedData -ResourceName 'xDSCVault_Unwrap'

function Get-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('CLI', 'API')]
    [System.String]
    $VaultMethod,

    [parameter(Mandatory = $true)]        
    [System.String]
    $WrappedToken,

    [parameter(Mandatory = $true)]        
    [System.String]
    $RoleId,

    [parameter(Mandatory = $true)]        
    [System.String]
    $VaultAddress,

    [System.String]
    $CliPath = $null,
   
    [System.String]
    $ApiPrefix = 'v1'
  )

  $returnValue = @{
    VaultMethod  = $VaultMethod
    WrappedToken = $WrappedToken
    RoleId       = $RoleId
    VaultAddress = $VaultAddress
    CliPath      = $CliPath
    ApiPrefix    = $ApiPrefix
    ApiPath      = ($VaultAddress + '/' + $ApiPrefix + '/')
  }

  $returnValue
}


function Set-TargetResource
{
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('CLI', 'API')]
    [System.String]
    $VaultMethod,

    [parameter(Mandatory = $true)]        
    [System.String]
    $WrappedToken,

    [parameter(Mandatory = $true)]        
    [System.String]
    $RoleId,

    [parameter(Mandatory = $true)]        
    [System.String]
    $VaultAddress,

    [System.String]
    $CliPath = $null,
   
    [System.String]
    $ApiPrefix = 'v1'
  )

  $result = [string]::Empty

  $resourceData = Get-TargetResource -VaultMethod $VaultMethod -WrappedToken $WrappedToken -RoleId $RoleId -VaultAddress $VaultAddress -CliPath $CliPath -ApiPrefix $ApiPrefix
  if ($VaultMethod -eq 'CLI')
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
  }
  else
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
    $unwrapApi = ($resourceData.ApiPath + 'sys/wrapping/unwrap')
    $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
    $headers.Add('X-Vault-Token', $resourceData.WrappedToken)
    try
    {
      $result = Invoke-RestMethod -Method Post -Uri $unwrapApi -Headers $headers -ErrorAction Stop
      New-StoredCredential -Target $resourceData.VaultAddress -Type Generic -UserName $resourceData.RoleId -Password $($result.data.secret_id) -Persist LocalMachine
    }
    catch
    {
      $responseBody = Read-RESTResponse -Response $result
      if ($responseBody -match 'wrapping token is not valid or does not exist' ) 
      {
        Write-Error -Message ($script:localizedData.VaultTokenLookupInvalid)
        return $false
      }
      else
      {
        Write-Error -Message ('Error was {0}' -f $_)
        return $false
      }
    }
  }
}


function Test-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Boolean])]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('CLI', 'API')]
    [System.String]
    $VaultMethod,

    [parameter(Mandatory = $true)]        
    [System.String]
    $WrappedToken,

    [parameter(Mandatory = $true)]        
    [System.String]
    $RoleId,

    [parameter(Mandatory = $true)]        
    [System.String]
    $VaultAddress,

    [System.String]
    $CliPath = $null,
   
    [System.String]
    $ApiPrefix = 'v1'
  )

  $resourceData = Get-TargetResource -VaultMethod $VaultMethod -WrappedToken $WrappedToken -RoleId $RoleId -VaultAddress $VaultAddress -CliPath $CliPath -ApiPrefix $ApiPrefix

  $result = [string]::Empty

  if ($VaultMethod -eq 'CLI')
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
    if ($CliPath -ne $null)
    {
      if ((Test-Path -Path $CliPath) -eq $true)
      {
        try
        {
          Write-Verbose -Message ($script:localizedData.CheckingDNS -f $VaultAddress)
          $regex = $VaultAddress -match '(?<=://).+'
          $dns = Resolve-DnsName -Name $matches[0] -ErrorAction Stop
        }
        catch
        {
          if ($_.Exception -match 'DNS name does not exist' )
          {
            Write-Error -Message ($script:localizedData.VaultDnsException)
            return $false
          }
          else
          {
            return $false
          }
        }
      }
      else
      {
        return $false
      }
    }
    else
    {
      Write-Error -Message 'Cli path is null'
      return $false
    }
  }
  else
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
    try
    {
      Write-Verbose -Message ($script:localizedData.CheckingDNS -f $VaultAddress)
      $regex = $VaultAddress -match '(?<=://).+'
      $dns = Resolve-DnsName -Name $matches[0] -ErrorAction Stop
      try
      {
        Write-Error -Message ($script:localizedData.Vaultissecretwrapped)
        $unwrapLookupApi = ($resourceData.ApiPath + 'sys/wrapping/lookup')
        $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
        $headers.Add('X-Vault-Token', $resourceData.WrappedToken)
        $result = Invoke-RestMethod -Method Post -Uri $unwrapLookupApi -Headers $headers
        return $true
      }
      catch
      {
        $responseBody = Read-RESTResponse -Response $result
        if ($responseBody -match 'wrapping token is not valid or does not exist' ) 
        {
          Write-Error -Message ($script:localizedData.VaultTokenLookupInvalid)
          return $false
        }
        else
        {
          Write-Error -Message ('Error was {0}' -f $_)
          return $false
        }
      }
    }
    catch
    {
      if ($_.Exception -match 'DNS name does not exist' )
      {
        Write-Error -Message ($script:localizedData.VaultDnsException)
        return $false
      }
      else
      {
        return $false
      }
    }
  }
}

Export-ModuleMember -Function *-TargetResource
