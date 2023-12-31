$Error.clear()

Import-Module -force -passthru (Join-Path $PSScriptRoot './template-namedRegexCompleter.psm1') | Ft

completerTest.FindNamedRegex -RegexName 'ip'
# completerTest.FindNamedRegex -RegexName












# delete

# class LucidLogNameCompleter : IArgumentCompleter {

#     # hidden [hashtable]$Options = @{
#         # CompleteAs = 'Name'
#     # }
#     # hidden [string]$CompleteAs = 'Name'
#     # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
#     # LucidLogNameCompleter([int] $from, [int] $to, [int] $step) {
#     LucidLogNameCompleter( ) { }
#     [IEnumerable[CompletionResult]] CompleteArgument(
#         [string] $CommandName,
#         [string] $parameterName,
#         [string] $wordToComplete,
#         [CommandAst] $commandAst,
#         [IDictionary] $fakeBoundParameters) {

#         [List[CompletionResult]]$found = @(
#                 $records = lucid log --list --json
#                     | ConvertFrom-Json -AsHashtable
#                     | % Keys | Sort-Object -Unique | %{
#                         New.Cr -ListItemText $_ -CompletionText $_ -ResultType ParameterValue -Tooltip "mode here"
#                     }

#                 # (Bintils.LucidLink.Parse.Logs -AsObject -infa Ignore).Keys | Sort-Object -Unique
#                 # | ?{ $_ -match $wordToComplete }
#             ) | ?{
#                  $_.ListItemText -match $WordToComplete
#              }
#         $found | ConvertTo-Json | Add-Content 'temp:\last.log' -ea 'continue'
#         return $found
#     }
# }
