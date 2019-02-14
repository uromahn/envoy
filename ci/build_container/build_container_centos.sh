#!/bin/bash -e

yum update -y

# scl devtoolset and epel repositories
yum install -y centos-release-scl epel-release
yum install  -y https://centos7.iuscommunity.org/ius-release.rpm

# dependencies for bazel and build_recipes
yum install -y java-1.8.0-openjdk-devel unzip which openssl rpm-build \
                 cmake3 devtoolset-7-gcc devtoolset-7-gcc-c++ devtoolset-7-binutils git2u \
                 go-toolset-7-golang libtool which make ninja-build patch rsync wget \
                 clang-5.0.1 devtoolset-7-libatomic-devel llvm-5.0.1 python27 python-virtualenv bc perl-Digest-SHA \
                 openssl strace wireshark tcpdump

yum clean all

ln -s /usr/bin/cmake3 /usr/bin/cmake
ln -s /usr/bin/ninja-build /usr/bin/ninja

# enable devtoolset-6 for current shell
# disable errexit temporarily, otherwise bash will quit during sourcing
set +e
. scl_source enable devtoolset-7
. scl_source enable go-toolset-7
. scl_source enable python27
set -e

BAZEL_VERSION="$(curl -s https://api.github.com/repos/bazelbuild/bazel/releases/latest |
                  python -c "import json, sys; print json.load(sys.stdin)['tag_name']")"
BAZEL_INSTALLER="bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
curl -OL "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${BAZEL_INSTALLER}"
chmod ug+x "./${BAZEL_INSTALLER}"
"./${BAZEL_INSTALLER}"
rm "./${BAZEL_INSTALLER}"

# setup bash env
cat >/etc/profile.d/devtoolset-7.sh <<EOL1
. scl_source enable devtoolset-7
EOL1
cat >/etc/profile.d/go-toolset-7.sh <<EOL2
. scl_source enable go-toolset-7
EOL2
cat >/etc/profile.d/python27.sh <<EOL3
. scl_source enable python27
EOL3

set +e
. scl_source enable devtoolset-7
. scl_source enable go-toolset-7
. scl_source enable python27
set -e

# Setup tcpdump for non-root.
groupadd pcap
chgrp pcap /usr/sbin/tcpdump
chmod 750 /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

EXPECTED_CXX_VERSION="g++ (GCC) 7.3.1 20180303 (Red Hat 7.3.1-5)" ./build_container_common.sh
