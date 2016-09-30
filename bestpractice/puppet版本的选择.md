# Puppet版本的选择


TODO: Version pic

## Puppet 2.x

目前Puppet 2.x的最新版本是2.7.x。除非是遗留系统保留大量的第三方模块，无法升级到其他版本，否则我们极力推荐读者从2.x升级到3.x版本。

## Puppet 3.x

Puppet 3.x的最新版本是[3.8.7](https://docs.puppet.com/puppet/3.8/reference/release_notes.html)。相比2.x，其catalog的编译速度提升了50%，并且也包含了4.x里的新增特性(通过额外配置开启）。属于主流版本，推荐使用。

## Puppet 4.x

在9月22日，Puppet发布了4.7.0版本，但目前我仍不推荐使用4.x。原因就是Python2和Python3的关系一样。Python社区修复了Py2中令人头疼的编码问题，但是愿意使用的人寥寥无几，Python社区甚至专门做了一个[Python2生命倒计时网站](https://pythonclock.org/)来提醒大家赶紧切换到Python3。原因就在于大量的第三方库并进行升级以支持Py3。Puppet也是同样的原因。当前所有的puppet-openstack modules都支持Puppet4，但我们无法保证其他第三方的模块也能正常支持Puppet4。