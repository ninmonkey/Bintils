using namespace System.Collections.Generic

Function InvokeGrep {
    <#
    .SYNOPSIS
        wraps the native command RipGrep
    #>
    param(
        [string]$Pattern,

        [ArgumentCompletions('Smart', 'IgnoreCase', 'CaseSensitive')]
        [string]$CaseMode,

        [switch]$AsJson,

        [switch]$Version,
        [switch]$WhatIf,
        [switch]$ListTypes
    )

    if($Version) {
        rg --version
        return
    }
    if($ListTypes) {
        rg --type-list
        return
    }

    [List[Object]]$binArgs = @()

    switch($CaseMode){
        'CaseSensitive' {
            $binArgs.Add('--case-sensitive')
        }
        'Smart' {
            $binArgs.Add('--smart-case')
        }
        'IgnoreCase' {
            $binArgs.Add('--ignore-case')
        }
    }

    $binArgs.Add( $Pattern )

    if( $AsJson ) {
        $binArgs.Add('--json')
    }

    # PreviewArgs
    $binArgs -join ' ' | write-host -back 'darkyellow'
    if( $WhatIf ) { return }
    # neither, call with args

    & 'rg' @binArgs



}

InvokeGrep -Pattern 'Function' -CaseMode 'Smart' -AsJson
InvokeGrep -Pattern 'Function' -CaseMode 'Smart' -WhatIf
return
InvokeGrep -Version
