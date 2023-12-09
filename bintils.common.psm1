using namespace System.Collections.Generic
using namespace System.Management.Automation.Language
using namespace System.Management.Automation

[List[Object]]$script:BC_LastBinArgs = @()
[hashtable]$script:BC_AppConfig = [ordered]@{
    FormatStr = @{
        YearMonthDay_Filename = "yyyy-MM-dd"
        DateTime_Iso8607 = "yyyy'-'MM'-'dd HH':'mm':'ss'Z'"
    }
}
[hashtable]$script:___UserHasCommand = @{}

function Bintils.Common.Format.Whitespace {
    <#
    .notes
        'flatten' or 'collapse' for this function flattens, sort of like html does

        FlattenNewLine

            in : a\n\n\nb\nc\nBintils.Common.Format.Whitespace
            out: a\nb\nc\n

        NormalizeLineEnding

            in : \ra\r\nb\r\r
            out: \na\nb\n\n
    .LINK
        https://learn.microsoft.com/en-us/dotnet/standard/base-types/character-classes-in-regular-expressions#WhitespaceCharacter
    .link
        https://learn.microsoft.com/en-us/dotnet/standard/base-types/character-classes-in-regular-expressions#SupportedUnicodeGeneralCategories
    #>
    [OutputType('System.String')]
    [Alias('Bintils.Common.Format-CleanText')]
    param(
        [Alias('InputObject', 'In', 'InpObj', 'Obj', 'String', 'Lines')]
        [Parameter(ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$Text,

        [ArgumentCompletions(
            '@{ StripAnsiColors = $false }',
            '@{ StripAllAnsiEscapes = $false }',
            '@{ NormalizeLineEnding = $false }',
            '@{ FlattenSpace = $false }',
            '@{ FlattenNewline = $false }',
            '@{ FlattenOtherWhitespace = $false }',
            '@{ FormatControlChars = $false }',
            '@{ StripControlChars = $false }'
        )]
        [hashtable]$Options = @{}
    )

    begin {
        $Config = @{
            StripAnsiColors = $True
            StripAllAnsiEscapes = $True
            NormalizeLineEnding = $True
            FlattenSpace = $true
            FlattenNewline = $True
            FlattenOtherWhitespace = $True
            FormatControlChars = $True
            StripControlChars = $true
        }
        $Config = nin.MergeHash -BaseHash $Config -OtherHash  ( $Options ?? @{} )
    }
    process {
        foreach($curLine in $Text) {
            [string]$Accum = $curLine

            if($Config.StripAnsiColors) {
                $Accum = $Accum -replace
                    '\u001B.*?m',
                    ''
            }
            if($Config.StripAllAnsiEscapes) {
                $Accum = $Accum -replace
                    '\u001B.*?\p{L}',
                    ''
            }

            if($Config.NormalizeLineEnding) {
                $Accum = $Accum -replace
                '\r?\n',
                "`n"
            }
            if($Config.FlattenSpace) {
                $Accum = $Accum -replace
                '[ ]+',
                ' '
           }
            if($Config.FlattenNewline) {
                $Accum = $Accum -replace
                '(\r?\n)+',
                "`n"
            }
            if($Config.FlattenOtherWhitespace) {
                $Accum = $Accum -replace
                '\s+',
                '␠'
            }
            if($Config.StripControlChars) {
                $Accum = $Accum -replace
                '(\p{Cc})+',
                "`u{2400}"
            }

            if($Config.FormatControlChars) {
                # '\'
                $Accum = $Accum | Format-ControlChar
            }

            $Accum
            continue
        }
    }
}

function Bintils.Common.New.CompletionResult {
    [Alias(
        'Bintils.CompletionResult',
        'Bintils.New.CR'
    )]
    param(
        # original base text
        [Alias('Item', 'Text')]
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$ListItemText,

        # actual value used in replacement, if not the same as ListItem
        [AllowEmptyString()]
        [AllowNull()]
        [Alias('Replacement', 'Replace')]
        [Parameter()]
        [string]$CompletionText,

        # Is there a better default?
        [Parameter()]
        [CompletionResultType]
        $ResultType  = ([CompletionResultType]::ParameterValue),

        # multi-line text displayed when using listcompletion
        [Parameter()]
        [Alias('Description', 'Help', 'RenderText')]
        [string[]]$Tooltip
    )
    [System.ArgumentException]::ThrowIfNullOrWhiteSpace( $ListItemText , 'ListItemText' )

    $Tooltip =  $Tooltip -join "`n"
    if( [string]::IsNullOrEmpty( $Tooltip )) {
        $Tooltip = '[⋯]'
    }
    if( [string]::IsNullOrEmpty( $CompletionText )) {
        $CompletionText = $ListItemText
    }
    [CompletionResult]::new(
        <# completionText: #> $completionText,
        <# listItemText  : #> $listItemText,
        <# resultType    : #> $resultType,
        <# toolTip       : #> $toolTip)
}


function Bintils.Common.PreviewArgs {
    <#
    .SYNOPSIS
        write dim previews of the args
    #>
    param(
        [Alias(
            'Args', 'List', 'Items', 'Obj' )]
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$InputObject
    )
    begin {
        [List[Object]]$Items = @()
    }
    process {
        $Items.AddRange(@( $InputObject ))
     }
     end {
        $Items
            | Join-String -sep ' ' -op 'bin args => @( ' -os ' )'
            | Bintils.Common.Write-DimText
     }
}

function Bintils.Common.Test-UserHasNativeCommand {
    <#
    .SYNOPSIS
        Tests if a native command is found, then caching results. const-time if it is cached
    .EXAMPLE
        > Bintils.Common.Test-UserHasNativeCommand 'bat'
        > Bintils.Common.Test-UserHasNativeCommand 'fd'

    .EXAMPLE
        > Bintils.Common.Test-UserHasNativeCommand -All
    .EXAMPLE
        > Bintils.Missing-NativeCmd rg
        > Bintils.Missing-NativeCmd rg_missing
        > Bintils.Has-NativeCmd rg
        > Bintils.Has-NativeCmd rg_missing

        # True,  False, True,  False

    .NOTES
        future: compare whether SessionStateInvokingCommand is faster
            $ExecutionContext.InvokeCommand.GetCommand('pwsh', 'Application')

    #>
    [Alias(
        'Bintils.Test-HasNativeCmd',
        'Bintils.IsMissing-NativeCmd',
        'Bintils.Missing-NativeCmd',
        'Bintils.Has-NativeCmd'
    )]
    [CmdletBinding(DefaultParameterSetName='FindOne')]
    param(
        [Parameter(Mandatory,parameterSetName='FindOne', Position=0)]
        [string]$CommandName,

        [Alias('All')]
        [Parameter(ParameterSetName='ListAll')]
        [switch]$PassThru,

        # inverts the boolean, for UX
        # or use the alias to be enabled by default
        [Alias('IsMissing', 'WhenMissing')]
        [Parameter(ParameterSetName='FindOne')]
        [switch]$TrueWhenMissing,

        [switch]$SlowSearch
    )
    $state = $script:___UserHasCommand

    <#
    .notes
        when calling
        > Bintils.Missing-NativeCmd -CommandName bat

        then
        > $PSCmdlet.MyInvocation.MyCommand.Name # -is 'Bintils.Common.Test-UserHasNativeCommand'

            Bintils.Common.Test-UserHasNativeCommand

        then
        > $PSCmdlet.MyInvocation.InvocationName # -is 'Bintils.Missing-NativeCmd'

    #>
    $commandAliasUsed = $PSCmdlet.MyInvocation.InvocationName

    if( $commandAliasUsed -match '(Is)?Missing-') {
        # $MyInvocation.MyCommand.Name | write-host -fg 'orange'
        # $Pscmdlet.MyInvocation | write-host -fg 'blue'
        write-debug 'cache-miss for Test-UserHasNativeCommand'
        $TrueWhenMissing = $true
    }

    switch($PSCmdlet.ParameterSetName){
        'ListAll' {
            return $state
        }
        default {
            if( -not $state.ContainsKey( $CommandName )) {
                if($SlowSearch) {
                    $state[ $CommandName ] =
                        [bool](Gcm -Name $CommandName -CommandType Application -ea 'ignore').count -gt 0
                } else {
                    $ExecutionContext.InvokeCommand.GetCommand(
                        <# commandName: #> 'pwsh',
                        <# type: #> 'Application' )
                }
            }
            $wasFound = $state[ $CommandName ]

            if( $TrueWhenMissing ) { return -not $wasFound }
            return $wasFound
        }
    }
}

function Bintils.Common.Format.CommandAst {
    <#
    .synopsis
    .notes
        $commandAst.CommandElements.GetType()

        Namespace: System.Collections.ObjectModel

        Pwsh 7.4.0> [23] 🐒
        $commandAst | % gettype |Ft -AutoSize

            Namespace: System.Management.Automation.L

            Access Modifiers Name
            ------ --------- ----
            public class     CommandAst : CommandBaseAst

        Pwsh 7.4.0> [23] 🐒
        $commandAst.CommandElements | % gettype | ft  -AutoSize

            Namespace: System.Management.Automation.Language

            Access Modifiers Name
            ------ --------- ----
            public class     StringConstantExpressionAst : ConstantExpressionAst
    #>
    [CmdletBinding(DefaultParameterSetName = 'AsCommandAst')]
    param(
        [Alias('InputObject', 'In', 'Obj', 'Cmd')]
        [Parameter(
            ParameterSetName = 'AsCommandAst',
            Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [CommandAst]$CommandAst, # -is Management.Automation.Language
        [Parameter(
            ParameterSetName = 'AsCommandElements',
            Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [object[]]$CommandElements # -is Management.Automation.Language
        # [hashtable]$Options = @{}

        # [Parameter(ValueFromTypeName)]

    )
    begin {
        $Options = @{
            PadLeft = 10
            Template = @'
    {2} | {0} [ {1} ]
'@
        }
    }
    process {
        <#
        'future '


        #>
        $CommandAst.CommandElements | %{
            $_ | Join-String {
                $Options.Template -f @(
                    $_.StringConstantType;
                    $_.StaticType
                    $_.Value.ToString().PadLeft( $Options.PadLeft, ' ')
                ) }
            }
    }

}


function Bintils.Common.Format.BaseTypeChain {
    <#
    .SYNOPSIS
        visualize inher
    .NOTES
        future:
            - allow piping or parameter
    .EXAMPLE
        Fmt.BaseType ( Get-Item . ) |  Join-String
        Fmt.BaseType ( $commandAst.CommandElements[2] ) |  Join-String
    .EXAMPLE
        Fmt.BaseType ( $commandAst.CommandElements[2] ) |  Join.UL
            - ConstantExpressionAst
            - ExpressionAst
            - CommandElementAst
            - Ast
            - Object
    #>
    [Alias('Bintils.Format.TypeChain')]
    param( [Object]$InputObject )

   $curType = $InputObject.GetType()
   $nextBase = ( $curType )?.BaseType
   $found = @(
        while( -not ( -not $nextBase) ) {
            $nextBase.Name
            $nextBase = $nextBase.BaseType
        }
    )
    $NamesToDim = @(  # stuff that I don't want to toally remove
        'Ast'
    )
    $NamesToIgnore = @(
        'Object'
    )

    $found.Where({ $_ -notin @($NamesToIgnore) })
    return $Found

}
function Bintils.Common.Format.TrimOuterSlashes {
    <#
    .SYNOPSIS
        reason: Join-path can't be used on 's3' filepaths
    .EXAMPLE
        Pwsh> '/2023', '/foo/' | Bv.Format.TrimOuterSlashes

            2023
            foo
    #>
    [Alias('Bintils.Common.TrimOuterSlashes')]
    [OutputType('String')]
    param(
        [switch]$StripBackslash,
        [switch]$StripForwardslash
    )
    process {
        [string]$Accum = $_

        [bool]$useDefaultParams =
            -not $PSBoundParameters.ContainsKey('StripBackslash') -and -not $PSBoundParameters.ContainsKey('StripForwardslash')

        if( $UseDefaultParams ) {
            write-verbose 'fallback to stripping both types when not specified'
            $StripBackslash = $true
            $StripForwardslash = $true
        }

        if( $StripBackslash ) {
            $Char = '\'
            $Accum = $Accum -replace ( '^' + [regex]::Escape( $Char ) ), ''
            $Accum = $Accum -replace ( [regex]::Escape( $Char ) + '$' ), ''
        }
        if( $StripForwardslash ) {
            $Char = '/'
            $Accum = $Accum -replace ( '^' + [regex]::Escape( $Char ) ), ''
            $Accum = $Accum -replace ( [regex]::Escape( $Char ) + '$' ), ''
        }
        return $Accum
    }
}

function Bintils.Common.Write-DimText {
    <#
    .SYNOPSIS
        # sugar for dim gray text,
    .EXAMPLE
        # pipes to 'less', nothing to console on close
        get-date | Dotils.Write-DimText | less

        # nothing pipes to 'less', text to console
        get-date | Dotils.Write-DimText -PSHost | less
    .EXAMPLE
        > gci -Name | Dotils.Write-DimText |  Join.UL
        > 'a'..'e' | Dotils.Write-DimText  |  Join.UL
    #>
    [OutputType('String')]
    [Alias('Bintils.DimText')]
    param(
        # write host explicitly
        [switch]$PSHost
    )
    $Ratio60 = 256 * .6 -as 'int'
    $Ratio20 = 256 * .2 -as 'int'

    $Fg = @{
        Gray60 = $PSStyle.Foreground.FromRgb( $Ratio60, $Ratio60, $Ratio60 )
        Gray20 = $PSStyle.Foreground.FromRgb( $Ratio20, $Ratio20, $Ratio20 )
    }
    $Bg = @{
        Gray60 = $PSStyle.Background.FromRgb( $Ratio60, $Ratio60, $Ratio60 )
        Gray20 = $PSStyle.Background.FromRgb( $Ratio20, $Ratio20, $Ratio20 )
    }

    $ColorDefault = @{
        ForegroundColor = 'gray60'
        BackgroundColor = 'gray20'
    }
    [string]$render =
        $Input
            | Join-String -op $(
                $Fg.Gray60,
                $Bg.Gray20 -join '') -os $( $PSStyle.Reset )

    return $render | Write-Information -infa 'Continue'


    # if($PSHost) {

    #         # | Pansies\write-host @colorDefault
    # }

    # return $Input
    #     | New-Text @colorDefault
    #     | % ToString
}
function Bintils.Common.InvokeBin {
    <#
    .SYNOPSIS
        Actually calls the native command, and waits fora a confirm prompt. Args may come from Bintils.Common.BuildBinArgs
    #>
    [Alias('Bintils.Common.Invoke')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param(
        [object[]]$BinArgs,

        [ArgumentCompletions('aws', 'rclone')]
        [Alias('NativeCommandName')]
        [string]$CommandName = 'aws'
    )
    'Invoke: ' | write-verbose -Verbose
    # "`n`n"
    $binAws = Get-Command -CommandType Application -Name $CommandName -TotalCount 1 -ea 'stop'
    # "`n`n"
    $BinArgs | Bintils.Common.PreviewArgs
    # "`n`n"
    if ($PSCmdlet.ShouldProcess(
        "$( $BinArgs -join ' '  )",
        "InvokeBin: $( $CommandName )")
    ) {
        '   Calling "{0}"' -f @( $CommandName )
            | write-host -fore 'green'

        '   Calling "{0}"' -f @( $CommandName )
        # '::invoke: => Confirmed'
            | Bintils.Common.Write-DimText | Write-Information -infa 'continue'

        & $BinAws @BinArgs
    } else {
        # '::invoke: => Skip' | Bintils.Common.Write-DimText | Write-Information -infa 'continue'
        '   Skipped calling "{0}"' -f @( $CommandName ) | write-host -back 'darkred'
    }
    $BinArgs
        | Bintils.Common.PreviewArgs
        # | write-host -fore 'Green'
}

function Bintils.Common.NewFolderName.FromDate {
    <#
    .SYNOPSIS
        folder name using the date '2031-01-04'
    .EXAMPLE
        Pwsh> Bintils.Common.NewFolderName.FromDate
            2023-11-15

        Pwsh> Bintils.Common.NewFolderName.FromDate -InputDateTime (get-date).AddDays(-30)
            2023-11-16
    #>
    [OutputType('String')]
    param(
        # Datetime if not specified
        [Parameter()]
        [Alias('Datetime', 'From', 'FromDt', 'Dt')]
        $InputDateTime = [Datetime]::Now
    )

    return $InputDateTime.ToString( $BC_AppConfig.FormatStr.YearMonthDay_Filename )
}

function Bintils.Common.Config.Get {
    'or edit $script:BC_AppConfig' | write-host -back 'blue'
    return $script:BC_AppConfig
}

Export-ModuleMember -Function @(
    'Bintils.*'
    'Bin.Common.*'
) -Alias @(
    'Bintils.*'
    'Bin.Common.*'
) -Variable @(
    'BC_*'
    'BC_LastBinArgs',
    'Bintil*'
    'BC_AppConfig'
)
