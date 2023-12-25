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


function Bintils.Commmn.Format.String.Shorten {
    <#
    .SYNOPSIS
        Get the longest substring, based on param MaxLength. will not error
    .NOTES
        Similar to [string]::substring( x, length )
            but errors are coerced or ignored (silent for UX)

        does not join strings, so you can pipe an array and each are seperately truncated
    - future
        - [ ] optionally use codepoint count for lengths
        - [ ] optionally auto-join for cases where you're going to use a Join-String
    see also:
        - <Dotils/tests/Format-ShortString.tests.ps1>
    #>
    [Alias(
        'Bintils.Common.Format-ShortenString',
        'Bintils.Common.Str.Trunc',
        'Bintils.ShortenString',
        'Bintils.Str.Shorten',
        'Bintils.Str.Trunc'
    )]
    [OutputType('System.String')]
    param(
        # does not join strings, so you can pipe an array and each are seperately truncated
        [Alias('InputObject', 'In', 'InpObj', 'Obj', 'String', 'Lines')]
        [Parameter(ValueFromPipeline)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$Text,

        #  '⋯', '…', 'ຯ', '᠁', '⋮', '⋰', '⋱', '︙'
        [Alias('NoEllipsis')]
        [switch]$WithoutEllipsisWhenTruncated,

        # string length, measured as basic string length ( meaning it's not the number of codepoints / Runes )
        [Alias('Len', 'Max', 'Width', 'Cols', 'Columns')]
        [int]$MaxLength = 120,


        # Should inline whitespace be merged before counting lenght?
        [switch]$AutoFlattenNewlines,

        # string to be used when the string is longer than the limit. this is not taken into account when testing length
        [Alias('EllipsisString')]
        [ArgumentCompletions(
            '␀', '␠', '␊',
            '⋯', '…', 'ຯ', '᠁', '⋮', '⋰', '⋱', '︙')]
        [string]$ReplacementString = '…' # ⋱' # '…'
    )
    begin {
        # $PSBoundParameters  | Json -Compress
        #     | Write-debug # | write-host -fore 'salmon' -bg 'gray10'
    }
    process {
        foreach($curLine in $Text) {
            $actualStrLen = ( $curLine )?.Length ?? 0
            if( $actualStrLen -le $MaxLength ) {
                $CurLine
                continue
            }
            if($actualStrLen -gt $MaxLength) {
                [string]$render_short =
                    $curLine.Substring(0, $MaxLength)

                if(-not $WithoutEllipsisWhenTruncated) {
                    $render_short += $ReplacementString
                }
                    #  + $ReplacementString

                $render_short
                continue
            }
            throw 'ShouldNeverReachException'
        }

    }
    end {}
}


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


function Bintils.Common.Format.WhenContainsSpaces-FormatQuotes {
    <#
    .SYNOPSIS
        useful if you want to quote only when spaces exist
    #>
    [Alias(
        'Bintils.WhenContainsSpaces-FormatQuotes'
    )]
        param(
            [string]$Text,
            [switch]$DoubleQuote
        )
        $hasSpaces = $Text -match ' '
        $hasSingle = $Text -match "[']+"
        $hasDouble = $Text -match '["]+'

        $splat = @{}
        if($DoubleQuote) {
            $splat.DoubleQuote = $True
        } else {
            $splat.SingleQuote = $True
        }

        $hasSpaces ? (
            Join-String -in $Text @splat
        ) : $Text
}
function Bintils.Common.Parse.Filter-FirstNonBlank {
    <#
    .synopsis
        return first string in a list of text, ensure result is a scalar. might work for no-text
    .EXAMPLE
        > Bintils.Common.Parse.Filter-FirstNonBlank -InputText '','cat', 'dog'

            'cat'

    #>
    [OutputType('System.String')]
    param(
        [Parameter()]
        [Alias('Lines', 'Text', 'InputText', 'In')]
        [object[]] $InputObject,

        # any blanks should be skipped, else just empty strings ?
        [switch]$NoIgnoreWhitespace
    )
    if(-not $NoIgnoreWhitespace ) {
        $InputObject | ?{ ($_)?.ToString().Length -gt 0 } | Select -First 1
        return
    }
    $InputObject | ?{ -not [String]::IsNullOrWhiteSpace( $_ ) } | Select -First 1
    return
}


function Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize {
    <#
    .synopsis
        gets header sizes for a fixed-column text outputs
    .NOTES
        original snippet was
            [regex]::Split( $stdout[0], '\s{3,}') | Join.UL
    .example
        # main entry point:
        > Bintils.Common.Parse.FixedWidthColumns -InputText $data

        # else
        > Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize -InputText $data
        > Bintils.Common.Parse.FixedWidthColumns
    .example
        > $header = 'Goat  Name            Id        Region                Kind     Ears'
        > Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize -InputText $header | ft

            Name       Index Width Position
            ----       ----- ----- --------
            Goat  Name     0    22        0
            Id            22    10        1
            Region        32    22        2
            Kind          54     9        3
            Ears          63     4        4

    .EXAMPLE
        Bintils.Common.ParseFixedWidth.HeaderNames -InputText $stdout[0] | ft * -AutoSize
        VERBOSE: KEY NAME; LOCAL_VALUE;

        Name        StartAt EndAt Index DisplayWhitespace DisplayFullTextWhitespace
        ----        ------- ----- ----- ----------------- -------------------------
        KEY NAME          0     8     0 KEY␠NAME          KEY␠NAME␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠LOCAL_VALUE␠␠␠␠␠␠␠␠
        LOCAL_VALUE       0    11     1 LOCAL_VALUE       KEY␠NAME␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠LOCAL_VALUE␠␠␠␠␠␠␠␠
                          0     0     2                   KEY␠NAME␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠␠LOCAL_VALUE␠␠␠␠␠␠␠␠
    .LINK
        Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize
    .LINK
        Bintils.Common.Parse.FixedWidthColumns.GetRows
    .LINK
        Bintils.Common.Parse.FixedWidthColumns
    #>
    [Outputtype(
        'ParsedFixedWidthColumnSchema[]',
        'object[]'
    )]
    [CmdletBinding()]
    param(
        [Alias('Line', 'Text', 'Contents')]
        [Parameter(Mandatory, Position=0)]
        [object[]]$InputText,

        [Parameter()]
        [int]$MinWidthDelim = 3,

        [Parameter()]
        [ArgumentCompletions(
            '@{ AlwaysTrimNames = $false }'
        )]
        [hashtable]$Options = @{}
    )
    $Config = nin.MergeHash -OtherHash ($Options ?? @{}) -BaseHash @{
        AlwaysTrimNames = $true
        DropBlankCrumbs = $true
    }
    # Detect widths for parsing

$regex = @{
    ColumnName = @'
(?x)
    (?<Item>.*?)
    ($ | [ ]{size,} )
'@ -replace 'size', $MinWidthDelim
}
    # default to first line if lines
    'Multiple lines passed, assuming first line is columns' | write-verbose
    # $Scalar = @( $InputText )[0]
    # $firstNonBlank = $InputText | ?{ $_.Length -gt 0 } | Select -first 1
    $firstNonBlank = Bintils.Common.Parse.Filter-FirstNonBlank -InputObject $InputText
    # $

    $foundIndex = [regex]::matches( $firstNonBlank, $Regex.ColumnName )

    # ( $foundIndex = [regex]::Matches($Header, $reColumn )  )
    #     |Ft -AutoSize
    #     | write-host

    class ParsedFixedWidthColumnSchema {
        [string]$Name = ''
        # [int]$StartAt = 0
        # [int]$EndAt = 0 # end at is also total width
        [int]$Index = 0
        [int]$Width = 0
        [int]$Position = 0
    }

    $position = 0
    $columns = @(
    foreach($fi in @( $foundIndex )) {
        # if($fi.Width -eq 0) { continue }
        # if($Config.DropBlankCrumbs) {
        #     if($fi.Length -eq 0) { continue } # less easy because of name
        # }
        $parsed = [ParsedFixedWidthColumnSchema]@{
            Name = $fi.Value | Join-String
            Index = $fi.Index
            Width = $fi.Length
            Position = ($Position++)
            # DisplayWhitespace =  $fi.Value # | Dotils.Format.Show.Space
        }
        if( $Config.AlwaysTrimNames ) {
            $parsed.Name = $Parsed.Name.Trim()
        }
        $parsed
    })

    $selected = @(
        $Config.DropBlankCrumbs ?
            $columns.where({$_.Index -ne -1 -and  $_.Width -gt 0 }) :
            $columns )

    return $selected  # | ?{ $_.Width -gt 0}
}
function Bintils.Common.Parse.FixedWidthColumns.GetRows {
    <#
    .SYNOPSIS
        parses rows using known column sizes
    .NOTES

    .EXAMPLE
        # either mode is okay
        Bintils.Common.Parse.FixedWidthColumns.GetRows -InputText $data -HeaderData $data
        Bintils.Common.Parse.FixedWidthColumns.GetRows -InputText $data -HeaderData $data[0]
    .EXAMPLE
        $ll = lucid config --no-trim --effective
        ( $schema = bintils.common.parse.FixedWidthColumns.GetHeaderSize -InputText $ll )
        Bintils.Common.Parse.FixedWidthColumns.GetRows -InputText @( $ll ) -HeaderData $schema|ft

    .LINK
        Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize
    .LINK
        Bintils.Common.Parse.FixedWidthColumns.GetRows
    .LINK
        Bintils.Common.Parse.FixedWidthColumns
    #>
    param(
        # lines of text. optionally including the header rows, which will be filtred out
        # remove binding, for a better UX
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        # [ValidateNotNullOrEmpty()] # it validates per element, breaking my intended purpose
        [Alias('Lines', 'InputObject', 'Text', 'Str', 'In', 'Data', 'Rows', 'Records', 'Contents')]
        [string[]]$InputText,

        # either schema from .GetHeaderSize, else rows of text. if multiple lines, assume just the first line is the header
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompletions(
            '$schema',
            '( Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize -InputText $data[0] )'
        )]
        [object[]]$HeaderData,

        [switch]$NoTrimValues
    )

    class ParsedFixedWidthColumnData {
        [string]$Name = ''
        [string]$Text = ''
        [int]$ColumnId = 0
        [int]$RowId = 0
    }

    # 'refactor: accept type if contains all properties: Index, Width, Name, Position?'
    $firstHeader = Bintils.Common.Parse.Filter-FirstNonBlank -InputObject $HeaderData

    # if (  @($HeaderData)[0] -is 'string' ) {
    if( $FirstHeader -is 'string' ){
        write-debug -debug 'auto converting text to dimensions'
        write-verbose -verb 'auto converting text to dimensions'
        # $schema = Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize -InputText $HeaderData
        $schema = Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize -InputText $firstHeader
    } else {
        $schema = $HeaderData
    }

    # maybe invalid args, else PSCO
    if ( @( $schema )[0].GetType().Name -ne 'ParsedFixedWidthColumnSchema' ) {
    # if ( @( $HeaderData )[0].GetType().Name -ne 'ParsedFixedWidthColumnSchema' ) {
        'WarnOnly: FirstHeaderDataElement was not of type [ParsedFixedWidthColumnSchema]'
            | write-verbose
    }

    [string]$firstColName = @( $schema )[0].Name
    if( [string]::IsNullOrWhiteSpace( $firstColName ) ) {
        $Schema | Select -first 1 | COnvertTo-Json -compress | Write-debug
        throw "InvalidArgumentException, No 'Name' in schema's first column!'"

    }
    $rowId = 0
    $colId = 0
    foreach($Line in @($InputText) ) {
        $colId = 0
        if( $Line.StartsWith( $firstColName )  ) { continue }

        foreach($col in $schema ) {
            $At, $Width = $col.Index, $Col.Width

            # replace this with [Math]::Clamp to ensure save substr
            $Text = $Line.
                        PadRight( $at + $Width, ' ').
                        Substring( $at, $Width )
            $parsed = [ParsedFixedWidthColumnData]@{
                Name = $col.Name
                Text = $Text
                ColumnId = ( $colId++ )
                RowId = $RowId
            }
            if(-not $NoTrimValues ) {
                $parsed.Text = $parsed.Text.Trim()
            }
            $parsed
        }
        $rowId++
    }
    return
}

