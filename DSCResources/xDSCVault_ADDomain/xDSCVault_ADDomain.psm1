# User name and password needed for this resource and Write-Verbose Used in helper functions
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()
$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
-ChildPath 'CommonResourceHelper.psm1')

# Localized messages for verbose and error statements in this resource
$script:script:localizedData = Get-script:localizedData -ResourceName 'xDSCVault_ADDomain'

function Get-TrackingFilename
{
  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]
    $DomainName
  )

  return Join-Path -Path ($env:temp) -ChildPath ('{0}.xADDomain.completed' -f $DomainName)
}
function Get-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('Api', 'Cli')]
    [System.String]
    $VaultMethod,

    [parameter(Mandatory = $true)]
    [System.String]
    $VaultAddress,

    [System.String]
    $CliPath,

    [System.String]
    $ApiPrefix,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainName,

    [System.String]
    $ParentDomainName,

    [System.String]
    $DomainNetBIOSName,

    [System.String]
    $DatabasePath,

    [System.String]
    $LogPath,

    [System.String]
    $SysvolPath,

    [System.String]
    $DnsDelegationUserName,

    [System.String]
    $DnsDelegationVaultPath,

    [parameter(Mandatory = $true)]
    [System.String]
    $SafemodeAdministratorPasswordVaultPath,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainAdministratorUsername,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainAdministratorVaultPath
  )

  Assert-Module -ModuleName 'ADDSDeployment'
  $domainFQDN = Resolve-DomainFQDN -DomainName $DomainName -ParentDomainName $ParentDomainName
  $isDomainMember = Test-DomainMember

  $retries = 0
  $maxRetries = 5
  $retryIntervalInSeconds = 30
  $domainShouldExist = (Test-Path (Get-TrackingFilename -DomainName $DomainName))
  do
  {            
    try
    {
      if ($isDomainMember)
      {
        ## We're already a domain member, so take the credentials out of the equation
        Write-Verbose -Message ($script:localizedData.QueryDomainADWithLocalCredentials -f $domainFQDN)
        $domain = Get-ADDomain -Identity $domainFQDN -ErrorAction Stop
      }
      else
      {
        $clientToken = Start-VaultAuth -VaultAddress $VaultAddress
        $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorVaultPath
        $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
        $DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DomainAdministratorUsername, $VaultValue)
        Write-Verbose -Message ($script:localizedData.QueryDomainWithCredential -f $domainFQDN)
        $domain = Get-ADDomain -Identity $domainFQDN -Credential $DomainAdministratorCredential -ErrorAction Stop
      }

      ## No need to check whether the node is actually a domain controller. If we don't throw an exception,
      ## the domain is already UP - and this resource shouldn't run. Domain controller functionality
      ## should be checked by the xADDomainController resource?
      Write-Verbose -Message ($script:localizedData.DomainFound -f $domain.DnsRoot)
        
      $targetResource = @{
        DomainName        = $domain.DnsRoot
        ParentDomainName  = $domain.ParentDomain
        DomainNetBIOSName = $domain.NetBIOSName
      }
        
      return $targetResource
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
      $errorMessage = $script:localizedData.ExistingDomainMemberError -f $DomainName
      ThrowInvalidOperationError -ErrorId 'xADDomain_DomainMember' -ErrorMessage $errorMessage
    }
    catch [Microsoft.ActiveDirectory.Management.ADServerDownException]
    {
      Write-Verbose -Message ($script:localizedData.DomainNotFound -f $domainFQDN)
      $domain = @{ }
      # will fall into retry mechanism
    }
    catch [System.Security.Authentication.AuthenticationException]
    {
      $errorMessage = $script:localizedData.InvalidCredentialError -f $DomainName
      ThrowInvalidOperationError -ErrorId 'xADDomain_InvalidCredential' -ErrorMessage $errorMessage
    }
    catch
    {
      $errorMessage = $script:localizedData.UnhandledError -f ($_.Exception |
        Format-List -Force |
      Out-String)
      Write-Verbose -Message $errorMessage

      if ($domainShouldExist -and ($_.Exception.InnerException -is [System.ServiceModel.FaultException]))
      {
        Write-Verbose -Message $script:localizedData.FaultExceptionAndDomainShouldExist
        # will fall into retry mechanism
      }
      else
      {
        ## Not sure what's gone on here!
        throw $_
      }
    }

    if ($domainShouldExist)
    {
      $retries++
      Write-Verbose -Message ($script:localizedData.RetryingGetADDomain -f $retries, $maxRetries, $retryIntervalInSeconds)
      Start-Sleep -Seconds ($retries * $retryIntervalInSeconds)
    }
  }
  while ($domainShouldExist -and ($retries -le $maxRetries) )
}


