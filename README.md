# PScred
https://www.powershellgallery.com/packages/pscred

PScred is a simple password manager built in PowerShell. 
The passwords are stored ecrypted using PowerShell's ConvertTo-SecureString cmdlet 
and can only be decrypted by the same computer and user account that encrypted them.

Install PScred directly from the Powershell Gallery 

```powershell
Install-Module -Name pscred 
```

You can use pscred to store a password that you create (you will be promted for the password)
ex: 
```powershell
Set-Pass -Name mypass -Description "My secret"  
```

You can also store a randomly generated password
ex: 
```powershell
Set-RandomPass -Name mypass -Description "My secret" -Length "12"  
```

Then use pscred to get a saved password and place it on the clipboard
ex: 
```powershell
Get-Pass -Name mypass  
```

Or you can use pscred to pass password to scripts
ex: 
```powershell
$Credential = Get-Pass -Name mypass  | Get-Clipboard
```
If you want to move passwords to a different system you can run Export-Pass on the source system (8 digit PIN will be requested)
and then run Import-Pass on the target system to encrypt the secrets again with the session account. 

## Usage
```powershell
Set-Pass
# Set-Pass Saves a new password. Optionally a description can be added 
# ex: Set-Pass -Name <Name> -Description <Description>

Set-RandomPass
# Set-RandomPass Saves a new randomly generated password (special characters included). Optionally a description can be added 
# ex: Set-RandomPass -Name <Name> -Description <Description> -Length <Password Length>

Get-Pass
# Get-Pass Gets the value of a stored password and places it on the clipboard 
# ex: Get-Pass -Name <Name>

Get-Passlist
# Get-PassList gets a list of all stored passwords
# ex: Get-PassList

Remove-Pass
# Remove-Pass removes a stored password
# ex: Remove-Pass -Name <Name>

Export-Pass
# Export-Pass creates a folder with all passwords (encrypted hashes) that can be imported on a different system.
# An 8 digit PIN will be requested and the same PIN will be needed to import the passwords to the new system
# ex: Export-Pass

Import-Pass
# Import-Pass imports the passwords exported from a different system 
# An 8 digit PIN will be requested (this is the same PIN used when running the Export-Pass command on the source system)
# ex: Import-Pass
