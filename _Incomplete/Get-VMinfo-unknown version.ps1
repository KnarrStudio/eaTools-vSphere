function Get-VMinfo {
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$False,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='What host name would you like to target?')]
    [Alias('host')]
    [ValidateLength(3,30)]
    [string[]]$VHost,
	
	[Parameter (Mandatory=$False,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
      HelpMessage='What VMs name would you like to target?')]
    [Alias('VM')]
    [ValidateLength(3,30)]
    [string[]]$VMachine,
		
    [string]$logname = 'errors.txt'
  )

  begin {
  write-verbose "Deleting $logname"
    del $logname -ErrorActionSilentlyContinue
  }

  process {

    write-verbose "Beginning process loop"

    foreach ($computer in $computername) {
      Write-Verbose "Processing $computer"
      # use $computer to target a single computer
	

      # create a hashtable with your output info
      $info = @{
        'info1'=$value1;
        'info2'=$value2;
        'info3'=$value3;
        'info4'=$value4
      }
      Write-Output (New-Object –TypenamePSObject –Prop $info)
	  
	  
	  
    }
  }
}

<#
function Get-VirtualMachines
{
 param
(
	[Object]
	[Parameter(Mandatory=$true, ValueFromPipeline=$true, HelpMessage="Data to filter")]
	$InputObject
)
process
{
	<#$Script:VMpoweredON = get-vm | Where-Object {$_.PowerState -eq 'PoweredOn'} # All powered ON VMs
    $Script:VMPoweredOff = get-vm | Where-Object {$_.PowerState -eq 'PoweredOff'} # All powered OFF VMs
    $Script:VMtags = get-tags # Tags on vcenter
    $Script:VMsnapshots = get-snap # All Snapshots
#> 

	if ($InputObject -eq 'PoweredOn')
	{
		$InputObject
	}
}
}



Function Get-VMinformation {
	# User settings
	$Script:VMHostIP = '214.54.192.18'
	$Script:WhatIfPreference = $true #This is a safety measure that I am working on.  My scripts will have a safety mode, or punch the monkey to actually execute.  You can thank Phil West for this idea, when he removed all of the printers on the print server when he double-clicked on a vbs script.
	$Script:MainMenuChoice = 0 # Sets main menu choice
	$null = '.\COOP-serverlist.csv' # The list of servers 
	$null = Get-Datastore | Where-Object {$_.name -like 'LOCALdatastore18'}


	# Script Variables
	$Script:HostsAll = get-vmhost # All hosts controlled by vcenter
	$Script:HostsLocal = get-vmhost | Where-Object {$_.Site -eq 'Norfolk' } # All hosts in current site
	$Script:VMpoweredON = get-vm | Where-Object {$_.PowerState -eq 'PoweredOn'} # All powered ON VMs
	$Script:VMPoweredOff = get-vm | Where-Object {$_.PowerState -eq 'PoweredOff'} # All powered OFF VMs
	$Script:VMtags = get-tags # Tags on vcenter
	$Script:VMsnapshots = get-snap # All Snapshots

	$Script:local = Get-Location

	Set-Location .\ 

}

Function Info-COOPs-Snaps {

	$PoweredOffVM = get-vm | Where-Object {($_.PowerState -eq 'PoweredOff') -and ($_.Name -notmatch 'COOP')}# | Format-Table -AutoSize
	$COOPSinuse = get-vm | Where-Object {($_.PowerState -eq 'PoweredOn') -and ($_.Name -match 'COOP')}
	$Snapshotinfo = get-vm | get-snapshot 


#>



# SIG # Begin signature block
# MIID7QYJKoZIhvcNAQcCoIID3jCCA9oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8jompWmCIAqCFq33STo5QW4L
# fVigggINMIICCTCCAXagAwIBAgIQyWSKL3Rtw7JMh5kRI2JlijAJBgUrDgMCHQUA
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
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU+i8q6oP6ZD3T2OC4UlRwKvvCE1sw
# DQYJKoZIhvcNAQEBBQAEgYBG4P7wx7DpxqSq9ap+8164gTCznP9QhqMdCDwV5Mha
# G2vvBpu4J9o4uOnfHjb+iFFiEwx4jCMCsPHVxlwJjKszTEvr0jiBNZhH5NNYVIsd
# 49EIWohvGnCcJ2fUZdPtAnn7Si5qzHFPikzQG53RPt+/qyqFPpfkGauorYRcbj5+
# 5Q==
# SIG # End signature block
