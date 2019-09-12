Function Remove-COOPs 
{
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

	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='high')]
	param
	(
		[Parameter(Mandatory=$True,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='What VM  would you like to target?')]
		[Alias('vm')]
		[ValidateLength(3,30)]
		[string[]]$computername,

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
			if ($pscmdlet.ShouldProcess($computer)) {
				# use $computer here
			}
		}
	}
	if ($MainMenuChoice -eq '2'){Clear-Host}

	#Get List of all VM's with "COOP" in the name. This will be used as the list of COOP's that will be deleted.
	$VMServers = get-vm | Where-Object {$_.Name -match 'COOP'}
	$VMServers | Format-Table Name

	#Enter the date of the COOP vms that you want to remove.  From the printout of the list above, you will be able to select the unwanted dates.
	$COOPdate = Read-Host 'Enter the date of the COOP you want to remove (YYYYMMDD) '

	#Get List of the VM Clones you want to Remove.  This is similar to the first step, but uses the specific date you gave to search on.  This will be your list of systems to remove.
	$PoweredOffClones = $VMPoweredOff | Where-Object -FilterScript {$_.Name -like "$COOPdate*"} #| ft Name, ResourcePool  -AutoSize

	#Set "$OkRemove" to "N" 
	$OkRemove = 'N'
	$OkRemove = Read-host "Preparing to remove ALL COOP'ed vm servers below. $PoweredOffClones`nIs this Okay? [N] "

	If ($OkRemove -eq 'Y'){
		#Remove older COOP's from the list you created in the early part of the script.
		foreach ($VMz in $PoweredOffClones) {
			Write-Host -sep `n "Checking to ensure $VMz is Powered Off." #-foregroundcolor Red
			If (($VMz.PowerState -eq 'PoweredOff') -and ($VMz.Name -match 'COOP')){
				Write-Host -sep `n $VMz 'is in a Powered Off state and will be removed. ' -foregroundcolor Blue 
				#Write-Host "Remove-VM $VMz -DeletePermanently -confirm:$true "
				Remove-VM $VMz -DeletePermanently -confirm:$true -runasync 

			}}}
}
}
