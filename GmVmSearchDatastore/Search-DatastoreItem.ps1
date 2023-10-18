Function Search-DatastoreItem 
{
  <#
    .SYNOPSIS
    Describe purpose of "Search-DatastoreItem" in 1-2 sentences.

    .DESCRIPTION
    Add a more complete description of what the function does.

    .PARAMETER Expression
    Describe parameter -Expression.

    .PARAMETER Datastore
    Describe parameter -Datastore.

    .EXAMPLE
    Search-DatastoreItem -Expression Value -Datastore Value
    Describe what this call does

    .NOTES
    Place additional notes here.

    .LINK
    URLs to related sites
    The first link is opened by Get-Help -Online Search-DatastoreItem

    .INPUTS
    List of input types that are accepted by this function.

    .OUTPUTS
    List of output types produced by this function.
  #>


  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true,HelpMessage='String to search for',
    Position = 0)]
    [string]$Expression,
         
    [Parameter(ValueFromPipeline,
    Position = 1)]
    [Alias('DS')]
    [string[]]$Datastore = '*'
  )
 
  BEGIN {
    $Counter = 0
  }
     
  PROCESS {
 
    $DSNames = Get-Datastore -Name $Datastore |
    Where-Object -FilterScript {
      $_.Name -notlike 'ma-ds-*'
    } |
    Sort-Object -Property Name |
    Select-Object -ExpandProperty Name
 
    foreach ($DS in $DSNames) 
    {
      $Percent = '{0:n2}' -f (100/$DSNames.Count*$Counter)
      Write-Progress -Activity 'Searching datastores' -PercentComplete $Percent -CurrentOperation ('Searching {0}' -f $DS) -Status ('{0}% Complete - {1} of {2} datastore(s) completed' -f $Percent, $Counter, $DSNames.Count)
 
      Set-Location -Path "vmstore:\$(Get-Datacenter)"
             
      Write-Verbose -Message ('Searching {0}' -f $DS)
 
      Set-Location $DS
 
      Get-ChildItem -Filter $Expression -Recurse |
      Select-Object -Property Name, FolderPath, ItemType |
      Format-Table -AutoSize
 
      Write-Verbose -Message ('Done with {0}' -f $DS)
 
      Set-Location -Path ..
      $Counter ++
    }
 
    .$env:HOMEDRIVE
 
  }
 
  END {}
}
