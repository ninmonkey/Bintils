- regex 'event' parsing mode, to auto parse `wsl --help`
- `--distro <name>` should complete existing names
- regex to parse `wsl --help` to build the completions, not manually
- why does it always complete one named `CompletionText`, verify with a fresh debug session
- if previous token is the suggested completion, do not return that completer
  - else `--list<tab> <tab> <tab>` is a never-ending chain
- nested commands/heirarchal completions that depend on the previous one
    --distro 'ubuntu'
    --distro 'docker-desktop-data'

    this is where completionType == parameter, or parametervalue is used


## docs /refs
- [working across filesytems](https://learn.microsoft.com/en-us/windows/wsl/filesystems)
- [Mount a Linux disk in WSL 2](https://learn.microsoft.com/en-us/windows/wsl/wsl2-mount-disk)
- [Using USB Devices](https://learn.microsoft.com/en-us/windows/wsl/connect-usb)
- [manage disk space](https://learn.microsoft.com/en-us/windows/wsl/disk-space)
- [Import any Linux distro](https://learn.microsoft.com/en-us/windows/wsl/use-custom-distro)
- [accessing a WSL2 distro from the LAN](https://learn.microsoft.com/en-us/windows/wsl/networking)
  - using [netsh-interface-portproxy](https://learn.microsoft.com/en-us/windows-server/networking/technologies/netsh/netsh-interface-portproxy)