# User name and password needed for this resource and Write-Verbose Used in helper functions
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()
$errorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

# Localized messages for verbose and error statements in this resource
$script:localizedData = Get-LocalizedData -ResourceName 'xDSCVault_ADDomain'

<#
    .SYNOPSIS
    Retrieves the name of the file that tracks the status of the xADDomain resource with the
    specified domain name.

    .PARAMETER DomainName
    The domain name of the xADDomain resource to retrieve the tracking file name of.

    .NOTES
    The tracking file is currently output to the environment's temp directory.
        
    This file is NOT removed when a configuration completes, so if another call to a xADDomain
    resource with the same domain name occurs in the same environment, this file will already
    be present.
        
    This is so that when another call is made to the same resource, the resource will not
    attempt to promote the machine to a domain controller again (which would cause an error).
        
    If the resource should be promoted to a domain controller once again, you must first remove
    this file from the environment's temp directory (usually C:\Temp).

    If in the future this functionality needs to change so that future configurations are not
    affected, $env:temp should be changed to the resource's cache location which is removed
    after each configuration.
    ($env:systemRoot\system32\Configuration\BuiltinProvCache\MSFT_xADDomain)
#>
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
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $ApiPrefix = 'v1',

        [Parameter(Mandatory)]
        [System.String] $DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorUsername,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorVaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $SafemodeAdministratorPasswordVaultPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $ParentDomainName,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $DomainNetBIOSName,

        [System.String]
        $DnsDelegationUserName,

        [System.String]
        $DnsDelegationVaultPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $DatabasePath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $SysvolPath,

        [System.String]
        $AuthBackend = 'approle'
    )
    
    Assert-Module -ModuleName 'ADDSDeployment'
    $domainFQDN = Resolve-DomainFQDN -DomainName $DomainName -ParentDomainName $ParentDomainName
    $isDomainMember = Test-DomainMember

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorVaultPath
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)

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
                Write-Verbose -Message ($localizedData.QueryDomainADWithLocalCredentials -f $domainFQDN)
                $domain = Get-ADDomain -Identity $domainFQDN -ErrorAction Stop
            }
            else
            {
                Write-Verbose -Message ($localizedData.QueryDomainWithCredential -f $domainFQDN)
                $domain = Get-ADDomain -Identity $domainFQDN -Credential $DomainAdministratorCredential -ErrorAction Stop
            }

            ## No need to check whether the node is actually a domain controller. If we don't throw an exception,
            ## the domain is already UP - and this resource shouldn't run. Domain controller functionality
            ## should be checked by the xADDomainController resource?
            Write-Verbose -Message ($localizedData.DomainFound -f $domain.DnsRoot)
        
            $targetResource = @{
                DomainName        = $domain.DnsRoot
                ParentDomainName  = $domain.ParentDomain
                DomainNetBIOSName = $domain.NetBIOSName
            }
        
            return $targetResource
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            $errorMessage = $localizedData.ExistingDomainMemberError -f $DomainName
            ThrowInvalidOperationError -ErrorId 'xADDomain_DomainMember' -ErrorMessage $errorMessage
        }
        catch [Microsoft.ActiveDirectory.Management.ADServerDownException]
        {
            Write-Verbose -Message ($localizedData.DomainNotFound -f $domainFQDN)
            $domain = @{ }
            # will fall into retry mechanism
        }
        catch [System.Security.Authentication.AuthenticationException]
        {
            $errorMessage = $localizedData.InvalidCredentialError -f $DomainName
            ThrowInvalidOperationError -ErrorId 'xADDomain_InvalidCredential' -ErrorMessage $errorMessage
        }
        catch
        {
            $errorMessage = $localizedData.UnhandledError -f ($_.Exception |
                    Format-List -Force |
                    Out-String)
            Write-Verbose -Message $errorMessage

            if ($domainShouldExist -and ($_.Exception.InnerException -is [System.ServiceModel.FaultException]))
            {
                Write-Verbose -Message $localizedData.FaultExceptionAndDomainShouldExist
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
            Write-Verbose -Message ($localizedData.RetryingGetADDomain -f $retries, $maxRetries, $retryIntervalInSeconds)
            Start-Sleep -Seconds ($retries * $retryIntervalInSeconds)
        }
    }
    while ($domainShouldExist -and ($retries -le $maxRetries) )
} #end function Get-TargetResource

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $ApiPrefix = 'v1',

        [Parameter(Mandatory)]
        [System.String] $DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorUsername,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorVaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $SafemodeAdministratorPasswordVaultPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $ParentDomainName,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $DomainNetBIOSName,

        [System.String]
        $DnsDelegationUserName,

        [System.String]
        $DnsDelegationVaultPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $DatabasePath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $SysvolPath,

        [System.String]
        $AuthBackend = 'approle'
    )

    $targetResource = Get-TargetResource @PSBoundParameters
    $isCompliant = $true

    ## The Get-Target resource returns .DomainName as the domain's FQDN. Therefore, we
    ## need to resolve this before comparison.
    $domainFQDN = Resolve-DomainFQDN -DomainName $DomainName -ParentDomainName $ParentDomainName
    if ($domainFQDN -ne $targetResource.DomainName)
    {
        $message = $localizedData.ResourcePropertyValueIncorrect -f 'DomainName', $domainFQDN, $targetResource.DomainName
        Write-Verbose -Message $message
        $isCompliant = $false   
    }
    
    $propertyNames = @('ParentDomainName', 'DomainNetBIOSName')
    foreach ($propertyName in $propertyNames)
    {
        if ($PSBoundParameters.ContainsKey($propertyName))
        {
            $propertyValue = (Get-Variable -Name $propertyName).Value
            if ($targetResource.$propertyName -ne $propertyValue)
            {
                $message = $localizedData.ResourcePropertyValueIncorrect -f $propertyName, $propertyValue, $targetResource.$propertyName
                Write-Verbose -Message $message
                $isCompliant = $false        
            }
        }
    }
        
    if ($isCompliant)
    {
        Write-Verbose -Message ($localizedData.ResourceInDesiredState -f $domainFQDN)
        return $true
    }
    else
    {
        Write-Verbose -Message ($localizedData.ResourceNotInDesiredState -f $domainFQDN)
        return $false
    }
} #end function Test-TargetResource

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VaultAddress,

        [System.String]
        $ApiPrefix = 'v1',
    
        [Parameter(Mandatory)]
        [System.String] $DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorUsername,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorVaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $SafemodeAdministratorPasswordVaultPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $ParentDomainName,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $DomainNetBIOSName,

        [System.String]
        $DnsDelegationUserName,

        [System.String]
        $DnsDelegationVaultPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $DatabasePath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $LogPath,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [System.String] $SysvolPath,

        [System.String]
        $AuthBackend = 'approle'
    )

    # Debug can pause Install-ADDSForest/Install-ADDSDomain, so we remove it.
    [ref] $null = $PSBoundParameters.Remove('Debug')
    ## Not entirely necessary, but run Get-TargetResouece to ensure we raise any pre-flight errors.
    $targetResource = Get-TargetResource @PSBoundParameters

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $SafemodeAdministratorPasswordVaultPath
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $SafemodeAdministratorPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('SafeModePlaceHolderUser', $VaultValue)
    
    $installADDSParams = @{
        SafeModeAdministratorPassword = $SafemodeAdministratorPassword.Password
        NoRebootOnCompletion          = $true
        Force                         = $true
    }
    
    if ($PSBoundParameters.ContainsKey('DnsDelegationVaultPath'))
    {
        $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $SafemodeAdministratorPasswordVaultPath
        $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
        $DnsDelegationCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DnsDelegationUserName, $VaultValue)
        $installADDSParams['DnsDelegationCredential'] = $DnsDelegationCredential
        $installADDSParams['CreateDnsDelegation'] = $true
    }
    if ($PSBoundParameters.ContainsKey('DatabasePath'))
    {
        $installADDSParams['DatabasePath'] = $DatabasePath
    }
    if ($PSBoundParameters.ContainsKey('LogPath'))
    {
        $installADDSParams['LogPath'] = $LogPath
    }
    if ($PSBoundParameters.ContainsKey('SysvolPath'))
    {
        $installADDSParams['SysvolPath'] = $SysvolPath
    }
    
    if ($PSBoundParameters.ContainsKey('ParentDomainName'))
    {
        $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorUsername
        $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
        $DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DomainAdministratorUsername, $VaultValue)    
        Write-Verbose -Message ($localizedData.CreatingChildDomain -f $DomainName, $ParentDomainName)
        $installADDSParams['Credential'] = $DomainAdministratorCredential
        $installADDSParams['NewDomainName'] = $DomainName
        $installADDSParams['ParentDomainName'] = $ParentDomainName
        $installADDSParams['DomainType'] = 'ChildDomain'
        if ($PSBoundParameters.ContainsKey('DomainNetBIOSName'))
        {
            $installADDSParams['NewDomainNetbiosName'] = $DomainNetBIOSName
        }
        Install-ADDSDomain @installADDSParams
        Write-Verbose -Message ($localizedData.CreatedChildDomain)
    }
    else
    {
        Write-Verbose -Message ($localizedData.CreatingForest -f $DomainName)
        $installADDSParams['DomainName'] = $DomainName
        if ($PSBoundParameters.ContainsKey('DomainNetbiosName'))
        {
            $installADDSParams['DomainNetbiosName'] = $DomainNetBIOSName
        }
        Install-ADDSForest @installADDSParams
        Write-Verbose -Message ($localizedData.CreatedForest -f $DomainName) 
    }  

    'Finished' | Out-File -FilePath (Get-TrackingFilename -DomainName $DomainName) -Force

    # Signal to the LCM to reboot the node to compensate for the one we
    # suppressed from Install-ADDSForest/Install-ADDSDomain
    $global:DSCMachineStatus = 1
} #end function Set-TargetResource

## Import the common AD functions
$adCommonFunctions = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath '\MSFT_xADCommon\MSFT_xADCommon.ps1'
. $adCommonFunctions

Export-ModuleMember -Function *-TargetResource