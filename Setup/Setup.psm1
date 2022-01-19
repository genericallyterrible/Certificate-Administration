<# Object for storing long snipets of SQL code.
    Writes content to a file that is removed when
    the object is disposed.
    Implementing disposable ensures that the temporary
    file used is removed, even if execution
    is cancelled by the user with Ctrl + C.
    No guarantees are made about behavior if the
    shell encounters a hard crash or is closed
    prematurely by the user.
    Stores file contents in a temporary string of up to
    $BatchSize length before adding it's contents to the
    file at $FilePath to reduce I/O operations.
    This comes with the drawback that WriteToFile()
    must be called before the file at $FilePath contains
    all of the intended content.
#>
class DisposableCommand : System.IDisposable {
    static [int] $Private:BatchSize = 100000
    [string] $Private:FilePath
    [string] $Private:CommandText = ""

    DisposableCommand (
        [string] $FilePath
    ) {
        $this.FilePath = $FilePath
        $this.CreateFile()
    }

    [void] AddSQLFile (
        [string] $RepoRoot
        , [string] $SQLFilePath
    ) {
        $this.AddCommandText((Get-SQLFile $RepoRoot $SQLFilePath))
    }

    [void] AddCommandText (
        [string] $CommandText
    ) {
        $this.CommandText += (
            $CommandText.TrimEnd()`
            + [System.Environment]::NewLine`
            + [System.Environment]::NewLine`
            + [System.Environment]::NewLine
        )
        $this.CheckCommandLength()
    }

    [void] hidden CheckCommandLength() {
        if ($this.CommandText.Length -gt [DisposableCommand]::BatchSize) {
            $this.WriteToFile()
        }
    }

    [void] WriteToFile() {
        if ($this.CommandText -ne "") {
            # Write-Host "Writing $($this.CommandText.Length) characters"
            $this.CommandText | Add-Content -Path $this.FilePath -NoNewline
            $this.CommandText = ""
        }
    }

    [string] GetFilePath() {
        $this.WriteToFile()
        return $this.FilePath
    }

    [void] SetFilePath (
        [string] $FilePath
    ) {
        $this.MoveFile($FilePath)
        $this.WriteToFile()
    }

    [void] MoveFile (
        [string] $FilePath
    ) {
        if (Test-Path $this.FilePath) {
            # File exists at old location, move and update
            Move-Item -Path $this.FilePath -Destination $FilePath
            $this.FilePath = $FilePath
        } else {
            # No file at old location, update and create
            $this.FilePath = $FilePath
            $this.CreateFile()
        }
    }

    [void] CreateFile() {
        if (!(Test-Path $this.FilePath)) {
            New-Item $this.FilePath -ItemType File
        } else {
            "" | Set-Content -Path $this.FilePath
        }
    }

    [void] DeleteFile() {
        if (Test-Path $this.FilePath) {Remove-Item $this.FilePath}
        $this.CommandText = ""
    }

    [void] Dispose() {
        $this.DeleteFile()
    }
}


<# Mimics to some capacity the using statement from C#
    Caveats:
    Since the $ScriptBlock is passed in as a parameter
    it occupies a separate scope from the surrounding code.
    The values of visually surrounding variables may be used
    however, they must be passed as references if their
    values are to be modified.
    The return keyword immediately exits the try block
    and triggers the finally block.
    Unlike the using statement in C#, a value can be returned.
#>
function UsingObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )

    try
    {
        $result = . $ScriptBlock
    }
    finally
    {
        if ($null -ne $InputObject -and $InputObject -is [System.IDisposable])
        {
            $InputObject.Dispose()
        }
    }
    return $result
}


<# Prompts the user for a selection of one of multiple items
    1. Displays $Prompt.
    2. Optionally displays $CancelPrompt in position 0 if
        $Cancellable is $true.
    3. Iterates over $Options and displays each in
        position 1 to $Options.Count.
    Repeates steps 1 to 3 until a valid option is chosen.
#>
function Get-MultipleSelection {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Prompt
        , [Parameter(Mandatory=$true)]
        [string[]] $Options
        , [Parameter(Mandatory = $false)]
        [bool] $Cancellable = $false
        , [Parameter(Mandatory = $false)]
        [string] $CancelPrompt = "Cancel"
    )

    [int] $Response = 0
    [bool] $IsValid = $false
    [int] $Padding = ($Options.Count).ToString().Length + 2
    while (!($IsValid)) {
        [int] $OptionNo = 0

        Write-Host $Prompt
        if ($Cancellable) {
            Write-Host ("[$OptionNo]".PadLeft($Padding) + ": $CancelPrompt")
        }

        foreach ($Option in $Options) {
            $OptionNo += 1
            Write-Host ("[$OptionNo]".PadLeft($Padding) + ": $Option")
        }

        if ([Int]::TryParse((Read-Host), [ref]$Response)) {
            if (($Response -eq 0) -and ($Cancellable)) {
                return ""
            }
            elseif (($Response -ge 1) -and ($Response -le $Options.Count)) {
                $IsValid = $true
            }
        }
    }

    return $Options.Get($Response - 1)
}


# Creates a line of SQL code to print a message for logging purposes
function Get-LogLine {
    param (
        [string] $Message
        , [Parameter(Mandatory = $false)]
        [string] $Severity = "INFO"
    )
    return "PRINT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff') + ' $Severity $Message'" + [System.Environment]::NewLine
}


<# Returns the contents of a SQL file as a string
    Prepends a line for logging information about when
    the command was executed and what the file is relative
    to the root of the repository.
#>
function Get-SQLFile {
    [OutputType([string])]
    param (
        [string] $RepoRoot
        , [string] $SQLFilePath
    )
    $FileContent = Get-Content -Path $SQLFilePath -Raw
    if ([string]::IsNullOrEmpty($FileContent)) {
        return ""
    }
    # Add print message to SQL command to deliminate the beginning of the file then get the file
    return (Get-LogLine ($SQLFilePath -replace [regex]::Escape($RepoRoot), '.') "INFO")`
    + $FileContent.TrimEnd()`
    + [System.Environment]::NewLine`
    + [System.Environment]::NewLine
}


# Removes Logfiles in $LogsDir based on $LogsToKeep
function Remove-OldLogs {
    param (
        [Parameter(Mandatory=$true)]
        [string] $LogsDir
        , [Parameter(Mandatory=$true)]
        [int] $LogsToKeep
    )
    if ($LogsToKeep -lt 0) {
        # Don't delete any logs if $LogsToKeep < 0
        return
    } elseif ($LogsToKeep -eq 0) {
        # Don't keep any logs, delete the directory
        Remove-Item $LogsDir -Recurse
    } else {
        # Delete old log files when there are more than $LogsToKeep
        $Logs = Get-ChildItem $LogsDir -Filter *.log
        if (($Logs -is [array]) -and ($Logs.Length -gt $LogsToKeep)) {
            $OldLogs = $Logs | Sort-Object -Property CreationTime -Top ($Logs.Length - $LogsToKeep)
            foreach ($OldLog in $OldLogs) {
                Remove-Item $OldLog
            }
        }
    }
}


# Changes all instances of the CurDBName in SQL files in this repository
function Rename-Database {
    param (
        [Parameter(Mandatory = $true)]
        [string] $CurDBName
        , [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $CurDBQuotedSQL = "\[$CurDBName\]"
    $CurDBQuotedPS = "`"$CurDBName`""

    $NewDBName = Read-Host ("Enter a new name for the $CurDBQuotedPS database (empty input cancels) ")
    if ("" -eq $NewDBName) {
        Write-Host "Renaming cancelled"
        return $CurDBName
    }

    $NewDBQuotedSQL = "[$NewDBName]"
    $NewDBQuotedPS = "`"$NewDBName`""

    # Update all SQL scripts
    Get-ChildItem $RepoRoot -Recurse -Filter *.sql |
    ForEach-Object {
        ((Get-Content -Path $_.FullName -Raw) -replace $CurDBQuotedSQL,$NewDBQuotedSQL).TrimEnd()
        | Set-Content -Path $_.FullName
    }

    # Update all Powershell scripts
    Get-ChildItem $RepoRoot -Recurse -Filter *.ps*1 |
    ForEach-Object {
        ((Get-Content -Path $_.FullName -Raw) -replace $CurDBQuotedPS,$NewDBQuotedPS).TrimEnd()
        | Set-Content -Path $_.FullName

    }

    Write-Host "Successfully renamed to: $NewDBQuotedPS"
    return $NewDBName
}


function Initialize-Database {
    param (
        [Parameter(Mandatory = $true)]
        [string] $DatabaseName
        , [Parameter(Mandatory = $true)]
        [string] $RepoRoot
        , [Parameter(Mandatory = $false)]
        [int] $LogsToKeep = 5
    )

    $SetupDir = $RepoRoot + "\Setup"
    $SetupSQL = $SetupDir + "\Setup.sql"
    $SQLDir = $RepoRoot + "\SQL"
    $CommandFile = $SetupDir + "\Command.sql"
    $LogsDir = $RepoRoot + "\Logfiles"
    $LogFile = $LogsDir + "\" + (Get-Date -Format "yyyy-MM-dd_HH_mm_ss_fff") + ".log"
    $ServerName = [ref]""

    # Create Logfiles directory if it doesn't exist
    if (-not (Test-Path -Path $LogsDir -PathType Container)) {
        New-Item -Path $LogsDir -ItemType "directory" > $null
    }

    UsingObject($Command = [DisposableCommand]::new($CommandFile)) {

        # Generate single sql script from .\Setup\Setup.sql and all sql files in .\SQL
        $Command.AddCommandText(
            (Get-LogLine "Beginning of execution for $DatabaseName")`
            + "GO"
            )

        $Command.AddSQLFile($RepoRoot, $SetupSQL)

        Get-ChildItem $SQLDir -Recurse -filter *.sql |
        ForEach-Object {
            # Write-Host $_.FullName # Debugging
            $Command.AddSQLFile($RepoRoot, $_.FullName)
        }
        # Add the tables twice so tables that depended on one another are successfully created
        Get-ChildItem ($SQLDir + "\Tables") -Recurse -filter *.sql |
        ForEach-Object {
            $Command.AddSQLFile($RepoRoot, $_.FullName)
        }

        $Command.AddCommandText(
            (Get-LogLine "End of execution for $DatabaseName")`
            + "GO"
            )
        $Command.WriteToFile()


        # Prompt for user input
        $ServerName.Value = Read-Host "Enter the name of the server to attach to"
        if ($ServerName.Value -eq "") {$ServerName.Value = "."}

        $Prompt = "Server authentication method"
        $Choices = "Windows Authentication","SQL Server Authentication"
        $Choice = Get-MultipleSelection $Prompt $Choices

        switch ($Choice) {
            $Choices[0] {
                # Windows Authentication
                SQLCMD -S $ServerName.Value -E -i $CommandFile -o $LogFile
                break
            }
            $Choices[1] {
                # SQL Server Authentication
                $Username = Read-Host -Prompt "Username"
                SQLCMD -S $ServerName.Value -U $Username -i $CommandFile -o $LogFile
                # Add a newline after the password prompt
                Write-Host ""
                break
            }
        }
    }


    # Delete old log files
    Remove-OldLogs $LogsDir $LogsToKeep

    if ($LogsToKeep -ne 0) {
        if (Test-Path $LogFile) {
            Write-Host "Log written to: `"$LogFile`""
        } else {
            Write-Host "Failed to write log to: `"$LogFile`""
        }
    }


    if ($LastExitCode -ne 0) {
        Write-Host "Could not complete setup for: `"$DatabaseName`" on server: `"$($ServerName.Value)`""
    } else {
        Write-Host "Setup completed for: `"$DatabaseName`" on server: `"$($ServerName.Value)`""
    }
    Start-Sleep 1
}
