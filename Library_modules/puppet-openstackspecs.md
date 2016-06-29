# puppet-openstack-specs


本章节也是选读章节，仅对模块做了一个简单介绍。   
`puppet-openstack-specs`模块是用于管理Blueprint design document，对Openstack了解的同学应该知道，在早年，社区使用Launchpad来管理BluePrint(BP)，后来过渡到使用这种Markdown语法编写+Code review的方式来管理功能开发文档，我觉得这是一个非常好的设计，在文档的格式定义，归档，搜索上有非常有益的尝试。

## 模块详解

与PuppetOpenstack相关的specs放在specs/目录下，并根据release版本不同，划分出了不同的目录，例如以Newton的某个BP为例：[**Configuration File Deprecation Support**](https://github.com/openstack/puppet-openstack-specs/blob/master/specs/newton/config-deprecation-for-inifile-provider.rst)

它使用如下的章节目录对功能定义进行描述:

- Problem description
- Proposed change
 - Alternatives
 - Data model impact
 - Module API impact
 - End user impact
 - Performance Impact
 - Deployer impact
 - Developer impact
- Implementation
 - Assignee
 - Work Items 
- Dependencies
- Testing
- Documentation Impact
- References

总结为四个字：非常专业。