BeforeAll {
    Import-Module -ea 'stop' 'Bintils' -force -passthru  | write-host -fore 'blue'
}
Describe 'Bintils.Common.Parse.FixedWidthColumns' {
    it '"<Label>" is <Expected> <' -forEach @(
        @{
            RawLines = @(
@'
Goat  Name            Id        Region                Kind     Ears
Billy the Kid         4         Roof of your car      Alpine   tiny
James Van Der Bleat   6         Petting zoo           Nubian   long, floppy
the G.O.A.T. goat                                              the good kind
Pickles               49                                       mia
the goat              42        East
'@ -split '\r?\n'
            )
        }
    )  {
        $HeaderLine = $RawLines[0]
        $Data = $RawLines | Select -skip 1

        $schema = Bintils.Common.Parse.FixedWidthColumns.GetHeaderSizes $HeaderLine
            | write-host -fore 'orange'

        # 'header as raw text'
        Bintils.Common.Parse.FixedWidthColumns.GetRows -InputText $Data -HeaderData $HeaderLine
            | write-host -fore 'orange'

        # 'header as schema'
        Bintils.Common.Parse.FixedWidthColumns.GetRows -InputText $Data -HeaderData $schema
            | write-host -fore 'orange'

        Set-ItResult -Pending -Because 'double check hard coded values'
        write-host 'check out the details' -fore 'purple'




        # Bintils.Common.Format-ShortenString -Text $InObj -MaxLength $MaxLen
    }

}