function Bintils.Common.Parse.FixedWidthColumns {
    <#
    .synopsis
        entry point to gets the header sizes, and the final table rows in one go
    .EXAMPLE
        # future: clean up example to use argument keys
        $meta = [ordered]@{}
        $res = Bintils.Common.Parse.FixedWidthColumns -InputText ( lucid config --no-trim --local )
        $meta = @{}
        $res | Group RowId | %{
            $Key   =  $_.group | ? Name -match 'KEY NAME'    | % Text
            $Value =  $_.group | ? Name -match 'LOCAL_VALUE' | % Text
            $meta[ $key ] = $Value
        }
        $Meta | ft -AutoSize
        # output

            Name                           Value
            ----                           -----
            ObjectScheduler.MaxUploadRate  10MB
            ObjectScheduler.MaxDownloadRa… 300MB
            FileSystem.MountPointWindows   J:\lucid_root

            DataCache.Location             J:\lucid_cache
    .example
        Bintils.Common.Parse.FixedWidthColumns -InputText ( lucid config --no-trim --local ) | %{
            $_ | Select -exc *Id
        } | Json

        # out
        [{"Name":"KEY NAME","Text":"DataCache.Location"},{"Name":"LOCAL_VALUE","Text":"J:\\lucid_cache"},{"Name":"KEY NAME","Text":"FileSystem.MountPointWindows"},{"Name":"LOCAL_VALUE","Text":"J:\\lucid_root"},{"Name":"KEY NAME","Text":"ObjectScheduler.MaxDownloadRate"},{"Name":"LOCAL_VALUE","Text":"300MB"},{"Name":"KEY NAME","Text":"ObjectScheduler.MaxUploadRate"},{"Name":"LOCAL_VALUE","Text":"10MB"},{"Name":"KEY NAME","Text":""},{"Name":"LOCAL_VALUE","Text":""}]

    .LINK
        Bintils.Common.Parse.FixedWidthColumns.GetHeaderSize
    .LINK
        Bintils.Common.Parse.FixedWidthColumns.GetRows
    .LINK
        Bintils.Common.Parse.FixedWidthColumns

    #>
    param(
        # Lines of text. auto detect schema using first row
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        # remove binding validation, for a better UX
        # [ValidateNotNullOrEmpty()] # it validates per element, breaking my intended purpose

        [Alias('Lines', 'InputObject', 'Text', 'Str', 'In', 'Data', 'Rows', 'Records', 'Contents')]
        [ArgumentCompletions(
            '( lucid config --no-trim --effective )',
            '( lucid config --no-trim --local )'
        )]
        [string[]]$InputText,

        [ValidateScript({throw 'nyi: make easy casting to hash for unique names'})]
        [bool]$AsHashtable
    )

    $header =  Bintils.Common.Parse.Filter-FirstNonBlank -InputObject $InputText
    # $header =  $InputText | Select -first 1
    $rows =  $InputText  | Select -skip 1

    Bintils.Common.Parse.FixedWidthColumns.GetRows -InputText $Rows -HeaderData $Header
    return

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

function Bintils.Common.OutJson {
    <#
    .SYNOPSIS
        Sugar to pipe using different views, usually json
    .EXAMPLE
        docker inspect $containerName (Bintils.Docker.NewTemplateString Json.All)
            | Bintils.Common.OutJson Code.Stdin
    #>
    [CmdletBinding()]
    param(
        [ValidateSet(
            'Temp',
            'Code.Stdin',
            'Bat'
        )]
        [Parameter(Mandatory, Position=0)]
        [string]$OutputMode,


        [Parameter()]
        $Destination,

        [Parameter()]
        [string]$TempDestination,

        # pass through JQ or Convertfrom/To
        [Alias('NoExpand', 'Minify', 'Min', 'SkipJqExpand')]
        [switch]$WithoutAutoExpand,

        [switch]$AutoOpenCode,

        [Alias('InputObject', 'Text', 'InText', 'InStr', 'Str')]
        [Parameter(mandatory, ValueFromPipeline)]
        [string[]]
        $Lines
    )
    begin {
        [List[Object]]$Items = @()
    }
    process {
        foreach($curLine in $Lines) { $Items.Add( $curLine )}
    }
    end {

        [List[Object]]$BinArgs = @()
        [string]$Contents = ''

        if( $WithoutAutoExpand ){
            $Contents = $Items | Join-String -sep  "`n"
        } else {
            'auto expanding with jq else pwsh' | write-verbose
            if( (Bintils.Common.Test-UserHasNativeCommand -CommandName 'jq')) {
                $Contents = $Contents | jq #@('.')
            }
            else {
                $Contents = $Contents | ConvertFrom-Json -depth 12 | ConvertTo-Json
            }
        }

        switch($OutputMode) {
            'Temp' {
                if( $PSBoundParameters.ContainsKey('Destination')) {
                    $DestPath = $Destination
                } elseif ( $PSBoundParameters.ContainsKey('TempDestination')) {
                    $DestPath =
                        Join-Path Temp: 'Bintils.OutJson' $TempDestination
                } else {
                    $DestPath = Join-path Temp: 'lastOut.json'
                }
                $contents | Set-Content -path $DestPath
                'wrote: {0}' -f $DestPath
                    | Bintils.Common.Write-DimText | Write-Information -infa 'Continue'

                if($AutoOpenCode) {
                    $binArgs = @(
                        '--goto' ; Get-Item $DestPath )
                    & code @binArgs
                }
                break
            }
            'Code.Stdin' {
                $binArgs = '-'
                $Contents | code @binArgs
                break
            }
            'Bat' {
                $binArgs.AddRange(@(
                    '-l'
                    'json'
                    '--force-colorization' # Alias for '--decorations=always --color=always'.
                    # '--color', 'always'
                    '--file-name', 'Bintils.Common.OutJson.json'
                    if($false) {
                        '--wrap', 'auto'
                        '--wrap', 'never'
                        '--wrap', $count
                    }
                ))
                $Contents | bat @binArgs
                break
            }
            default {
                throw "UnhandledOutputMode: $OutputMode"
            }
        }
    }

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
