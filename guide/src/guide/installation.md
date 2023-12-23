# Installation

Pre-compiled binaries are available in the
[Releases](https://github.com/kuroahna/textractor_websocket/releases) page

1. Download, unzip, and copy the
   [x86 DLL](https://github.com/kuroahna/textractor_websocket/releases/latest/download/textractor_websocket_x86.zip)
   file into your `Textractor/x86` folder
2. Download, unzip, and copy the
   [x64 DLL](https://github.com/kuroahna/textractor_websocket/releases/latest/download/textractor_websocket_x64.zip)
   file into your `Textractor/x64` folder
3. Open up `Textractor/x86/Textractor.exe`, click `Extensions`, right click
   inside the `Extensions` dialog box, click `Add extension`, change the file
   extension in the file picker dialog from `*.xdll` to `*.dll`, and select
   `textractor_websocket_x86.dll` inside the `Textractor/x86` folder from Step
   1.
4. Open up `Textractor/x64/Textractor.exe`, click `Extensions`, right click
   inside the `Extensions` dialog box, click `Add extension`, change the file
   extension in the file picker dialog from `*.xdll` to `*.dll`, and select
   `textractor_websocket_x64.dll` inside the `Textractor/x64` folder from Step
   2.

Expected file structure

```
Textractor
├── x64
    └── Textractor.exe
    └── textractor_websocket_x64.dll
    └── ...
├── x86
    └── Textractor.exe
    └── textractor_websocket_x86.dll
    └── ...
```