function Set-TargetResource
{
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('Api', 'Cli')]
    [System.String]
    $VaultMethod,

    [parameter(Mandatory = $true)]
    [System.String]
    $VaultAddress,

    [System.String]
    $CliPath,

    [System.String]
    $ApiPrefix,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainName,

    [System.String]
    $ParentDomainName,

    [System.String]
    $DomainNetBIOSName,

    [System.String]
    $DatabasePath,

    [System.String]
    $LogPath,

    [System.String]
    $SysvolPath,

    [System.String]
    $DnsDelegationUserName,

    [System.String]
    $DnsDelegationVaultPath,

    [parameter(Mandatory = $true)]
    [System.String]
    $SafemodeAdministratorPasswordVaultPath,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainAdministratorUsername,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainAdministratorVaultPath
  )

    # Debug can pause Install-ADDSForest/Install-ADDSDomain, so we remove it.
    [ref] $null = $PSBoundParameters.Remove("Debug");
    ## Not entirely necessary, but run Get-TargetResouece to ensure we raise any pre-flight errors.
    $targetResource = Get-TargetResource @PSBoundParameters;
    
    $installADDSParams = @{
        SafeModeAdministratorPassword = $SafemodeAdministratorPassword.Password;
        NoRebootOnCompletion = $true;
        Force = $true;
    }
    
    if ($PSBoundParameters.ContainsKey('DnsDelegationCredential'))
    {
        $installADDSParams['DnsDelegationCredential'] = $DnsDelegationCredential;
        $installADDSParams['CreateDnsDelegation'] = $true;
    }
    if ($PSBoundParameters.ContainsKey('DatabasePath'))
    {
        $installADDSParams['DatabasePath'] = $DatabasePath;
    }
    if ($PSBoundParameters.ContainsKey('LogPath'))
    {
        $installADDSParams['LogPath'] = $LogPath;
    }
    if ($PSBoundParameters.ContainsKey('SysvolPath'))
    {
        $installADDSParams['SysvolPath'] = $SysvolPath;
    }
    
    if ($PSBoundParameters.ContainsKey('ParentDomainName'))
    {
        Write-Verbose -Message ($script:localizedData.CreatingChildDomain -f $DomainName, $ParentDomainName);
        $installADDSParams['Credential'] = $DomainAdministratorCredential
        $installADDSParams['NewDomainName'] = $DomainName
        $installADDSParams['ParentDomainName'] = $ParentDomainName
        $installADDSParams['DomainType'] = 'ChildDomain';
        if ($PSBoundParameters.ContainsKey('DomainNetBIOSName'))
        {
            $installADDSParams['NewDomainNetbiosName'] = $DomainNetBIOSName;
        }
        Install-ADDSDomain @installADDSParams;
        Write-Verbose -Message ($script:localizedData.CreatedChildDomain);
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.CreatingForest -f $DomainName);
        $installADDSParams['DomainName'] = $DomainName;
        if ($PSBoundParameters.ContainsKey('DomainNetbiosName'))
        {
            $installADDSParams['DomainNetbiosName'] = $DomainNetBIOSName;
        }
        Install-ADDSForest @installADDSParams;
        Write-Verbose -Message ($script:localizedData.CreatedForest -f $DomainName); 
    }  

    "Finished" | Out-File -FilePath (Get-TrackingFilename -DomainName $DomainName) -Force

    # Signal to the LCM to reboot the node to compensate for the one we
    # suppressed from Install-ADDSForest/Install-ADDSDomain
    $global:DSCMachineStatus = 1
}


function Test-TargetResource
{
  [CmdletBinding()]
  [OutputType([System.Boolean])]
  param
  (
    [parameter(Mandatory = $true)]
    [ValidateSet('Api', 'Cli')]
    [System.String]
    $VaultMethod,

    [parameter(Mandatory = $true)]
    [System.String]
    $VaultAddress,

    [System.String]
    $CliPath,

    [System.String]
    $ApiPrefix,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainName,

    [System.String]
    $ParentDomainName,

    [System.String]
    $DomainNetBIOSName,

    [System.String]
    $DatabasePath,

    [System.String]
    $LogPath,

    [System.String]
    $SysvolPath,

    [System.String]
    $DnsDelegationUserName,

    [System.String]
    $DnsDelegationVaultPath,

    [parameter(Mandatory = $true)]
    [System.String]
    $SafemodeAdministratorPasswordVaultPath,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainAdministratorUsername,

    [parameter(Mandatory = $true)]
    [System.String]
    $DomainAdministratorVaultPath
  )

    $targetResource = Get-TargetResource @PSBoundParameters
    $isCompliant = $true;

    ## The Get-Target resource returns .DomainName as the domain's FQDN. Therefore, we
    ## need to resolve this before comparison.
    $domainFQDN = Resolve-DomainFQDN -DomainName $DomainName -ParentDomainName $ParentDomainName
    if ($domainFQDN -ne $targetResource.DomainName)
    {
        $message = $script:localizedData.ResourcePropertyValueIncorrect -f 'DomainName', $domainFQDN, $targetResource.DomainName;
        Write-Verbose -Message $message;
        $isCompliant = $false;   
    }
    
    $propertyNames = @('ParentDomainName','DomainNetBIOSName');
    foreach ($propertyName in $propertyNames)
    {
        if ($PSBoundParameters.ContainsKey($propertyName))
        {
            $propertyValue = (Get-Variable -Name $propertyName).Value;
            if ($targetResource.$propertyName -ne $propertyValue)
            {
                $message = $script:localizedData.ResourcePropertyValueIncorrect -f $propertyName, $propertyValue, $targetResource.$propertyName;
                Write-Verbose -Message $message;
                $isCompliant = $false;        
            }
        }
    }
        
    if ($isCompliant)
    {
        Write-Verbose -Message ($script:localizedData.ResourceInDesiredState -f $domainFQDN);
        return $true;
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.ResourceNotInDesiredState -f $domainFQDN);
        return $false;
    }
}

## Import the common AD functions
$adCommonFunctions = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath '\MSFT_xADCommon\MSFT_xADCommon.ps1';
. $adCommonFunctions;

Export-ModuleMember -Function *-TargetResource

