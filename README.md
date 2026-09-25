# dotfiles

## セットアップ

前提：Windowsの開発者モード有効

```powershell
winget install --id Git.Git -e
git clone -c core.symlinks=true git@github.com:HikaruIwama/dotfiles.git
cd dotfiles
winget import -i winget/packages.json
```

新しいターミナルを開き、dotfilesディレクトリで実行する。

```powershell
./install.ps1
```
