# dotfiles

## SSH鍵

```sh
ssh-keygen -t ed25519
```

公開鍵をGitHubにAuthentication KeyとSigning Keyの両方で登録し、`git/allowed_signers`にも追加する。

## Linux（Ubuntu/Debian）

```sh
sudo apt-get update
sudo apt-get install -y git curl
git clone git@github.com:HikaruIwama/dotfiles.git
cd dotfiles
./install.sh
```

## Windows

開発者モードを有効にする。

```powershell
winget install --id Git.Git -e
git clone git@github.com:HikaruIwama/dotfiles.git
cd dotfiles
powershell -ExecutionPolicy Bypass -File install.ps1
```
