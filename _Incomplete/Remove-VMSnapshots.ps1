Function Remove-VMSnapshots {
	<#
.SYNOPSIS
Removes "Add-VMSnapshots"
.DESCRIPTION
Removes VM's which have been created by the "Add-VMSnapshots" function
.EXAMPLE
Remove-VMSnapshots 
.EXAMPLE
Remove-VMSnapshots -all
Removes all of the snapshots on vcenter that don't have "Do Not Delete"
.EXAMPLE
Remove-VMSnapshots -author "initials"
.PARAMETER VMServer
The computer name to query. Just one.
.PARAMETER author
The initials of the originator of the Snapshot
.PARAMETER logname
The name of a file to write failed computer names to. Defaults to errors.txt.
#>

	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='high')]
	param
	(
		[Parameter(Mandatory=$False,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='What VM(s) would you like to target?')]
		[ValidateLength(3,30)]
		[string[]]$VMServers,

		[Parameter(Mandatory=$False,
			HelpMessage='Enter the initials of the author or person who made the snapshots')]
		#[switch]$author = $false,
		[string]$author = $(if ($author){Read-Host -Prompt "Enter the initials of person who made the snapshots"}),

		[Parameter(Mandatory=$False,
			HelpMessage="All snapshots except with descriptions 'Do Not Delete'")]
		[switch]$all = $false,

		[string]$logname = 'errors.txt'
	)

	begin {
		if(Test-path $logname){ 
			write-verbose "Deleting $logname"
			Remove-Item $logname -ErrorAction Continue
		}
	}

	process {

		if($all){Write-Host "All"}
		if($author){Write-Host "Author $author"}
		<#
        $VMSnapshots = Get-VM | Get-Snapshot

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

        }#>
	}
}

# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaGGlWUzgHqB6Oi6stdNWGXzi
# cVOgggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUdQV83JSmOGREjUnW6FC/e4BmWSgw
# DQYJKoZIhvcNAQEBBQAEgYBJAN0d9LRJKjMfm/0i/M1dIOjIl3fa8Qp/n+rgIpRk
# 0GaKldigRoieHyhgH+HSCX9mmHAFKk0DLtPNr57NtYXt+kI0gqMgajC4Y1AtRxDA
# tlFJ8HMmTsCQAFJ6bnx7NXEaVfLqhrjqGqaASYmIejr0hb2pwZWl6wuyx57elZRN
# GQ==
# SIG # End signature block
