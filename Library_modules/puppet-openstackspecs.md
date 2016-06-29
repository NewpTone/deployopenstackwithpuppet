# puppet-openstack-specs

1. [模块讲解](#模块讲解)

**本节作者：余兴超**    
**阅读级别：选读 **  
**阅读时间: 0.5小时**

本章节也是选读章节，仅对模块做了一个简单介绍。   
`puppet-openstack-specs`模块是用于管理Blueprint design document，对Openstack了解的同学应该知道，在早年，社区使用Launchpad来管理BluePrint(BP)，后来过渡到使用这种Markdown语法编写+Code review的方式来管理功能开发文档，我觉得这是一个非常好的设计，在文档的格式定义，归档，搜索上有非常有益的尝试。

## 模块讲解

与PuppetOpenstack相关的specs放在specs/目录下，并根据release版本不同，划分出了不同的目录。

例如以Newton的某个BP为例：[**Configuration File Deprecation Support**](https://github.com/openstack/puppet-openstack-specs/blob/master/specs/newton/config-deprecation-for-inifile-provider.rst)

它使用如下目录对BP进行详细地描述:

- Problem description  #问题描述
- Proposed change  #提出的改进计划
 - Alternatives  #其他替代方案
 - Data model impact  #对数据模型的影响
 - Module API impact  #对模块API的影响
 - End user impact    #对终端用户的影响
 - Performance Impact #对性能的影响
 - Deployer impact    #对部署人员的影响
 - Developer impact   #对开发人员的影响
- Implementation  # 实现相关
 - Assignee  #指派人
 - Work Items #任务列表
- Dependencies  #依赖
- Testing  #测试
- Documentation Impact #对文档的影响
- References #参考链接

总结为四个字：非常专业。