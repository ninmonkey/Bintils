using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
# using namespace Sytem.Text.RegularExpressions

class NamedRegex {
    [string]$Name
    [string]$Pattern
    [Text.RegularExpressions.RegexOptions]$RegexOptions = ('ignoreCase,IgnorePatternWhitespace')

    [Regex] ToRegex() {
        return [Regex]::new($This.Pattern, $this.Options )
    }
    [string] ToString() { return $this.Pattern }
}

function DefaultRegexMapping {
    # build sources
    [OutputType( [NamedRegex] )]
    param()
    @(
        [NamedRegex]@{
            Name = 'Email'
            Pattern = '^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$'
        }
        [NamedRegex]@{
            Name = 'Phone'
            Pattern = '^\d{3}-\d{3}-\d{4}$'
        }
        [NamedRegex]@{
            Name = 'Url'
            Pattern = '^(https?|ftp)://[^\s/$.?#].[^\s]*$'
        }
        [NamedRegex]@{
            Name = 'IP'
            Pattern = '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        }
    )
}


class NamedRegexArgCompleter  : IArgumentCompleter {
    NamedRegexArgCompleter ( ) { }
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [CommandAst] $commandAst,
        [IDictionary] $fakeBoundParameters) {

        $query = completerTest.FindNamedRegex
        [List[NamedRegex]]$query = @(
            DefaultRegexMapping
            | ?{ $_.Name -match [Regex]::Escape( $wordToComplete ) }
        )

        [List[CompletionResult]]$completions = @(
            $query | %{
                $curNamed = $_
                $toolip = 'tooltip'
                [CompletionResult]::new(
                    <# completionText: #> $curNamed.Name,
                    <# listItemText: #> $curNamed.Name,
                    <# resultType: #> [CompletionResultType]::ParameterValue,
                    <# toolTip: #> $toolTip)
            }
        )
        wait-debugger

        return $completions
    }
}

class NamedRegexCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
# class NamedRegexCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [NamedRegexCompletionsAttribute]::new()
        Pwsh> [NamedRegexCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    # [hashtable]$Options = @{}
    NamedRegexCompletionsAttribute() { }

    [IArgumentCompleter] Create() {
        return [NamedRegexArgCompleter]::new()
    }
}

function completerTest.tryAttribute {
    param($Template, $Params)
    switch($Template) {
        # 'New.Name' {
        #     [NamedRegexCompletionsAttribute]::new( $Params )
        # }
        default {
            [NamedRegexCompletionsAttribute]::new()
        }
    }
}
function completerTest.FindNamedRegex {
    # returns regex that matches names. autocompletes valid keys
    [CmdletBinding()]
    [OutputType( [NamedRegex] )]
    param(
        # [Parameter(Mandatory)]
        # [NamedRegexCompletionsAttribute()]
        [ArgumentCompleter(  [NamedRegexArgCompleter] )]
        [string]$RegexName
    )

    return $RegexName
    # [List[Object]]$query = DefaultRegexMapping | ?{ $_.Name -match [Regex]::Escape( $RegexName ) }
    # return $query
}

Export-ModuleMember -Function @( 'completerTest.*') -Alias  @( 'completerTest.*')
gcm 'completerTest.*' |Ft -auto

@'
Commands to try:

> completerTest.FindNamedRegex -RegexName 'ip'
> completerTest.FindNamedRegex -RegexName <menuComplete|tab>
'@ | write-host -fore blue
