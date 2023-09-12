# textractor_websocket

## Description

An extension for [Textractor](https://github.com/Artikash/Textractor) written in
Rust that opens a WebSocket locally on port `6677` and sends the text from
Textractor to all the connected clients.

A WebSocket client such as
[texthooker-ui](https://github.com/Renji-XD/texthooker-ui)
can stream the text by the server and display it to your browser.

## Build

If you want to build the DLL yourself, you can follow the instructions below.
Otherwise, skip to the [Install](#install) section.

Ensure you have Rust installed. The installation instructions can be found
[here](https://www.rust-lang.org/learn/get-started). Then you can build the
DLL with

```bash
# For x64
cargo build --release --target i686-pc-windows-gnu

# For x86
cargo build --release --target x86_64-pc-windows-gnu
```

## Install

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

<details><summary>Expected file structure</summary>

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

</details>

## Usage

After installing the extension, when you start Textractor and have selected a
text thread, Textractor will automatically start the server at
`ws://localhost:6677`

You will need a WebSocket client such as
[texthooker-ui](https://github.com/Renji-XD/texthooker-ui)
to stream the text and display it to your browser
