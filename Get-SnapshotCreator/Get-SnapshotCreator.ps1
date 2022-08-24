function Get-SnapshotCreator
{
    Param(
        [Parameter(Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.SnapshotImpl]$Snapshot
    )
    Begin
    {
        function Get-SnapshotTree
        {
          param([Parameter(Mandatory)][Object]$tree, [Parameter(Mandatory)][Object]$target)
          $found = $null
          foreach($elem in $tree){
            if($elem.Snapshot.Value -eq $target.Value)
            {
              $found = $elem
              continue
            }
          }
          if($found -eq $null -and $elem.ChildSnapshotList -ne $null)
          {
            $found = Get-SnapshotTree -tree $elem.ChildSnapshotList -target $target
          }
          return $found
        }
    }
    Process
    {
      $guestName = $Snapshot.VM.Name
      $tasknumber = 999 
      $tMgr = Get-View -VIObject TaskManager
      #Create hash table. Each entry is a create snapshot task
      $report = @{}
      
      $filter = New-Object -TypeName VMware.Vim.TaskFilterSpec
      $filter.Time = New-Object -TypeName VMware.Vim.TaskFilterSpecByTime
      $filter.Time.beginTime = $Snapshot.Created.AddDays(-5)
      $filter.Time.timeType = 'startedTime'
      
      $collectionImpl = Get-View -VIObject ($tMgr.CreateCollectorForTasks($filter))
      $null = $collectionImpl.RewindCollector
      $collection = $collectionImpl.ReadNextTasks($tasknumber)
      while($collection -ne $null)
      {
       $collection | 
        Where-Object { $_.DescriptionId -eq 'VirtualMachine.createSnapshot'} |
        Where-Object { $_.State -eq 'success' }|
        Where-Object { $_.EntityName -eq $guestName} | 
        ForEach-Object {
          $row = New-Object -TypeName PsObject -Property @{
            'User'=$_.Reason.UserName
          }
        
          $vm = Get-View -VIObject $_.Entity
          if($vm -ne $null)
          {
            $snapshottree = Get-SnapshotTree -target $_.Result -tree $vm.Snapshot.RootSnapshotList 
            if($snapshottree -ne $null)
            {
                $key = '{0}&{1}' -f $_.EntityName, 
                    $snapshottree.CreateTime.ToFileTimeUtc()
                $report[$key] = $row
            }
          }
       }
       $collection = $collectionImpl.ReadNextTasks($tasknumber)
    }
    $collectionImpl.DestroyCollector()
    # Get the guest snapshots and add the user
    Foreach ($snap in $snapshot) 
    {
      $key ='{0}&{1}' -f $snap.vm.Name, $snap.Created.ToFileTimeUtc()
      if($report.ContainsKey($key))
      {
          $snap | Add-Member -MemberType NoteProperty -Name Creator `
              -Value $report[$key].User -PassThru
      }
    }
  }
}