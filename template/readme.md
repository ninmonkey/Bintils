## About

Examples of error handling around invoking native commands, when they are missing

- Source: [NativeCommandErrorHandling.ps1](./NativeCommandErrorHandling.ps1)

## Examples

Here's a few examples to demonstrate the differences

```ps1
FastGetNativeCommand 'pwsh'
FastGetNativeCommand 'badname'

GetNativeCommand 'winget'

InvokeBinCommand 'winget' '--help'
InvokeBinCommand 'code' @('-g', $PROFILE.CurrentUserAllHosts)

ExampleStop pwsh
ExampleStop badname

ExampleIgnore Pwsh
ExampleIgnore badname

ExampleStop pwsh
ExampleStop badname

GetNativeCommand 'bad' -ea 'Stop'
GetNativeCommand 'bad' -ea 'ignore'
GetNativeCommand 'bad' -Mandatory
```