# PScred

PScred is a simple password manager built in powershell. 
The passwords are stored ecrypted using PowerShell's ConvertTo-SecureString cmdlet 
and can only be decrypted by the same computer and user account that encrypted them.

You can use pscred to pass password to scripts
ex: $Credential = Get-Pass -Name mypass  | Get-Clipboard

If you want to move passwords to a different system you can you the Export-Pass on the source system (8 digit PIN required)
and then run Import-Pass on the target system to encrypt the secrets again with the session account. 

## Usage
```powershell
Set-Pass
# Set-Pass Saves a new password. Optionally a description can be added 

Get-Pass
# Get-Pass Gets the value of a stored password and places it on the clipboard 

Get-Passlist
# Get-PassList gets a list of all stored passwords

Remove-Pass
# Remove-Pass removes a stored password

Export-Pass
# Export-Pass creates a folder with all passwords (encrypted hashes) that can be imported on a different system.
# An 8 digit PIN will be requested and the same PIN will be needed to import the passwords to the new system

Import-Pass
# Import-Pass imports the passwords exported from a different system 
# An 8 digit PIN will be requested (this is the same PIN used when running the Export-Pass command on the source system)
