Function Remove-COOPs {
	<#
.SYNOPSIS
Removes "Create-COOPs" VM
.DESCRIPTION
Removes VM's which have been created by the "Create-COOPs" function
.EXAMPLE
Remove-COOPs 
.EXAMPLE
Give another example of how to use it
.PARAMETER COOPedServers
The computer name to query. Just one.
.PARAMETER logname
The name of a file to write failed computer names to. Defaults to errors.txt.
#>

	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='high')]
	param
	(
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='What VM(s)  would you like to target?')]
		[Alias('COOPedVMs')]
		[ValidateLength(3,30)]
		[string[]]$COOPedServers,

		[string]$logname = 'errors.txt'
	)

	begin {
		write-verbose "Deleting $logname"
		del $logname -ErrorActionSilentlyContinue
	}

	process {

		If ($OkRemove -eq 'Y'){
			#Remove older COOP's from the list you created in the early part of the script.
			write-verbose "Beginning process loop"
			foreach ($VMachine in $COOPedServers) {
				Write-Verbose "Processing $VMachine"
				if ($pscmdlet.ShouldProcess($VMachine)) {

					Write-Verbose "Checking to ensure $VMachine is Powered Off."
					If (($VMachine.PowerState -eq 'PoweredOff') -and ($VMachine.Name -match 'COOP')){
						Write-Verbose "Removing $VMachine." 
						#Write-Host "Remove-VM $VMachine -DeletePermanently -confirm:$true "
						Remove-VM $VMachine -DeletePermanently -confirm:$true -runasync 

					}
				}
			}

		}
	}
}
# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9JKdHGZqP10GJVicwzCnT8P4
# JG2gggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
# MBYxFDASBgNVBAMTC0VyaWtBcm5lc2VuMB4XDTE3MTIyOTA1MDU1NVoXDTM5MTIz
# MTIzNTk1OVowFjEUMBIGA1UEAxMLRXJpa0FybmVzZW4wgZ8wDQYJKoZIhvcNAQEB
# BQADgY0AMIGJAoGBAKYEBA0nxXibNWtrLb8GZ/mDFF6I7tG4am2hs2Z7NHYcJPwY
# CxCw5v9xTbCiiVcPvpBl7Vr4I2eR/ZF5GN88XzJNAeELbJHJdfcCvhgNLK/F4DFp
# kvf2qUb6l/ayLvpBBg6lcFskhKG1vbEz+uNrg4se8pxecJ24Ln3IrxfR2o+BAgMB
# AAGjYDBeMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEcGA1UdAQRAMD6AEMry1NzZravR
# UsYVhyFVVoyhGDAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlboIQyWSKL3Rtw7JMh5kR
# I2JlijAJBgUrDgMCHQUAA4GBAF9beeNarhSMJBRL5idYsFZCvMNeLpr3n9fjauAC
# CDB6C+V3PQOvHXXxUqYmzZpkOPpu38TCZvBuBUchvqKRmhKARANLQt0gKBo8nf4b
# OXpOjdXnLeI2t8SSFRltmhw8TiZEpZR1lCq9123A3LDFN94g7I7DYxY1Kp5FCBds
# fJ/uMYIBSjCCAUYCAQEwKjAWMRQwEgYDVQQDEwtFcmlrQXJuZXNlbgIQyWSKL3Rt
# w7JMh5kRI2JlijAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUVr0JYtBCbrzaLq1iQk1b2LGL02cw
# DQYJKoZIhvcNAQEBBQAEgYBAiwGztlImzv/cMH90nLyLqypAn689R7KrHg6WVR14
# Tt1v/MQ/LI73xKc4JBItSD8evuwVeG4J2lIklA1VaXQ+Q41xcsjkUAT1usrf+128
# /LUBqBD4U5OPy0HCPa4UKhHxi9Tbnz+qAuzgk9polTojWld5bHUS58FRymrtM8di
# tA==
# SIG # End signature block
