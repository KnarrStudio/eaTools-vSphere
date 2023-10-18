#requires -Version 3.0 -Modules VMware.VimAutomation.Core
Function Find-VmSnapshot
{
  <#
      .SYNOPSIS
      Finds a snapshot based on a search string

      .DESCRIPTION
      Searches either the Name or the Description field of all of the snapshot to return the ones with your search string

      .PARAMETER SearchField
      Either the 'Name' or the 'Description' field that are found in a snapshot

      .PARAMETER SearchString
      The string you are searching for

      .EXAMPLE
      Find-VmSnapshot -SearchField Name -SearchString INC123456
      This will search the Name field for the string (in this case a ticket number) INC123456

      .EXAMPLE
      Find-VmSnapshot
      This will return all snapshots on all VMs

      .NOTES
      Place additional notes here.

      .INPUTS
      Strings

      .OUTPUTS
      Object
  #>

  param(
    [Parameter(Mandatory,HelpMessage = 'The Field to search.  Name or Description')]
    [ValidateSet('Name','Description')]
    [AllowNull()]
    [AllowEmptyCollection()]
    [AllowEmptyString()][String]$SearchField,
    [AllowNull()]
    [AllowEmptyCollection()]
    [AllowEmptyString()][String]$SearchString,
    [AllowNull()]
    [AllowEmptyCollection()]
    [AllowEmptyString()][String]$SearchBeforeDate,
    [AllowNull()]
    [AllowEmptyCollection()]
    [AllowEmptyString()][String]$SearchDaysBack
  )

  function Script:Search-Snapshots
  {
    <#
        .SYNOPSIS
        Internal search
    #>
   
    param
    (
      [Parameter(Mandatory)][Object]$AllSnapshots,
      [Parameter(Mandatory)][Object]$SearchField,
      [Parameter(Mandatory)][Object]$SearchString
    )
    $AllSnapshots | Where-Object -Property $SearchField -Match -Value $SearchString
  }


  $AllVms = Get-VM
 
  Try
  {
    Write-Verbose -Message 'TRY'

    $AllSnapshots = $AllVms | Get-Snapshot -ErrorAction Stop

    if($SearchField -or $SearchString)
    {
      $FilteredSnapshotList = Search-Snapshots -AllSnapshots $AllSnapshots -SearchField $SearchField -SearchString $SearchString
    }
    elseif($SearchDaysBack -or $SearchBeforeDate)
    {
      if($SearchDaysBack)
      {
        $DaysBack = $SearchDaysBack
      }else
      {
        $DaysBack = (New-TimeSpan -Start $SearchBeforeDate -End (Get-Date)).Days
      }
      $FilteredSnapshotList = $AllSnapshots | Where-Object -Property Created -LE -Value $(Get-Date).AddDays(-$DaysBack)
    }
    else
    {
      $FilteredSnapshotList = $AllSnapshots
    }
    if($FilteredSnapshotList.count -gt 0)
    {
      $FoundSnapshot = $FilteredSnapshotList|  Select-Object -Property VM, Name, @{
        L = 'size GB'
        E = {
          '{0:N2}' -f $_.sizeGB
        }
      } 

      Write-Host -Object ('Result Count: {0}' -f $($FoundSnapshot.count))

      $FoundSnapshot
    }
    else
    {
      Write-Host -Object 'None Found'
    }
  }
  Catch
  {
    $AllSnapshots = 'Meaningful Error Message Here'
    Write-Verbose -Message 'CATCH'
  }
}

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
  $SnapshotName = ('SR_{0} - DEL_{1}' -f $TicketNumber , $($DeleteDate).ToString('yyyyMMMdd'))
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
  Select-Object -Property VM, Name, @{
    L = 'size GB'
    E = {
      '{0:N2}' -f $_.sizeGB
    }
  } |
  Format-Table -AutoSize 
  Write-Host -Object ('Count: {0}' -f $($Newsnaps.count))
}



Export-ModuleMember -Function Find-VmSnapshot, New-VmSnapshot
