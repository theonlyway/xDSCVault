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

I'll doco the resources with the parameters when I get a chance
