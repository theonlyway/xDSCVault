$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

function Read-RESTException
{
  [CmdletBinding()]
  Param
  (
    # Param1 help description
    [Parameter(Mandatory = $true,
    Position = 0)]
    $Exception
  )

  $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList ($Exception)
  $reader.BaseStream.Position = 0
  $reader.DiscardBufferedData()
  $responseBody = $reader.ReadToEnd()
  return $responseBody
}

function Get-LocalizedData
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceName
  )

  $resourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath $ResourceName
  $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

  if (-not (Test-Path -Path $localizedStringFileLocation))
  {
    # Fallback to en-US
    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
  }

  Import-LocalizedData `
  -BindingVariable 'localizedData' `
  -FileName "$ResourceName.strings.psd1" `
  -BaseDirectory $localizedStringFileLocation

  return $localizedData
}

function Start-VaultAuth
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory = $true,
    Position = 0)]   
    [System.String]
    $VaultAddress,

    [System.String]
    $ApiPrefix = 'v1'

  )
  $credentials = Get-StoredCredential -Target $VaultAddress
  $apiUri = ($VaultAddress + '/' + $ApiPrefix + '/auth/approle/login')
  $body = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
  $body.Add('role_id', $credentials.UserName)
  $body.Add('secret_id', [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($credentials.Password)))
  try
  {
    $apiResult = Invoke-RestMethod -Method Post -Uri $apiUri -Body ($body | ConvertTo-Json) -ContentType application/json -ErrorAction Stop
    return $apiResult
  }
  catch
  {
    "Error was $_"
    $line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
  }
}

function Write-VaultData
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory = $true,
    Position = 0)]   
    [System.String]
    $VaultAddress,

    [System.String]
    $ApiPrefix = 'v1',

    [Parameter(Mandatory = $true,
    Position = 1)]   
    [System.String]
    $VaultPath,

    [Parameter(Mandatory = $true,
    Position = 2)]   
    [System.String]
    $Value,

    [Parameter(Mandatory = $true,
    Position = 3)]   
    [System.String]
    $ClientToken

  )
  $apiUri = ($VaultAddress + '/' + $ApiPrefix + '/' + $VaultPath)

  $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
  $headers.Add('X-Vault-Token', $ClientToken)

  $body = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
  $body.Add('value', $Value)

  try
  {
    $apiResult = Invoke-RestMethod -Method Post -Uri $apiUri -Body ($body | ConvertTo-Json) -Headers $headers -ContentType application/json -ErrorAction Stop
  }
  catch
  {
    if ($_.Exception.Response.GetResponseStream() -ne $null) 
    {
      $responseBody = Read-RESTException -Exception $_.Exception.Response.GetResponseStream()
      if ($responseBody -match 'permission denied' ) 
      {
        Write-Error -Message "Permission denied. Ensure you are using a token that has permissions to write to $VaultPath"
      } 
    }
    else 
    {
      "Error was $_"
      $line = $_.InvocationInfo.ScriptLineNumber
      "Error was in Line $line"
    }
  }
}

function Read-VaultData
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory = $true,
    Position = 0)]   
    [System.String]
    $VaultAddress,

    [System.String]
    $ApiPrefix = 'v1',

    [Parameter(Mandatory = $true,
    Position = 1)]   
    [System.String]
    $VaultPath,

    [Parameter(Mandatory = $true,
    Position = 2)]   
    [System.String]
    $ClientToken

  )
  $apiUri = ($VaultAddress + '/' + $ApiPrefix + '/' + $VaultPath)

  $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
  $headers.Add('X-Vault-Token', $ClientToken)

  try
  {
    $apiResult = Invoke-RestMethod -Method Get -Uri $apiUri -Headers $headers -ErrorAction Stop
    return $apiResult
  }
  catch
  {
    if ($_.Exception.response.StatusCode.value__ -eq '404') 
    {
      Write-Verbose -Message "Returned 404. No value found at $VaultPath"
      $apiResult = 404
      return $apiResult
    }
    elseif ($_.Exception.Response.GetResponseStream() -ne $null) 
    {
      $blah = $_.Exception 
      $responseBody = Read-RESTException -Exception $_.Exception.Response.GetResponseStream()
      if ($responseBody -match 'permission denied' ) 
      {
        Write-Error -Message "Permission denied. Ensure you are using a token that has permissions to write to $VaultPath"
      } 
    }
    else 
    {
      "Error was $_"
      $line = $_.InvocationInfo.ScriptLineNumber
      "Error was in Line $line"
    }
  }
}


Export-ModuleMember -Function @( 'Read-RESTException', 'Get-LocalizedData', 'Write-VaultData', 'Read-VaultData', 'Start-VaultAuth' )