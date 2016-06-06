set -e

if [ -n "$DEBUG" ]; then
  set -x
fi

# set environment
export SCENARIO=scenario-aio
export SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
export PUPPET_VERSION=${PUPPET_VERSION:-3}
export SCENARIO=${SCENARIO:-scenario001}
export MANAGE_PUPPET_MODULES=${MANAGE_PUPPET_MODULES:-true}
export MANAGE_REPOS=${MANAGE_REPOS:-true}
export PUPPET_ARGS=${PUPPET_ARGS:-}
export SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
export DISTRO=$(lsb_release -c -s)
if [ $PUPPET_VERSION == 4 ]; then
  export PATH=${PATH}:/opt/puppetlabs/bin
  export PUPPET_RELEASE_FILE=puppetlabs-release-pc1
  export PUPPET_BASE_PATH=/etc/puppetlabs/code
  export PUPPET_PKG=puppet-agent
else
  export PUPPET_RELEASE_FILE=puppetlabs-release
  export PUPPET_BASE_PATH=/etc/puppet
  export PUPPET_PKG=puppet
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
