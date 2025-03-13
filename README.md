# apt-repo-test

## How to create repo

1. Create conf/distributions as follows:
```
Origin: Ubuntu
Label: Ubuntu-All
Suite: stable
Codename: jammy
Version: 22.04
Architectures: amd64
Components: main
Description: Test apt repostiroy
#Update: debian non-US security
SignWith: yes
```
2. Add deb pacakge into repository
```
reprepro -V --basedir . --component main --priority 0 includedeb jammy ./_work/hello_2.10-2ubuntu4_amd64.deb
```

## How to add this repo

curl -LSfs https://github.com/yhamamachi/apt-repo-test/raw/refs/heads/jammy/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/yhamamachi/apt-repo-test/jammy jammy main"
sudo apt update

## How to check repository is enabled

```
-> % LANG=C apt-cache policy hello
hello:
  Installed: (none)
  Candidate: 2.10-2ubuntu4
  Version table:
     2.10-2ubuntu4 500
        500 http://jp.archive.ubuntu.com/ubuntu jammy/main amd64 Packages
        500 https://raw.githubusercontent.com/yhamamachi/apt-repo-test/jammy jammy/main amd64 Packages
```

## Package upgrade check

myhello package is created by create_test_deb.sh
1. Create package and upload repository.
   - `create_test_deb.sh`
   - `reprepro -V --basedir . --component main --priority 0 includedeb jammy ./work.deb`
2. Change version of package on top of script file.
   - `PKG_VER="0.01-3+deb9u1"` will be changed
3. Regenerate package and upload repository.
   - `create_test_deb.sh`
   - `reprepro -V --basedir . --component main --priority 0 includedeb jammy ./work.deb`
```
-> % LANG=C apt-cache policy myhello
myhello:
  Installed: 0.01-2+deb9u1
  Candidate: 0.01-3+deb9u1
  Version table:
     0.01-3+deb9u1 500
        500 https://raw.githubusercontent.com/yhamamachi/apt-repo-test/jammy jammy/main amd64 Packages
 *** 0.01-2+deb9u1 100
```

## How to check package list in reposotory

```
-> % reprepro list jammy
jammy|main|amd64: hello 2.10-2ubuntu4
jammy|main|amd64: myhello 0.01-5+deb9u1
```

