#
# xADDomainController: DSC resource to install a domain controller in Active
# Directory.
#
# User name and password needed for this resource and Write-Verbose Used in helper functions
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

$errorActionPreference = 'Stop'

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')
        
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
        [String]$DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorUsername,
    
        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorVaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $SafemodeAdministratorPasswordVaultPath,

        [String]$DatabasePath,

        [String]$LogPath,

        [String]$SysvolPath,

        [String]$SiteName,

        [System.String]
        $AuthBackend = 'approle'
    )

    $returnValue = @{
        DomainName = $DomainName
        Ensure     = $false
    }

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorVaultPath -ApiPrefix $ApiPrefix
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)

    try
    {
        Write-Verbose -Message "Resolving '$($DomainName)' ..."
        $domain = Get-ADDomain -Identity $DomainName -Credential $DomainAdministratorCredential
        if ($domain -ne $null)
        {
            Write-Verbose -Message "Domain '$($DomainName)' is present. Looking for DCs ..."
            try
            {
                $dc = Get-ADDomainController -Identity $env:COMPUTERNAME -Credential $DomainAdministratorCredential
                Write-Verbose -Message "Found domain controller '$($dc.Name)' in domain '$($dc.Domain)'."
                if ($dc.Domain -eq $DomainName)
                {
                    Write-Verbose -Message "Current node '$($dc.Name)' is already a domain controller for domain '$($dc.Domain)'."

                    $serviceNTDS = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters'
                    $serviceNETLOGON = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'

                    $returnValue.Ensure = $true
                    $returnValue.DatabasePath = $serviceNTDS.'DSA Working Directory'
                    $returnValue.LogPath = $serviceNTDS.'Database log files path'
                    $returnValue.SysvolPath = $serviceNETLOGON.SysVol -replace '\\sysvol$', ''
                    $returnValue.SiteName = $dc.Site
                }
            }
            catch
            {
                if ($error[0]) 
                {
                    Write-Verbose -Message $error[0].Exception
                }
                Write-Verbose -Message 'Current node does not host a domain controller.'
            }
        }
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        if ($error[0]) 
        {
            Write-Verbose -Message $error[0].Exception
        }
        Write-Verbose -Message 'Current node is not running AD WS, and hence is not a domain controller.'
    }
    $returnValue
}

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
        [String]$DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorUsername,
    
        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorVaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $SafemodeAdministratorPasswordVaultPath,

        [String]$DatabasePath,

        [String]$LogPath,

        [String]$SysvolPath,

        [String]$SiteName,

        [System.String]
        $AuthBackend = 'approle'
    )

    # Debug can pause Install-ADDSDomainController, so we remove it.
    $parameters = $PSBoundParameters.Remove('Debug')
    $targetResource = Get-TargetResource @PSBoundParameters

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorVaultPath -ApiPrefix $ApiPrefix
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $SafemodeAdministratorPasswordVaultPath -ApiPrefix $ApiPrefix
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $SafemodeAdministratorPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('SafeModePlaceHolderUser', $VaultValue)

    if ($targetResource.Ensure -eq $false)
    {
        ## Node is not a domain controllr so we promote it
        Write-Verbose -Message "Checking if domain '$($DomainName)' is present ..."
        $domain = $null
        try
        {
            $domain = Get-ADDomain -Identity $DomainName -Credential $DomainAdministratorCredential
        }
        catch
        {
            if ($error[0]) 
            {
                Write-Verbose $error[0].Exception
            }
            throw (New-Object -TypeName System.InvalidOperationException -ArgumentList "Domain '$($DomainName)' could not be found.")
        }

        Write-Verbose -Message "Verified that domain '$($DomainName)' is present, continuing ..."
        $params = @{
            DomainName                    = $DomainName
            SafeModeAdministratorPassword = $SafemodeAdministratorPassword.Password
            Credential                    = $DomainAdministratorCredential
            NoRebootOnCompletion          = $true
            Force                         = $true
        }
        if ($DatabasePath -ne $null)
        {
            $params.Add('DatabasePath', $DatabasePath)
        }
        if ($LogPath -ne $null)
        {
            $params.Add('LogPath', $LogPath)
        }
        if ($SysvolPath -ne $null)
        {
            $params.Add('SysvolPath', $SysvolPath)
        }
        if ($SiteName -ne $null -and $SiteName -ne '')
        {
            $params.Add('SiteName', $SiteName)
        }

        Install-ADDSDomainController @params
        Write-Verbose -Message "Node is now a domain controller for '$($DomainName)'."

        # Signal to the LCM to reboot the node to compensate for the one we
        # suppressed from Install-ADDSDomainController
        $global:DSCMachineStatus = 1
    }
    elseif ($targetResource.Ensure)
    {
        ## Node is a domain controller. We check if other properties are in desired state
        if ($PSBoundParameters['SiteName'] -and $targetResource.SiteName -ne $SiteName)
        {
            ## DC is not in correct site. Move it.
            Write-Verbose "Moving Domain Controller from '$($targetResource.SiteName)' to '$SiteName'"
            Move-ADDirectoryServer -Identity $env:COMPUTERNAME -Site $SiteName -Credential $DomainAdministratorCredential
        }
    }
}

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
        [String]$DomainName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorUsername,
    
        [parameter(Mandatory = $true)]
        [System.String]
        $DomainAdministratorVaultPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $SafemodeAdministratorPasswordVaultPath,

        [String]$DatabasePath,

        [String]$LogPath,

        [String]$SysvolPath,

        [String]$SiteName,

        [System.String]
        $AuthBackend = 'approle'
    )

    $clientToken = Start-VaultAuth -VaultAddress $VaultAddress -ApiPrefix $ApiPrefix -AuthBackend $AuthBackend
    $currentVaultValue = Read-VaultData -VaultAddress $VaultAddress -ClientToken $clientToken.auth.client_token -VaultPath $DomainAdministratorVaultPath -ApiPrefix $ApiPrefix
    $VaultValue = ConvertTo-SecureString -String $currentVaultValue.data.value -AsPlainText -Force
    $DomainAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList (("$DomainName" + '\' + "$DomainAdministratorUsername"), $VaultValue)

    if ($PSBoundParameters.SiteName)
    {
        if (-not (Test-ADReplicationSite -SiteName $SiteName -DomainName $DomainName -Credential $DomainAdministratorCredential))
        {
            throw (New-Object -TypeName System.InvalidOperationException -ArgumentList "Site '$($SiteName)' could not be found.")
        }
    }

    $isCompliant = $true

    try
    {
        $parameters = $PSBoundParameters.Remove('Debug')

        $existingResource = Get-TargetResource @PSBoundParameters
        $isCompliant = $existingResource.Ensure

        if ([System.String]::IsNullOrEmpty($SiteName))
        {
            #If SiteName is not specified confgiuration is compliant
        }
        elseif ($existingResource.SiteName -ne $SiteName)
        {
            Write-Verbose "Domain Controller Site is not in a desired state. Expected '$SiteName', actual '$($existingResource.SiteName)'"
            $isCompliant = $false
        }
    }
    catch
    {
        if ($error[0]) 
        {
            Write-Verbose $error[0].Exception
        }
        Write-Verbose -Message "Domain '$($DomainName)' is NOT present on the current node."
        $isCompliant = $false
    }

    $isCompliant
}

## Import the common AD functions
$adCommonFunctions = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath '\MSFT_xADCommon\MSFT_xADCommon.ps1'
. $adCommonFunctions

Export-ModuleMember -Function *-TargetResource
