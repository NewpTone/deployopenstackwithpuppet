# 环境准备


在开始介绍PuppetOpenstack前，我们需要准备一台虚拟服务器用于接下来的练习和测试。

读者可以在本机上使用虚拟化软件或者通过云平台创建一台虚拟机。

其规格如下： `2 vCPU`, `4G RAM`, `30G Disk`, 至少有一块`NIC`，操作系统为`CentOS 7.1/7.2`，并可以连接上Internet


```shell
# Script for installing puppet Based on CentOS 7.x

set -e

if [ -n "$DEBUG" ]; then
  set -x
fi

# set environment
export SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
export PUPPET_VERSION=${PUPPET_VERSION:-4}
export MANAGE_PUPPET_MODULES=${MANAGE_PUPPET_MODULES:-true}
export MANAGE_REPOS=${MANAGE_REPOS:-true}
export PUPPET_ARGS=${PUPPET_ARGS:-}
export SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
if [ $PUPPET_VERSION == 4 ]; then
  export PATH=${PATH}:/opt/puppetlabs/bin
  export PUPPET_RELEASE_FILE=puppetlabs-release-pc1
  export PUPPET_BASE_PATH=/etc/puppetlabs/code
  export PUPPET_PKG=puppet-agent
elif [ $PUPPET_MAJ_VERSION == 5 ]; then
  export PATH=${PATH}:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin
  export PUPPET_RELEASE_FILE=puppet5-nightly-release
  export PUPPET_BASE_PATH=/etc/puppetlabs/code
  export PUPPET_PKG=${PUPPET_PKG:-puppet-agent}
fi
if [ $(id -u) != 0 ]; then
  # preserve environment so we can have ZUUL_* params
  SUDO='sudo -E'
fi

echo 'Setup (RedHat based)'
sudo yum -y remove facter puppet rdo-release
sudo yum -y install libxml2-devel libxslt-devel ruby-devel rubygems wget
sudo yum -y groupinstall "Development Tools"

echo 'Install Bundler'
mkdir -p .bundled_gems
export GEM_HOME=`pwd`/.bundled_gems
gem install bundler --no-rdoc --no-ri --verbose

echo 'Start install puppet'

if rpm --quiet -q $PUPPET_RELEASE_FILE; then
    $SUDO rpm -e $PUPPET_RELEASE_FILE
fi
# EPEL does not work fine with RDO, we need to make sure EPEL is really disabled
if rpm --quiet -q epel-release; then
    $SUDO rpm -e epel-release
fi
$SUDO rm -f /tmp/puppet.rpm

wget  http://yum.puppetlabs.com/${PUPPET_RELEASE_FILE}-el-7.noarch.rpm -O /tmp/puppet.rpm
$SUDO rpm -ivh /tmp/puppet.rpm
$SUDO yum install -y dstat ${PUPPET_PKG} setools setroubleshoot audit
$SUDO service auditd start

# SElinux in permissive mode so later we can catch alerts
$SUDO setenforce 0

 ``` 
