Configuration VMSetup {
    Import-DscResource -ModuleName PSDesiredStateConfiguration 
    Import-DscResource -ModuleName xHyper-V

    Node $AllNodes.NodeName {
        File CreateVMFolder {
            Type = 'Directory'
            DestinationPath = Join-Path $Node.VMStorePath $Node.NodeName
        }

        File GoldenImageCopy {
            Type = 'File'
            DestinationPath = Join-Path $Node.VMStorePath -ChildPath $Node.NodeName | Join-Path -ChildPath $Node.GoldenImage
            SourcePath = Join-Path $Node.GoldenImagePath -ChildPath $Node.GoldenImage
            Force = $true
            DependsOn = '[File]CreateVMFolder'
        }
    }
}