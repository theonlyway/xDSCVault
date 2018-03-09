# xDSCVault #
## Overview ##

Pretty much every DSC module is designed to store credentials in the MOF and if configured in such a way you can configure it to encrypt those credentials. However, for my current environment we don't want any credentials stored in the DSC configuration MOFs.

To do this we are using a combination of Hasicorp's Terraform & Vault products to provision infrastructure. Each peice of infrastructure that requires access to secrets is provisioned with a unique Vault AppRole, policy and wrapped token.

Since the majority of the Microsoft based DSC modules are about 90% fit for purpose with the exception of the credential part basically all I am doing is taking this modules and rewriting them to get the secret from the Vault API then create the credentail object during processing instead of having them expect the credentials be present in the MOF

## Current modules

- xDSCVault_Download
	- Downloads a copy of the vault binary if for some reason you can't use the API to access the Vault endpoint
- xDSCVault_Unwrap
	- Checks to see if a wrapped token is still wrapped and if it is it will unwrap it and stores the AppRole and RoleID in the local Windows Credential Manager
	- All the subsequent modules are designed to obtain the credentials from the location this module saves them
- xDSCVault_Write
	- Writes secrets to the vault endpoint
- xDSCVault_LocalUser
	- Based on the local user module from [PSDSCResources](https://github.com/PowerShell/PSDscResources#user)
- xDSCVault_ADDomain
	- Based on the ADDomain module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xaddomain)

## In-progress modules

- xDSCVault_WaitForADDomain
	- Based on the WaitForADDomain module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xwaitforaddomain)
- xDSCVault_ADDomainController
	- Based on the ADDomainController module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xaddomaincontroller)

## Planned

List of processes that I want to get working

- AD users
- Service accounts
- SQL clusters
- Octopus Deploy step template

## Resources

### VaultUnwrap

    VaultUnwrap Unwrap
    {
      RoleId = randomroleID
      WrappedToken = dee09a64-429b-619c-0466-9c108320105e
      VaultAddress = https://pathtovaultserver.com   
    } 
    
### VaultWrite

    VaultWrite LocalAdministratorPassword
    {
      VaultAddress = https://pathtovaultserver.com       
      VaultPath = "secret/path/somevalue-administrator"
      RandomSecret = $true
      ForceUpdate = $false
    } 

### VaultLocalUser

    VaultLocalUser LocalAdministratorPassword
    {
      VaultAddress = https://pathtovaultserver.com       
      VaultPath = "secret/path/somevalue-administrator"
      Username = 'Administrator'
      PasswordNeverExpires = $true
      Ensure = 'Present'
    }   

### VaultADDomain

* **DomainName**: Name of the domain.
  * If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
* **ParentDomainName**: Fully qualified name of the parent domain (optional).
* **DomainAdministratorCredential**: Credentials used to query for domain existence.
  * _Note: These are NOT used during domain creation._

```powershell
VaultADDomain FirstDS
{
    VaultAddress = https://pathtovaultserver.com
    DomainName = $domainName
    SafemodeAdministratorPasswordVaultPath = "secret/path/somevalue-domainsafemode"
    DomainAdministratorUsername = 'Administrator'
    DomainAdministratorVaultPath = "secret/path/somevalue-administrator"
}
```
### VaultWaitForADDomain

* **DomainName**: Name of the remote domain.
* **RetryIntervalSec**: Interval to check for the domain's existence.
* **RetryCount**: Maximum number of retries to check for the domain's existence.

```powershell
    VaultWaitForADDomain DscForestWait
    {
      VaultAddress = https://pathtovaultserver.com       
      DomainName = $domainName
      DomainUserUsername = 'Administrator'
      DomainUserVaultPath = "secret/path/somevalue-administrator"
      RetryCount = 50
      RetryIntervalSec = 30
    }
```
### VaultADDomainController

    VaultADDomainController SecondDC
    {
      VaultAddress = https://pathtovaultserver.com       
      DomainName = $domainName
      DomainAdministratorUsername = 'Administrator'
      DomainAdministratorVaultPath = "secret/path/somevalue-administrator"
      SafemodeAdministratorPasswordVaultPath = "secret/path/somevalue-domainsafemode"
    }