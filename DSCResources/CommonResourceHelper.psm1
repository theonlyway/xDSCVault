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
    # Param1 help description
    [Parameter(Mandatory = $true,
    Position = 0)]   
    [System.String]
    $VaultAddress,

    [System.String]
    $ApiPrefix = 'v1'

  )
  $credentials = Get-StoredCredential -Target $VaultAddress
  $apiUri = ($VaultAddress + '/' + $ApiPrefix + '/auth/approle/login')
  $headers = New-Object -TypeName 'System.Collections.Generic.Dictionary[[String],[String]]'
  $headers.Add('role_id', $credentials.UserName)
  $headers.Add('secret_id', [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($credentials.Password)))
  try
  {
    $apiResult = Invoke-RestMethod -Method Post -Uri $apiUri -Body ($headers | ConvertTo-Json) -ContentType application/json -ErrorAction Stop
    return $apiResult
  }
  catch
  {
    "Error was $_"
    $line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
  }
}


Export-ModuleMember -Function @( 'Read-RESTException', 'Get-LocalizedData' )