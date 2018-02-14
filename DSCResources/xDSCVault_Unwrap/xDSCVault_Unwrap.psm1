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

  $resourceData = Get-TargetResource -VaultMethod $VaultMethod -WrappedToken $WrappedToken -RoleId $RoleId -VaultAddress $VaultAddress -CliPath $CliPath -ApiPrefix $ApiPrefix
  if ($VaultMethod -eq 'CLI')
  {
    Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
  }
  else
  {
    $apiUri = ($resourceData.ApiPath + 'sys/wrapping/unwrap')
    $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
    $headers.Add('X-Vault-Token', $resourceData.WrappedToken)
    try
    {
      Write-Verbose -Message ($script:localizedData.AttemptUnwrap)
      $result = Invoke-RestMethod -Method Post -Uri $apiUri -Headers $headers -ErrorAction Stop
      Write-Verbose -Message ($script:localizedData.VaultMethod -f $VaultMethod)
      Remove-StoredCredential -Target $VaultAddress -ErrorAction SilentlyContinue
      New-StoredCredential -Target $resourceData.VaultAddress -Type Generic -UserName $resourceData.RoleId -Password $($result.data.secret_id) -Persist LocalMachine -ErrorAction Stop
    }
    catch
    {
      if ($_.Exception.Response.GetResponseStream() -ne $null) 
      {
        $responseBody = Read-RESTException -Exception $_.Exception.Response.GetResponseStream()
        if ($responseBody -match 'wrapping token is not valid or does not exist' ) 
        {
          Write-Error -Message ($script:localizedData.VaultTokenLookupInvalid)
        } 
      }
      else
      {
        Write-Error -Message $_.Exception
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
    }
    catch 
    {
      if ($_.Exception -match 'DNS name does not exist' )
      {
        Write-Error -Message ($script:localizedData.VaultDnsException)
      }
      else
      {
        Write-Error -Message $_.Exception
      }
    }

    $apiUri = ($resourceData.ApiPath + 'sys/wrapping/lookup')
    $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
    $headers.Add('X-Vault-Token', $resourceData.WrappedToken)

    try
    {
      Write-Verbose -Message ($script:localizedData.IsVaulttokenwrapped)
      $result = Invoke-RestMethod -Method Post -Uri $apiUri -Headers $headers -ErrorAction Stop
      Write-Verbose -Message ($script:localizedData.Vaulttokenisstillwrapped)
      $apiResult = ($script:localizedData.Resultwrapped)
    }
    catch
    {
      if ($_.Exception.Response.GetResponseStream() -ne $null) 
      {
        $responseBody = Read-RESTException -Exception $_.Exception.Response.GetResponseStream()
        if ($responseBody -match 'wrapping token is not valid or does not exist' ) 
        {
          Write-Verbose -Message ($script:localizedData.VaultTokenLookupInvalid)
          $apiResult = ($script:localizedData.Resulttokenerror)
        } 
      }
      else
      {
        Write-Error -Message $_.Exception
      }     
    }
  }

  if ($apiResult -ne 'tokenError') 
  {
    return $false
  }
  elseif ($apiResult -eq 'tokenError') {
    return $true
  }
}

Export-ModuleMember -Function *-TargetResource
