# Puppet版本的选择


TODO: Version pic

## Puppet 2.x

目前Puppet 2.x的最新版本是2.7.x。除非是遗留系统保留大量的第三方模块，无法升级到其他版本，否则我们极力推荐读者从2.x升级到3.x版本。

## Puppet 3.x

Puppet 3.x的最新版本是[3.8.7](https://docs.puppet.com/puppet/3.8/reference/release_notes.html)。相比2.x，其catalog的编译速度提升了50%，并且也包含了4.x里的新增特性(通过额外配置开启）。如不是特殊原因，我们推荐读者从3.x升级到4.x版本。

## Puppet 4.x

在2016年9月22日，Puppet已发布了4.7.0版本，之前我们曾建议读者谨慎使用4.x，但时至今日，我们推荐直接使用4.x版本。

目前PuppetOpenstack社区已经放弃对Puppet3的支持(https://review.openstack.org/#/c/383739/)。

因此，我们的建议是：
   - 如果您正在使用Puppet3，请谨慎升级到Puppet4。
   - 如果你正在计划使用Puppet，直接使用Puppet4。

我们会在下一节去详细介绍Puppet 4.x的显著变化。