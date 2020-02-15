Configuration NetworkingSetup {
    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName NetworkingDsc

    Node $AllNodes.NodeName
    {
        FirewallProfile DisablePrivateProfile
        {
            Name = 'Private'
            Enabled = $false
        }

        FirewallProfile DisablePublicProfile
        {
            Name = 'Public'
            Enabled = $false
        }

        FirewallProfile DisableDomainProfile
        {
            Name = 'Domain'
            Enabled = $false
        }
    }
}