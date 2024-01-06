$Error.clear() # just for this test

function FastGetNativeCommand {
    <#
    .SYNOPSIS
        Returns the first path, or, null if no commands are found.
    .NOTES
        See related functions under:

            $ExecutionContext.InvokeCommand | Find-Member *Get*
    #>
    [OutputType('String')]
    param( [string]$Name )

    return $ExecutionContext.InvokeCommand.
        GetCommandName( $Name, $false, $true ).Where({$_},'first')
}
function GetNativeCommand {
    <#
    .SYNOPSIS
        wraps getting a native command. caller can change the error action, or force it to throw
    .NOTES
        warning, Get-Command is slow, especially on errors. you can speed this up two ways

        1] call ExecutionContext directly
        2] cache whether a native command was found or not

        Check out the functions here:

            $ExecutionContext.InvokeCommand | Find-Member *Get*

    .example
        see the bottom of this file for examples
    #>
    [OutputType('System.Management.Automation.ApplicationInfo')]
    [CmdletBinding()]
    param(
        [ValidateNotNullOrWhiteSpace()]
        [Alias('Path', 'PSPath', 'FullName', 'Name')]
        [string]$CommandName,
        # always throw, regardless of the error action.
        [Alias('Fatal')][switch]$Mandatory
    )
    $getCommandSplat = @{
        CommandType = 'Application'
        TotalCount  = 1
        Name        = $CommandName
    }

    try {
        $binCmd = Get-Command @getCommandSplat
    } catch [Management.Automation.CommandNotFoundException]{
        $errMsg = "CouldNotFindNativeCommandException! $CommandName"
        if($Mandatory) {
            throw [Management.Automation.CommandNotFoundException] $errMsg
        } else {
            # I'm not sure if using EA here gives better or worse caller UX
            write-error $ErrMsg # -ea 'stop'
            return
        }
    }
    return $binCmd
}
function InvokeNativeCommand {
    <#
    .SYNOPSIS
        Invokes a native command if it exists. automatically callls GetNativeCommand
    #>
    [Alias('InvokeBinCommand')]
    [CmdletBinding()]
    param(
        [ValidateNotNullOrWhiteSpace()]
        [Parameter()]
        [Alias('Path', 'PSPath', 'FullName', 'Name')]
        [string]$CommandName,

        [Alias('Args', 'BinArgs')]
        [Object[]]$ArgList
    )
    $BinCmd = GetNativeCommand -Mandatory -CommandName $CommandName
    $ArgList | Join-String -sep ' ' -op (
        Join-String -f "Invoking => {0}" -in $BinCmd.Name )
        | Write-Verbose

    & $BinCmd @ArgList
}

function ExampleStop {
    # Test for -Ea Stop
    param( [string]$Name )
    write-verbose -Verb 'do I ever reach the end?'
    if( GetNativeCommand $Name -ea 'stop' ) {
        write-verbose -verb 'user has command, do stuff'
    }
    Write-Verbose -verb 'Reached the end?' # not when when cmd is missing
}
function ExampleIgnore {
    # Test for -Ea Ignore
    param( [string]$Name )
    if( GetNativeCommand $Name -ea Ignore ) {
        write-verbose -verb 'user has command, do stuff'
    } else {
        write-verbose -verb 'silent failure case'
    }
}
function ExampleCatch {
    <#
    .SYNOPSIS
        fail the first lookup on purpose, to test ShouldProcess handling
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param()
    'Searching for native command ripgrep, fail on purpose' | Write-verbose -verbose
    try {
        GetNativeCommand 'rg_bad_name' -Mandatory -ea 'stop'
    } catch {
        'try install ripgrep?' | write-warning
        if ($PSCmdlet.ShouldProcess("RipGrep", "Winget Install")) {
            InvokeNativeCommand 'winget' -ArgList @(
                'install'
                '--id'
                'BurntSushi.ripgrep.MSVC'
            )
        } else {
            write-warning 'ripgrep was not found, user skipped auto-install prompt'
            return
        }
    }

    InvokeNativeCommand -CommandName 'rg' -arglist @(
        '--version'
    )
    'success!' | Write-host -fore 'green'
}

@'
example commands to try:

    FastGetNativeCommand 'pwsh'
    FastGetNativeCommand 'badname'

    ExampleStop pwsh
    ExampleStop badname

    ExampleIgnore Pwsh
    ExampleIgnore badname

    ExampleStop pwsh
    ExampleStop badname

    GetNativeCommand 'winget'

    InvokeBinCommand 'winget' '--help'
    InvokeBinCommand 'code' @('-g', $PROFILE.CurrentUserAllHosts)

    GetNativeCommand 'bad' -ea 'Stop'
    GetNativeCommand 'bad' -ea 'ignore'
    GetNativeCommand 'bad' -Mandatory


'@ | write-host -fore 'green'
