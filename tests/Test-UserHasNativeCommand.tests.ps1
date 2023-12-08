BeforeAll {
    Import-Module Bintils -force -passthru
        | Join-String { $_.Name, $_.Version -join ' = ' }
        | write-host -fore yellow
}

Describe 'Bintils.Has-NativeCmd [Bintils.Common.Test-UserHasNativeCommand]' -Tag 'IsSlow', 'SlowBecause.UsesGetCommand' {
    # it '<CommandName> Exists <Expected> <ExpectedType>, is <Actual>' -ForEach @(
    it '<CommandName> is <Expected> and type: <ExpectedType>' -ForEach @(
        @{
            CommandName = 'pwsh'
            Expected = $true
            ExpectedType = [bool]
        }
        @{
            CommandName = 'pwsh_somefakename'
            Expected = $false
            ExpectedType = [bool]
        }
    ) {
        # Bintils.Has-NativeCmd -
        $Actual = Bintils.Has-NativeCmd $CommandName
        $Actual | Should -BeOfType $ExpectedType
        $Actual | SHould -BeExactly $Expected -Because 'It better be installed, this is Pwsh7'
    }
}
Describe 'Bintils.Missing-NativeCmd' -Tag 'IsSlow', 'SlowBecause.UsesGetCommand' {
     it '<CommandName> is <Expected> and type: <ExpectedType>' -ForEach @(
        @{
            CommandName = 'pwsh'
            Expected = $false
            ExpectedType = [bool]
        }
        @{
            CommandName = 'pwsh_somefakename'
            Expected = $true
            ExpectedType = [bool]
        }
    ) {
        # Bintils.Has-NativeCmd -
        $Actual = Bintils.Missing-NativeCmd $CommandName
        $Actual | Should -BeOfType $ExpectedType
        $Actual | SHould -BeExactly $Expected -Because 'It better be installed, this is Pwsh7'
    }
}
# Bintils.Missing-NativeCmd rg
# Bintils.Missing-NativeCmd rg_missing'
