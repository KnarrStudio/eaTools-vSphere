function Remove-COOPservers
{
  <#
    .SYNOPSIS
    Short Description
    .DESCRIPTION
    Detailed Description
    .EXAMPLE
    Remove-COOPservers
    explains how to use the command
    can be multiple lines
    .EXAMPLE
    Remove-COOPservers
    another example
    can have as many examples as you like
  #>
  if ($COOPprocess -eq "2"){Clear-Host}
  
  #Get List of all VM's with "COOP" in the name. This will be used as the list of COOP's that will be deleted.
  $VMServers  = get-vm | where {$_.Name -like "*COOP*"}
  get-vm | where {$_.Name -like "*COOP*"} | Format-Table Name
  
  #Enter the date of the COOP vms that you want to remove.  From the printout of the list above, you will be able to select the unwanted dates.
  $COOPdate = Read-Host "Enter the date of the COOP you want to remove (YYYYMMDD) "
  
  #Get List of the VM Clones you want to Remove.  This is similar to the first step, but uses the specific date you gave to search on.  This will be your list of systems to remove.
  $VMSvr = $VMServers | where {($_.Name -like "$COOPdate*") -and ($_.PowerState -eq "PoweredOff")} #| ft Name, ResourcePool  -AutoSize
  
  Write-Host -sep `n "Preparing to remove ALL COOP'ed vm servers below." $VMSvr -foreground Red
  
  #Set "$OkRemove" to "N" 
  $OkRemove = "N"
  $OkRemove = Read-host "Is this Okay? [N] "
  
  If ($OkRemove -eq "Y"){
    #Remove older COOP's from the list you created in the early part of the script.
    foreach ($VMz in $VMSvr) {
      Write-Host -sep `n "Checking to ensure $VMz is Powered Off." #-foregroundcolor Red
      If (($VMz.PowerState -eq "PoweredOff") -and ($VMz.Name -like "*COOP*")){
        Write-Host -sep `n $VMz "is in a Powered Off state and will be removed. " -foregroundcolor Blue 
        #Write-Host "Remove-VM $VMz -DeletePermanently -confirm:$true "
        Remove-VM $VMz -DeletePermanently -confirm:$true -runasync 
        
  }}}
}

