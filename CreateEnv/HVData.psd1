@{
    AllNodes = @(
        @{
            NodeName = "*"
            GoldenImagePath = 'D:\VM\Hyper-V\GoldenImages'
            VMStorePath = 'D:\VM\Hyper-V'
            PSDscAllowPlainTextPassword = $true
        }
        @{
            NodeName = 'localhost'
            VirtualMachines = @(
                @{
                    VMName = 'Test-ISBets01'
                    GoldenImage = "WIN2016.vhdx"
                }
            )
        }
    );
    NonNodeData = ''
}