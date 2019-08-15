# imgadm -- manage VM images

`imgadm` is a tool for managing images on a local headnode or compute node. It
can import and destroy local images, present information about how they're
being used.  To find and install new images, imgadm speaks to a server
implementing the IMGAPI. The default and canonical IMGAPI server is the Joyent
Images repository at <https://images.joyent.com>.


# Test Suite

    /usr/img/test/runtests

This can only be run in the global zone (GZ).


# Development

## Linux

**This is experimental.  Not all things work, particularly those that involve
interaction with VMs.  This means that `imgadm create <instance-uuid>` will not
work.**

The following examples are done on Ubuntu 18.04.2.

```
$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=18.04
DISTRIB_CODENAME=bionic
DISTRIB_DESCRIPTION="Ubuntu 18.04.2 LTS"
```

You will need node 6 available at /usr/node/bin/node.  One way to make this
happen is:

```
$ curl https://nodejs.org/dist/v6.17.1/node-v6.17.1-linux-x64.tar.gz | sudo tar xzf - -C /opt
$ sudo ln -s /opt/node-v6.17.1-linux-x64 /usr/node
```

To build:

```
$ make install
```

To run:

```
$ sudo ./sbin/imgadm available type=lx-dataset name=centos-7
UUID                                  NAME      VERSION   OS     TYPE        PUB
d1c80032-83d2-11e5-b89f-c317cd0ed1fd  centos-7  20151105  linux  lx-dataset  2015-11-05
aae64e42-c88d-11e5-a49d-87f422b1820b  centos-7  20160201  linux  lx-dataset  2016-02-01
b3d02644-d6b2-11e5-bf13-8b034aec4749  centos-7  20160219  linux  lx-dataset  2016-02-19
547ab560-ebac-11e5-b079-03394741b955  centos-7  20160316  linux  lx-dataset  2016-03-16
ddd996ae-fb57-11e5-adfd-0f38d6e6002e  centos-7  20160405  linux  lx-dataset  2016-04-05
d61a1ef2-12db-11e6-ad97-770e083f1374  centos-7  20160505  linux  lx-dataset  2016-05-05
21ed1470-2361-11e6-a349-a33c057f3399  centos-7  20160526  linux  lx-dataset  2016-05-26
07b33b7a-27a3-11e6-816f-df7d94eea009  centos-7  20160601  linux  lx-dataset  2016-06-01
32de63f8-8b6f-11e6-beb6-b3e46c186cc2  centos-7  20161006  linux  lx-dataset  2016-10-06
23ee2dbc-c155-11e6-ab6d-bf5689f582fd  centos-7  20161213  linux  lx-dataset  2016-12-13
3dbbdcca-2eab-11e8-b925-23bf77789921  centos-7  20180323  linux  lx-dataset  2018-03-23

$ zpool list
NAME   SIZE  ALLOC   FREE  EXPANDSZ   FRAG    CAP  DEDUP  HEALTH  ALTROOT
vms   99.5G   106K  99.5G         -     0%     0%  1.00x  ONLINE  -

$ sudo sbin/imgadm import -P vms 3dbbdcca-2eab-11e8-b925-23bf77789921
Importing 3dbbdcca-2eab-11e8-b925-23bf77789921 (centos-7@20180323) from "https://images.joyent.com"
Gather image 3dbbdcca-2eab-11e8-b925-23bf77789921 ancestry
Must download and install 1 image (249.9 MiB)
Download 1 image        [=================================>] 100% 249.98MB  14.19MB/s    17s
Downloaded image 3dbbdcca-2eab-11e8-b925-23bf77789921 (249.9 MiB)
...e8-b925-23bf77789921 [=================================>] 100% 249.98MB  13.39MB/s    18s
Imported image 3dbbdcca-2eab-11e8-b925-23bf77789921 (centos-7@20180323)

$ sbin/imgadm list
UUID                                  NAME      VERSION   OS     TYPE        PUB
3dbbdcca-2eab-11e8-b925-23bf77789921  centos-7  20180323  linux  lx-dataset  2018-03-23
```

## SmartOS

**What follows came from
[smartos-live/src/img](https://github.com/joyent/smartos-live/tree/master/src/img).
It may or may not work with the things in this repo.**

The src/img tree has not binary components, so you can get away
with faster edit/test cycle than having to do a full smartos platform
build and rebooting on it. Here is how:

    # On the target SmartOS GZ (e.g. MY-SMARTOS-BOX), make /usr/img
    # and /usr/man/man1m writeable for testing:
    ssh root@MY-SMARTOS-BOX
    rm -rf /var/tmp/img \
        && cp -RP /usr/img /var/tmp/img \
        && mount -O -F lofs /var/tmp/img /usr/img \
        && rm -rf /var/tmp/man1m \
        && cp -RP /usr/man/man1m /var/tmp/man1m \
        && mount -O -F lofs /var/tmp/man1m /usr/man/man1m

    # On a dev machine:
    # Get a clone of the repo.
    git clone git@github.com:joyent/smartos-live.git
    cd src/img

    # Make edits, e.g. change the version:
    vi package.json

    # Build a dev install image (in /var/tmp/img-install-image)
    # and rsync that to the target node.
    ./tools/dev-install root@MY-SMARTOS-BOX

    # Test that it worked by checking for the version change:
    ssh root@MY-SMARTOS-BOX imgadm --version

    # Or run the test suite:
    ssh root@MY-SMARTOS-BOX /var/img/test/runtests


Before commits, please (a) run the test suite on a test box per the notes
above and (b) maintain style by running `make check`.


# /var/imgadm/imgadm.conf

"/var/imgadm/imgadm.conf" is imgadm's config file. Typically it should not be
edited as most configuration is done via `imgadm ...` commands. For example,
the list of image repository (IMGAPI) "sources" is controlled via
`imgadm sources ...`.

    VAR             DESCRIPTION
    sources         Array of image repository (IMGAPI) sources used for
                    `imgadm avail`, `imgadm import`, etc. Use `imgadm sources`
                    to control this value.
    upgradedToVer   Automatically set by `imgadm` as it does any necessary
                    internal DB migrations.
    userAgentExtra  Optional string that is appended to the User-Agent header
                    when talking to an IMGAPI source.
