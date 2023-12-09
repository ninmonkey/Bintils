BeforeAll {
    Import-Module -ea 'stop' 'Bintils' -force -passthru  | write-host -fore 'blue'
}
Describe 'Bintils.Commmn.Format.String.Trunc' {
    it '"<Label>" is <Expected> <' -forEach @(
        @{
            Label = 'Max == Len'
            InObj = 'abcd'
            MaxLen = 4
            Expected = 'abcd'
        }
        @{
            Label = 'Max < Len'
            InObj = 'abcd'
            MaxLen = 2
            Expected = 'ab'
        }
        @{
            Label = 'Max > Len'
            InObj = 'abcd'
            MaxLen = 6
            Expected = 'abcd'
        }
    )  {
        Bintils.Common.Format-ShortenString -Text $InObj -MaxLength $MaxLen
    }
    Context 'ParameterBinding' {
        it 'No Args' {
            { 'a', 'bbb' | Bintils.Common.Format-ShortenString } | Should -Not -Throw
        }
        it 'As Positional' {
            { 'a', 'bbb' | Bintils.Common.Format-ShortenString -MaxLength 2 } | Should -Not -Throw
        }

    }
    Context 'Inputs From Pipeline' {
        it 'Inputs From Pipeline' -foreach @(
            @{
                Label = 'PipeSeveral'
                InObj = 'a', 'bbbb', 'cccccc'
                MaxLen = 2
                Expected = 'a', 'bb', 'cc'
            }
        ) {
            $Results = $InObj
                | Bintils.Common.Format-ShortenString -MaxLength $MaxLen -WithoutEllipsisWhenTruncated

            $Results | Should -BeExactly $Expected -because 'manually crafted example'

        }
    }
}

Describe 'Bintils.Common.Format.Whitespace' {
    it -skip 'NYI' {
        Set-ItResult -Pending -Because 'nyi'
    }
}
