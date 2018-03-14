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
    $ApiPrefix = 'v1',

    [System.String]
    $AuthBackend = 'approle'

  )
  $credentials = Get-StoredCredential -Target $VaultAddress
  $apiUri = ($VaultAddress + '/' + $ApiPrefix + '/auth/' + $AuthBackend + '/login')
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
    if ($_.Exception.Response.GetResponseStream() -ne $null) 
    {
      $responseBody = Read-RESTException -Exception $_.Exception.Response.GetResponseStream()
      if ($responseBody -match 'permission denied' ) 
      {
        Write-Error -Message "Permission denied. Ensure you are using a token that has permissions to write to $VaultPath"
      } 
      elseif ($responseBody -match 'invalid secret_id' ) 
      {
        Write-Error -Message 'Failed to login: Invalid secret_id'
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
    Write-Verbose -Message 'Attempting to write secret'
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
      $responseBody = Read-RESTException -Exception $_.Exception.Response.GetResponseStream()
      if ($responseBody -match 'permission denied' ) 
      {
        Write-Error -Message "Permission denied. Ensure you are using a token that has permissions to write to $VaultPath"
      } 
      else 
      {
        "Error was $_"
        $line = $_.InvocationInfo.ScriptLineNumber
        "Error was in Line $line"      
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

<#
    .SYNOPSIS
    Tests if the current machine is a Nano server.
#>
function Test-IsNanoServer
{
  [OutputType([Boolean])]
  [CmdletBinding()]
  param ()

  $isNanoServer = $false
    
  if (Test-CommandExists -Name 'Get-ComputerInfo')
  {
    $computerInfo = Get-ComputerInfo -ErrorAction 'SilentlyContinue'

    if ($null -ne $computerInfo)
    {
      $computerIsServer = 'Server' -ieq $computerInfo.OsProductType

      if ($computerIsServer)
      {
        $isNanoServer = 'NanoServer' -ieq $computerInfo.OsServerLevel
      }
    }
  }

  return $isNanoServer
}

<#
    .SYNOPSIS
    Tests whether or not the command with the specified name exists.

    .PARAMETER Name
    The name of the command to test for.
#>
function Test-CommandExists
{
  [OutputType([Boolean])]
  [CmdletBinding()]
  param 
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $Name 
  )

  $command = Get-Command -Name $Name -ErrorAction 'SilentlyContinue'
  return ($null -ne $command)
}

<#
    .SYNOPSIS
    Creates and throws an invalid argument exception

    .PARAMETER Message
    The message explaining why this error is being thrown

    .PARAMETER ArgumentName
    The name of the invalid argument that is causing this error to be thrown
#>
function New-InvalidArgumentException
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Message,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ArgumentName
  )

  $argumentException = New-Object -TypeName 'ArgumentException' `
  -ArgumentList @($Message, $ArgumentName)
  $newObjectParams = @{
    TypeName     = 'System.Management.Automation.ErrorRecord'
    ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
  }
  $errorRecord = New-Object @newObjectParams

  throw $errorRecord
}

<#
    .SYNOPSIS
    Creates and throws an invalid operation exception

    .PARAMETER Message
    The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
    The error record containing the exception that is causing this terminating error
#>
function New-InvalidOperationException
{
  [CmdletBinding()]
  param
  (
    [ValidateNotNullOrEmpty()]
    [String]
    $Message,

    [ValidateNotNull()]
    [System.Management.Automation.ErrorRecord]
    $errorRecord
  )

  if ($null -eq $Message)
  {
    $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
  }
  elseif ($null -eq $errorRecord)
  {
    $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
    -ArgumentList @($Message)
  }
  else
  {
    $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
    -ArgumentList @($Message, $errorRecord.Exception)
  }

  $newObjectParams = @{
    TypeName     = 'System.Management.Automation.ErrorRecord'
    ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect', 
    'InvalidOperation', $null )
  }

  $errorRecordToThrow = New-Object @newObjectParams
  throw $errorRecordToThrow
}

<#
    .SYNOPSIS
    Retrieves the localized string data based on the machine's culture.
    Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
    The name of the resource as it appears before '.strings.psd1' of the localized string file.
    For example:
    For WindowsOptionalFeature: MSFT_WindowsOptionalFeature
    For Service: MSFT_ServiceResource
    For Registry: MSFT_RegistryResource
#>

Export-ModuleMember -Function @( 'Test-IsNanoServer', 'New-InvalidArgumentException', 
'New-InvalidOperationException', 'Read-RESTException', 'Get-LocalizedData', 'Write-VaultData', 'Read-VaultData', 'Start-VaultAuth' )