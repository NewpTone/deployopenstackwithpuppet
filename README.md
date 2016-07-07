# 关于本书

人是很奇怪的动物，天生懒惰，但是在压力的驱使下，又能做成一些连自己都会觉得惊讶的成就。对于天生喜欢写写随笔和技术blog的我，在近三年的时间里，虽有多家出版社编辑的循循善诱，仍然不为所动，心想着有这闲时间我不如多吃几份美食，多打两盘DOTA。


更深层次地讲其实是源于对于未知的恐惧，源于面对数十万文字工作量的害怕，这本就是一场体力和脑力并存的马拉松，普通人在看到终点的艰巨时，在起点就已经选择了放弃，然而我不是一个普通的人，因此早在6个月前我就富有先见之明地创建了这本书，并且写上了长达83个字节的详细介绍，然后就没有了下文。

无数次惨痛的教训告诉我：决心虽然重要，但是坚持更加可贵。让我重新拾起笔（键盘）的原因是源于今晚的一顿饭。今晚注定是一个平凡的夜晚，DevOps组的同学们像往常一样忙到晚上8点多已是饥肠辘辘，正纷纷收拾东西下班，大家站在公司门前讨论去哪里吃饭，这时我走出来，虽刚从纽约飞回到空气清新的帝都，时差还没有倒回来，脑袋浑浑噩噩，但又担心这帮邋遢的家伙站在公司大门口持续影响公司形象，于是忙把他们连哄带骗全都打包上车，拉到了附近的一家馆子里，几口飘香的云南饭菜入肚，大家就开始天南地北地扯东扯西，无外乎是谁谁谁今天又看了一本MySQL从删库到跑路，谁谁谁今天又当了一回Puppet背锅侠，谁谁谁的项目又埋了一个大坑。

不知不觉，我们就聊到了OpenStack自动化部署这个话题上。作为一名从2011年开始接触Openstack的老油条，在13年幸运地混进了PuppetOpenstack社区项目成了一名core，这漫漫五年时间里有许多知识经验和教训值得沉淀，因此我深深地感觉到是时候~~忽悠~~召唤这帮孩子来一起填这个史诗级别的远古巨坑了。

UnitedStack DevOps Team从13年伊始就全身心投入到持续交付和持续集成事业中，目前使用了**96**个puppet module, **6**台PuppetMaster, 集中管理着约**87**个Openstack集群,**7**种不同环境，支撑了近**3500**台Openstack集群服务器。独立开发了UOS部署工具(CTask)， 软件包管理工具(Packforge/Specforge/Repoforge)， IaaS虚拟资源池(Chameleon）, Openstack升级套件(Screenwriter)，这里面涉及到了大量的自动化运维工具，例如：Ansible, Foreman, Puppet, ClusterShell, Mcollective；同时还有大量运维脚本，包含了多种语言，如：Shell, Ruby, Python, Puppet。

说实话，DevOps团队里每个人平时都有忙不完的事情，从早上还没到公司到晚上回到家中，随时随刻会被人on call，就像今天吃饭那样，维宇同学正站在门口等我上个wc的时间，就被其他同事喊回去处理问题去了。但并不是说因此就有理由说，我们很忙，忙得没有时间写一本书。我们的确需要停下脚步，回头看一看过去三年的努力，然后做一个系统性的梳理和总结了。

本书是关于对Openstack自动化部署工作核心部分的讲解：

> PuppetOpenstack核心模块和基础模块的详细介绍和最佳实践

我们规划每天晚上抽出3小时以上的不固定时间，计划在2个星期内（210+人时）完成第一版的初稿工作，然后开始进入稳定的迭代周期。而这本书仅是一个起步，这几天我规划了接下来的技术分享输出的Roadmap，比如Orchestration，CI, Rolling upgrade等热门话题。我们不想雷声大雨点小，因此当这些事情在真正落到地面的时候，你会听到那些令人振奋的声音。

最后，希望关注此书的读者们可以从中有所思，也有所得。

<br/>

&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; 于月光明媚昏昏欲睡的五月凌晨

&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; 余兴超



---

# 关于作者

> * 余兴超 ([Newptone](http://weibo.com/nupta))  &emsp; 2011年开始接触Openstack，PuppetOpenstack项目Core reviewer，目前负责公司打酱油相关事宜。
> * 廖鹏辉 ([大狗罗宾逊](http://weibo.com/aoLiii)） &emsp;与puppet-openstack社区和puppetlabs社区谈笑风声的 puppet 酱， UnitedStack头号背锅侠。
> * 陆源([小斯](http://weibo.com/2294179087/profile?topnav=1&wvr=6&is_all=1))  &emsp;UnitedStack DevOps成员，爱GW，不爱GFW。2012年开始埋坑，目前负责PuppetOpenstack和UOS部署工具开发。
> * 周维宇(spunkzwy) &emsp;Unitedstack Devops成员，专注于云计算与容器技术,目前负责UOS持续集成系统。
> * 韩亮亮(leon)  &emsp;专注于减肥和Devops，目前负责UOS部署工具开发。

# 如何参与

想为本书添砖加瓦？欢迎加入。更多细节参见 [如何参与](howto.md) 一节。

# 版本更新

想知道版本更新细节和接下来的编写计划？ 请用力戳我 [版本日志](release.md) 。