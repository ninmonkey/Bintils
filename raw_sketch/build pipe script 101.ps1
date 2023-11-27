err -clear
hr 1 -fg gray40
get-module Pipescript* | CountOf 'slow => Starting Pipes: '
hr 1 -fg gray40

function FixNativeCommandExample {
    param(
        [ArgumentCompletions(
            'gh', 'git', 'jq', 'code',
            'python', 'py'
        )]
        [string]$CommandName
    )
    Set-Alias 'gh' -value $executionContext.SessionState.InvokeCommand.GetCommand('gh', 'Application')
}



# return
# Get-module Pipescript

# if($slow) {

#     hr 1
#     Remove-Module Pipescript*
#     get-module Pipescript | CountOf 'begin pipes: '
#     hr 1
#     Import-Module -force -PassThru Pipescript
# } else {
#     get-module Pipescript | CountOf 'slow => Starting Pipes: '
#     hr 1
#     Remove-Module Pipescript*
#     get-module Pipescript* | CountOf 'StartingPipes: '
#     import-module pipescript -Passthru
# }

# Import-Module Pipescript -PassThru

# Import-Module -force -PassThru 'H:\data\2023\pwsh\my🍴\PipeScript\PipeScript.psm1'

# $find = Import-PipeScript -ScriptBlock {
$sb1 = {
    # function Get-MyProcess
    # {
        <#
        .Synopsis
            Gets My Process
        .Description
            Gets the current process
        .Example
            Get-MyProcess
        .Link
            Get-Process
        #>
        # [inherit(Abstract,ExcludeParameter='Name','ID','InputObject','IncludeUserName')]
        # [inherit('Get-Process',Abstract,ExcludeParameter='Name','ID','InputObject','IncludeUserName')]
        param()

        $PSBoundParameters | ft | out-string | write-host -back 'darkblue'

        # return & $baseCommand -id $pid @PSBoundParameters
    #  }
 }
$sb2 = {
    # function Get-MyProcess
        <#
        .Synopsis
            Gets My Process
        .Description
            Gets the current process
        .Example
            Get-MyProcess
        .Link
            Get-Process
        #>
        # [inherit(Abstract,ExcludeParameter='Name','ID','InputObject','IncludeUserName')]
        [inherit('Get-Process',Abstract,ExcludeParameter='Name','ID','InputObject','IncludeUserName')]
        [inherit(Abstract)]
        param()

        $PSBoundParameters | ft | out-string | write-host -back 'darkblue'
        return 'wip'

        # return & $baseCommand -id $pid @PSBoundParameters
 }
#  | bps

.> $sb2

{
    [inherit('Get-Process',Abstract,ExcludeParameter='Name','ID','InputObject','IncludeUserName')]
    param() process { $psBoundParameters }
}.Transpile() | OutNull 'transpiled => '



{
    [inherit("gh",Overload)]
    param()
    begin { "ABOUT TO CALL GH"}
    end { "JUST CALLED GH" }
}.Transpile()