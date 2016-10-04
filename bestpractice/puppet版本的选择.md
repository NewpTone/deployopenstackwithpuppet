# Puppet版本的选择


TODO: Version pic

## Puppet 2.x

目前Puppet 2.x的最新版本是2.7.x。除非是遗留系统保留大量的第三方模块，无法升级到其他版本，否则我们极力推荐读者从2.x升级到3.x版本。

## Puppet 3.x

Puppet 3.x的最新版本是[3.8.7](https://docs.puppet.com/puppet/3.8/reference/release_notes.html)。相比2.x，其catalog的编译速度提升了50%，并且也包含了4.x里的新增特性(通过额外配置开启）。属于主流版本，推荐使用。

## Puppet 4.x

在9月22日，Puppet发布了4.7.0版本，目前暂不推荐使用4.x。原因与Python2和Python3的情况类似：Py3修复了Py2中令人头疼的编码问题，提供了更多的新特性，但愿意使用的人寥寥无几，Python社区甚至专门做了一个[Python2生命倒计时网站](https://pythonclock.org/)来提醒大家尽快切换到Python3。主要原因在于目前仍有大量第三方库并没有升级到对Py3的支持。Puppet4也面临同样的问题。puppet-openstack modules已经支持Puppet4，但无法保证读者们在其线上使用到的第三方模块也能正常支持Puppet4。

因此，我们的建议是：
   - 如果您正在使用Puppet2/3，那么我们建议谨慎升级。
   - 如果你正在计划使用Puppet4，那么我们推荐使用Puppet4。