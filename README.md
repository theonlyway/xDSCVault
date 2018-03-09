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
- xDSCVault_WaitForADDomain
	- Based on the WaitForADDomain module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xwaitforaddomain)
- xDSCVault_ADDomainController
	- Based on the ADDomainController module from [xActiveDirectory](https://github.com/PowerShell/xActiveDirectory#xaddomaincontroller)

## In-progress modules

## Planned

List of processes that I want to get working

- AD users
- Service accounts
- SQL clusters
- Octopus Deploy step template

## Resources

### VaultUnwrap
* **VaultAddress**: URL to the Vault
  * _Required_
* **RoleID**: RoleID for the AppRole
  * _Required_
* **WrappedToken**: Wrapped token for the AppRole
  * _Required_
```powershell
VaultUnwrap Unwrap
{
  RoleId = randomroleID
  WrappedToken = dee09a64-429b-619c-0466-9c108320105e
  VaultAddress = https://pathtovaultserver.com   
} 
```
    
### VaultWrite
* **VaultAddress**: URL to the Vault
  * _Required_
* **VaultPath**: Path to where the credential will be written to in the Vault
  * _Required_
* **VaultValue**: Specify the value to be written
  * _Optional but either a value must be specified or random secret must be $true_
* **RandomSecret**: Generate a random secret
  * _Optional but either a value must be specified or random secret must be $true_
* **ForceUpdate**: Everytime the module runs it will write the value to Vault
  * _Required $true or $false_
```powershell
VaultWrite LocalAdministratorPassword
{
  VaultAddress = https://pathtovaultserver.com       
  VaultPath = "secret/path/somevalue-administrator"
  RandomSecret = $true
  ForceUpdate = $false
} 
```
### VaultLocalUser
* **VaultAddress**: URL to the Vault
* **[String] UserName** _(Key)_: Indicates the account name for which you want to ensure a specific state.
* **[String] Description** _(Write)_: Indicates the description you want to use for the user account.
* **[Boolean] Disabled** _(Write)_: Indicates if the account is disabled. Set this property to true to ensure that this account is disabled, and set it to false to ensure that it is enabled. The default value is false.
* **[String] Ensure** _(Write)_: Ensures that the feature is present or absent { *Present* | Absent }.
* **[String] FullName** _(Write)_: Represents a string with the full name you want to use for the user account.
* **[PSCredential] Password** _(Write)_: Indicates the password you want to use for this account.
* **[Boolean] PasswordChangeNotAllowed** _(Write)_: Indicates if the user can change the password. Set this property to true to ensure that the user cannot change the password, and set it to false to allow the user to change the password. The default value is false.
* **[Boolean] PasswordChangeRequired** _(Write)_: Indicates if the user must change the password at the next sign in. Set this property to true if the user must change their password. The default value is true.
* **[Boolean] PasswordNeverExpires** _(Write)_: Indicates if the password will expire. To ensure that the password for this account will never expire, set this property to true. The default value is false.
```powershell
VaultLocalUser LocalAdministratorPassword
{
  VaultAddress = https://pathtovaultserver.com       
  VaultPath = "secret/path/somevalue-administrator"
  Username = 'Administrator'
  PasswordNeverExpires = $true
  Ensure = 'Present'
}   
```
### VaultADDomain
* **VaultAddress**: URL to the Vault
  * _Required_
* **DomainName**: Name of the domain.
  * If no parent name is specified, this is the fully qualified domain name for the first domain in the forest.
  * _Required_
* **ParentDomainName**: Fully qualified name of the parent domain
  * _Optional_
* **DomainAdministratorUsername**: Credentials used to query for domain existence.
  * _Note: These are NOT used during domain creation._
  * _Required_
* **DomainAdministratorVaultPath**: Path to where the credential is located in the Vault
  * _Note: These are NOT used during domain creation._
  * _Required_
* **SafemodeAdministratorPasswordVaultPath**: Password for the administrator account when the computer is started in Safe Mode.
* **DnsDelegationCredential**: Credential used for creating DNS delegation (optional).
* **DomainNetBIOSName**: Specifies the NetBIOS name for the new domain (optional).
  * If not specified, then the default is automatically computed from the value of the DomainName parameter.
* **DatabasePath**: Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database (optional).
* **LogPath**: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written (optional).
* **SysvolPath**: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written. (optional)

```powershell
VaultADDomain FirstDS
{
    VaultAddress = https://pathtovaultserver.com
    DomainName = contoso.local
    SafemodeAdministratorPasswordVaultPath = "secret/path/somevalue-domainsafemode"
    DomainAdministratorUsername = 'Administrator'
    DomainAdministratorVaultPath = "secret/path/somevalue-administrator"
}
```
### VaultWaitForADDomain
* **VaultAddress**: URL to the Vault
  * _Required_
* **DomainName**: Name of the domain.
  * _Required_
* **DomainUserUsername**: Credentials used to query for domain existence.
  * _Optional_
* **DomainUserVaultPath**: Path to where the credential is located in the Vault
  * _Optional_
* **RetryIntervalSec**: Interval to check for the domain's existence.
* **RetryCount**: Maximum number of retries to check for the domain's existence.

```powershell
VaultWaitForADDomain DscForestWait
{
  VaultAddress = https://pathtovaultserver.com       
  DomainName = contoso.local
  DomainUserUsername = 'Administrator'
  DomainUserVaultPath = "secret/path/somevalue-administrator"
  RetryCount = 50
  RetryIntervalSec = 30
}
```
### VaultADDomainController
* **DomainName**: The fully qualified domain name for the domain where the domain controller will be present.
* **DomainAdministratorCredential**: Specifies the credential for the account used to install the domain controller.
* **SafemodeAdministratorPassword**: Password for the administrator account when the computer is started in Safe Mode.
* **DatabasePath**: Specifies the fully qualified, non-Universal Naming Convention (UNC) path to a directory on a fixed disk of the local computer that contains the domain database (optional).
* **LogPath**: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the log file for this operation will be written (optional).
* **SysvolPath**: Specifies the fully qualified, non-UNC path to a directory on a fixed disk of the local computer where the Sysvol file will be written. (optional)
* **SiteName**: Specify the name of an existing site where new domain controller will be placed. (optional)
```powershell
VaultADDomainController SecondDC
{
  VaultAddress = https://pathtovaultserver.com       
  DomainName = contoso.local
  DomainAdministratorUsername = 'Administrator'
  DomainAdministratorVaultPath = "secret/path/somevalue-administrator"
  SafemodeAdministratorPasswordVaultPath = "secret/path/somevalue-domainsafemode"
}
```