ReCept: Remarkable Intercept
============================

A small library to intercept and smooth pen events on the [reMarkable
2](https://remarkable.com/) tablet. This fixes the infamous "jagged lines"
issue some users of the reMarkable 2 experience.

![before vs after](images/before_after.png)

Disclaimer
----------

This is not an official reMarkable product, and I am in no way affiliated with
reMarkable. I release this library in the hope that it is helpful to others. I
can make no guarantee that it works as intended. There might be bugs leading to
device crashes.

This repository is forked from the original created by github user funkey.

Installation
------------

You need access to a Linux machine to install the fix. On that machine:

1. Connect your reMarkable 2 with the USB-C cable.
2. Clone this repository, i.e., run `git clone https://github.com/funkey/recept` in a terminal.
3. Change into the repository with `cd recept`.
4. Run `./install.sh`.

The install script will make several `ssh` connections to your device. For
that, it needs to know the IP address or hostname of your device. If you
haven't set up public key authentication before, it will also ask for a
password. You can find both the IP address and password in "Settings" -> "Help"
-> "Copyrights and licenses", at the bottom.

If you want to uninstall the fix, simply enter `0` when asked for the smoothing
value in the install script.

Will it increase the latency?
-----------------------------

In short, yes. The pen events themselves are not delayed (the filter itself
consists only of a handful of integer operations, which are likely negligible).
However, since we forward the average position of the past `N` events instead
of the actual event, the reported position is somewhere close to the `N/2`-last
event received. How much that actually increases latency depends on how fast
events come in. As an example, if the pen sends 1000 events per second and the
filter size `N` is 8, the mean will trail the actual pen position by around 4
milliseconds. This calculation assumes isochronous events, which might not be
the case.

To avoid the above latency issue, a second type of filter has been added.
The IIR Filter is basically a running average which can be weighted more
towards new values to try to get the newest reading closer to the edge.
This might have a different filtering behaviour compared to the FIR filter
implemented using the ring mechanism, however the filter coefficient can
be tuned to get a similar time constant.

How does it work?
-----------------

`ReCept` uses the `LD_PRELOAD` trick, which in this case intercepts calls to
`open` and `read`. Whenever `/dev/input/event1` is opened by `xochitl` (the GUI
running on the tablet), `librecept` remembers the file handle. Subsequent
`read`s from this handle are transparently filtered with a moving average of
size 16 by default.

How to comple it yourself
-------------------------

`ReCept` requires the arm toolchain from remarkable to be downloaded and installed.
Instructions to do so can be found at: `https://remarkable.engineering/deploy/sdk/`

    curl https://remarkable.engineering/oecore-x86_64-cortexa9hf-neon-toolchain-zero-gravitas-1.8-23.9.2019.sh -o install-toolchain.sh

The toolchain uses a shell script that will install the necessary binaries to the
directory you specify. It requires that you have bsdtar installed on your machine.
If you don't you can install it using apt for Ubuntu:

    sudo apt install libarchive-tools

To install the toolchain, simply run

    chmod +x install-toolchain.sh
    ./install-toolchain.sh

Once you have the toolchain downloaded and installed, you can source the toolchain
into your path. Look for the below file in the path that you provided for installing
the toolchain.

    environment-setup-cortexa9hf-neon-poky-linux-gnueabi
    source <PATH_TO_TOOLCHAIN>/environment-setup-cortexa9hf-neon-poky-linux-gnueabi

Now you are ready to compile. Just issuing make on the command line will generate all
the binaries corresponding to the different filters.

    make

After this follow the install instructions above to push the library to your tablet
and to restart xochitl.
