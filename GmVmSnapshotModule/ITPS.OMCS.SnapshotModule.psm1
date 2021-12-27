#Module v2.0
Function New-VmSnapshot
{
  <#
      .SYNOPSIS
      Create snapshots with standarized names and descriptions.

      .DESCRIPTION
      Uses the "New-Snapshot function to create quiesced snapshots, but if it can't it will fail to a "non" quiesced snapshot.  It also builds out the name and description.

      .PARAMETER VM
      One or more VM separated by "," or can be a variable.

      .PARAMETER TicketNumber
      Tracking number found in the Ticketing system.

      .PARAMETER Customer
      Person requesting the Snapshot. Often found in the ticket.

      .PARAMETER Contactinfo
      Phone or email address or customer to get in touch with them if needed.

      .PARAMETER Deletelnxdays
      By default it is set for 3 days (72) hours.  This can also be changed if needed.

      .PARAMETER ReasonForSnapshot
      By default it is just referencing the ticket, but can be customized if needed.

      .EXAMPLE
      New-VmSnapshot -VM serverName -TicketNumber INC654789 -Customer 'Alfred E. Nueman' -Contactlnfo 844-8129

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online New-vmsnapshot

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


  param(
    [Parameter(Mandatory,HelpMessage = 'One or more VM separated by ","')]
    [Alias('VMS')]
    [String[]]$Script:VM,
    [Parameter(Mandatory,HelpMessage = 'Remedy Ticket Number')]
    [String]$TicketNumber ,
    [Parameter(Mandatory,HelpMessage = 'Customer requesting the Snapshot. Often found in the ticket')]
    [String]$Customer ,
    [Parameter(Mandatory,HelpMessage = 'Phone or email address or customer')]
    [String]$Contactinfo ,
    [Parameter(Mandatory = $false)]
    [int]$Deletelnxdays = 3 ,
    [Parameter(Mandatory = $false)]
    [String]$ReasonForSnapshot = ('Requested by ticket {0}' -f $TicketNumber)
  )

  $DeleteDate = $((Get-Date).AddDays($Deletelnxdays))
  $SnapshotName = ('{0}--{1}_Del' -f $TicketNumber , $($DeleteDate).ToString('yyyyMMdd'))
  $SnapshotDescription = ('Delete on: {2}| Created By:{4}| Customer: {0}| Contact (phone/email):{1}| Reason:{3}' -f $Customer , $Contactinfo, 
  $DeleteDate, $ReasonForSnapshot , $($env:USERNAME))

  $SplatInfo = @{
    Description = $SnapshotDescription
  }

  Write-Verbose -Message ('Snapshot Name: {0}' -f $SnapshotName)
  Write-Verbose -Message ("snapshot Description: 'n{0}" -f $SnapshotDescription)

  ForEach($vmGuest in $VM)
  {
    Write-Verbose -Message ('server Name: {0}' -f $vmGuest)
    Try
    {
      $SnapshotNameQ = $SnapshotName+'--Quiesced'
      Write-Verbose -Message 'TRY'
      $null = New-Snapshot -VM $vmGuest -Name $SnapshotNameQ @SplatInfo -Quiesce -ErrorAction stop
    }
    Catch
    {
      Write-Verbose -Message 'CATCH'
      $SnapshotNameN = $SnapshotName + '--Not_Quiesced'
      $null = New-Snapshot -VM $vmGuest -Name $SnapshotNameN @SplatInfo
    }
  }

  $VerbosePreference = 'SilentlyContinue'
  $Newsnaps = Get-VM |
  Get-Snapshot |
  Where-Object -Property Name -Match -Value $SnapshotName
  $Newsnaps |
  Select-Object -Property VM, Name, @{L = "size GB";E = {"{0:N2}" -f $_.sizeGB} } |  Format-Table -AutoSize 
  Write-Host -Object ('Count: {0}' -f $($Newsnaps.count))
}


Export-ModuleMember -Function New-VmSnapshot
