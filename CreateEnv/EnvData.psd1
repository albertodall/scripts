@{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
        }
        @{
            NodeName = 'Test-ISBets01'
        }
    );
    NonNodeData = ''
}