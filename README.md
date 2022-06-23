Docker Agent Forwarding Toolkit (daft)
======================================

Daft is a 3-in-1 agent forwarder that provides credentials inside docker containers on OSX.

The concept (and much of the code) has been borrowed from:

* https://github.com/uber-common/docker-ssh-agent-forward
* https://github.com/transifex/docker-gpg-agent-forward

Daft provides 2 fairly straight-forward forwarders:

* ssh-agent
* gpg-agent

The recent Docker Desktop for Mac release 2.2.0.0 already provides built-in functionality to forward your ssh-agent, and you should definitely use that if its all you need and it works for you.

However, the mechanism for forwarding `SSH_AUTH_SOCK` is not configurable, and cannot be used to forward other UNIX sockets (for `S.gpg-agent`, for example). That's where this project steps in.

Additionally, daft also provides a third forwarder that will retrieve credentials stored in OSX Keychain.


Prerequisites:
==============

Daft is written entirely in bash, but takes advantage of advanced features of several standard UNIX utilities (readlink, date, xargs, etc). The OSX variant of these utilities leave much to be desired, so daft expects you to have installed GNU variants of most of these tools.

This guide will get you started:

* https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/

NOTE: The guide asks you to use `--with-default-names` which has since be deprecated from Homebrew.  I have in my startup profile:

```
if [[ "$OSTYPE" =~ "darwin" ]]; then
    # find -L /usr/local/opt -type d -name gnubin
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gnu-indent/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/ed/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gawk/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gnu-which/libexec/gnubin:$PATH"

    export PATH="/usr/local/opt/openssl/bin:$PATH"
    export PATH="/usr/local/sbin:$PATH"

    export COPYFILE_DISABLE=1
fi
```

This script additionally requires `socat`.  Install via Homebrew:

```
$ brew install socat
```

Obviously, you will need Docker.


Install:
========
```
git clone https://github.com/twang817/daft.git
cd daft
make
```

Starting Daft:
==============

```
$ daft start
Forward SSH Agent:     yes
Forward GPG Agent:     yes
Create Keychain Proxy: no

SSH keys forwarded:
4096 SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX user@example.com (RSA)

GPG keys imported:
gpg: keybox '/mnt/gpg/pubring.kbx' created
gpg: /mnt/gpg/trustdb.gpg: trustdb created
gpg: key XXXXXXXXXXXXXXXX: public key "User <user@example.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
gpg: inserting ownertrust of 3
gpg: inserting ownertrust of 3

```

This will start the daft docker container and forward your ssh and gpg agent.

Running your container:
=======================
To use daft, you really just need to add `$(daft mount)` to your run options:

```
$ docker run --rm $(daft mount) python:latest ssh-add -l
4096 SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX user@example.com (RSA)

$ docker run --rm $(daft mount) python:latest gpg -k
/root/.gnupg/pubring.kbx
------------------------
pub   rsa4096 2019-03-07 [C]
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
uid           [ultimate] User <user@example.com>
sub   rsa4096 2019-03-07 [E] [expires: 2020-03-06]
sub   rsa4096 2019-03-07 [S] [expires: 2020-03-06]
sub   rsa4096 2019-03-07 [A] [expires: 2020-03-06]
```

Accessing Keychain:
===================

To access keychain from inside your docker container, you'll need to provide daft what service and accounts you want to allow it to forward:

```
$ KEYCHAIN_SERVICE=myservice KEYCHAIN_ALLOWED=myaccount daft start
Forward SSH Agent:     yes
Forward GPG Agent:     yes
Create Keychain Proxy: yes

Keychain Service: myservice
Keychain Account: myaccount

SSH keys forwarded:
4096 SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX user@example.com (RSA)

GPG keys imported:
gpg: key XXXXXXXXXXXXXXXX: "User <user@example.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1

$ echo myaccount | docker run --rm -i $(daft mount) alpine/socat UNIX-CONNECT:/keychain/keychain.sock -
foo
```

Tips:
=====

If order for GPG agent to prompt you for credentials, you *must* use `pinentry-mac` in your `gpg-agent.conf`.  This should come by default with the brew installation of `gnupg2`.

If your keychain is locked, Keychain Access will prompt you to enter your password. Unfortunately, `socat` will timeout waiting for a response. To avoid this problem, click "Always Allow" when you encounter it for the first time.

Options:
========

Daft can be started with options to disable ssh (`--no-ssh`), gpg (`--no-gpg`), or keychain (`--no-keychain`) forwarding.

```
$ daft --no-ssh start
```

Similarly, you can choose whether or not to mount SSH into your container when you start it:

```
$ docker run $(daft mount --no-ssh) ...
```

**WARNING**: daft makes no attempt at access control.  Once you start daft, all forwarded agents are available to *any* docker container that mounts the agent!
