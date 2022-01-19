Using module ".\Setup.psm1" # Get classes
Import-Module -Name ".\Setup.psm1" -Force # Update functions


# Important initial variables
$DatabaseName = "Certificate_Administration"
$RepoRoot = (Resolve-Path -Path ($PSScriptRoot + "\..")).Path
# Number of logs from previous runs to keep.
# n < 0 : All logs are kept
# n = 0 : No logs are kept
# n > 0 : n logs are kept
$LogsToKeep = 5


# IO Loop
while ($true) {
    $Prompt = "Setup `"$DatabaseName`" database"
    $Choices = `
        "Begin setup"`
        ,"Rename `"$DatabaseName`""`
        , "Exit"
    $Choice = Get-MultipleSelection $Prompt $Choices
    switch ($Choice) {
        # Setup
        $Choices[0] {
            Initialize-Database $DatabaseName $RepoRoot $LogsToKeep
            break
        }
        # Rename
        $Choices[1] {
            $DatabaseName = Rename-Database $DatabaseName $RepoRoot
            break
        }
        # Exit
        $Choices[2] {
            return
        }
    }
}
