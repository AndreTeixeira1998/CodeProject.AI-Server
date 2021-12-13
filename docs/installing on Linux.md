# Setting up the development environment for Linux

1. Install WSL by opening a PowerShell terming and typing
`wsl --install`

2. Ensure VS Code is installed

3. Install the [VS Code Remote Development extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

4. Install the .NET SDK:

   1. Add the signing keys and package repository
       ```sh
      wget https://packages.microsoft.com/config/ubuntu/21.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
       sudo dpkg -i packages-microsoft-prod.deb
       rm packages-microsoft-prod.deb
       ```

   2. Install the .NET SDK
        ```sh
        sudo apt-get update; \
        sudo apt-get install -y apt-transport-https && \
        sudo apt-get update && \
        sudo apt-get install -y dotnet-sdk-5.0
        ```
        If you just want the runtime (which the SDK includes), use
        ```sh
        sudo apt-get update; \
        sudo apt-get install -y apt-transport-https && \
        sudo apt-get update && \
        sudo apt-get install -y aspnetcore-runtime-5.0
        ```
5. Navigate to your repo and launch VS Code
    ```
    cd /mnt/c/Dev/CodeProject/CodeProject.AI
    ````

6. Re-open in WSL by hitting `Ctrl+Shift P` for the command pallete, select "Remote-WSL: Reopen Folder in WSL" and hit enter.

You are now coding against the existing Windows repository, but using a remote connection to the WSL system from within VS Code. From within this current environment it's all Linux.