# Import-Module bintils -force -PassThru  | ft

# write-warning 'to do: H:\data\client_bdg\2023.11-bdg-s3-aws-lambda-app\LambUtils.psm1'































'early exit, future wip afterward "{0}:99999"' -f $PSCommandPath | Write-verbose -verbose
return
[Microsoft.PowerShell.Commands.PSPropertyExpression]
$found = (get-date).psobject.properties.where({ $_.name -match 'year' })
$meta = [ordered]@{}
foreach($x in $found){ $meta[ $x.Name ] = $x.Value; }
Bintils.Format-KeyValuePairs $meta -MaxValueLength 10


$found = (get-date).psobject.properties.where({ $_.name -match 'year' })
$meta = [ordered]@{}
foreach($x in $found){ $meta[ $x.Name ] = $x.Value; }
Bintils.Format-KeyValuePairs $meta -MaxValueLength 10

hr
$tinfo = get-date | % gettype
$meta2 = [ordered]@{}
$found2 = $tinfo.psobject.properties.Where({$_.name -match 'generic'})
foreach($x in $found2){ $meta2[ $x.Name ] = $x.Value; }
Bintils.Format-KeyValuePairs $meta2

function Bintils.Common.ConvertTo-Hashtable {
    param()
    throw 'left off here, function from picky'
}
