# CerealRTOS
Real-time Operating system 

## Debugging in VSCODE
- Install TI Embedded Debug Extension
- Install Cortex Debug Extension
- Run automatic dependency downloader on left side
- Perchance run this on Mac 
    - xattr -rd com.apple.quarantine ~/Library/Application\ Support/Texas\ Instruments/ti-embedded-debug/
- Use this to find your version 
    - ls ~/Library/Application\ Support/Texas\ Instruments/ti-embedded-debug/openocd/
- Use this template for .vscode/launch.json 
```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug MSPM0 LaunchPad",
            "cwd": "${workspaceFolder}",
            "executable": "${workspaceFolder}/build/your_output_file.out", 
            "request": "launch",
            "type": "cortex-debug",
            "servertype": "openocd",
            "runToEntryPoint": "main",
            "showDevDebugOutput": "none",
            "deviceName": "MSPM0G3507", 
            "configFiles": [
                "interface/xds110.cfg",
                "board/ti_mspm0_launchpad.cfg"
            ],
            "searchDir": [
                "/Users/YOUR_MAC_USERNAME/Library/Application Support/Texas Instruments/ti-embedded-debug/openocd/YOUR_VERSION_FOLDER/share/openocd/scripts"
            ]
        }
    ]
}
```