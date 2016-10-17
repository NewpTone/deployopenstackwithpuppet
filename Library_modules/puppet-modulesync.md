# puppet-modulesync-configs

1. [先睹为快](#先睹为快)
2. [模块讲解](#模块讲解)

**本节作者：余兴超**

**阅读级别：选读 **   

**阅读时间: 0.5小时**

本节为选读章节，推荐有兴趣的读者阅读。

##先睹为快

我们通过`puppet-openstack-cookiebutter`模块的contrib/bootstrap.sh脚本来说明：
```bash
# Step 4: Retrieve the puppet-modulesync-configs directory and configure it for your need
#
git clone https://review.openstack.org/openstack/puppet-modulesync-configs
pushd puppet-modulesync-configs/
cat > managed_modules.yml <<EOF
---
  - puppet-$proj
EOF
cat > modulesync.yml <<EOF
---
namespace:
git_base: file://$tmp_var/cookiecutter/
branch: initial_commit
EOF

# Step 5: Run msync and amend the initial commit
#
msync update --noop
pushd modules/puppet-$proj
md5password=`ruby -e "require 'digest/md5'; puts 'md5' + Digest::MD5.hexdigest('pw${proj}')"`
sed -i "s|md5c530c33636c58ae83ca933f39319273e|${md5password}|g" spec/classes/${proj}_db_postgresql_spec.rb
git remote add gerrit ssh://$user@review.openstack.org:29418/openstack/puppet-$proj.git
git add --all && git commit --amend -am "puppet-${proj}: Initial commit

This is the initial commit for puppet-${proj}.
It has been automatically generated using cookiecutter[1] and msync[2]

[1] https://github.com/openstack/puppet-openstack-cookiecutter
[2] https://github.com/openstack/puppet-modulesync-configs
"

echo "

-----------------------------------------------------------------------------------------------------
The new project has been successfully set up.

To submit the initial review please go to ${tmp_var}/puppet-modulesync-configs/modules/puppet-${proj}
and run git review.

Happy Hacking !
"
```

通过以上步骤，可以为一个新puppet module同步Gemfile,Rakeflie等文件，其中执行同步操作的关键命令是:
```bash
# 注意需要使用gem安装msync命令
msync update
```

## 模块讲解

打一个比方，modulesync-config模块类似于Openstack的[requirements](https://github.com/openstack/requirements)项目。用于管理Gem包的依赖，Rakefile的配置等等。它有几个重要的文件：

 - `config_defaults.yml`: 第一层级的键表示模块被管理的文件名
 - `.sync.yml`: 出现在各自module中，将覆盖`config_defaults`中的值
 - `managed_modules.yml`: 被管理的module列表
 - `modulesync.yml`: 传递到Modulesync命令行的键值对参数对

关于`puppet-modulesync-configs`的用途比较单一，因此不再深入展开，更详细的解释参见其[模块说明](https://github.com/openstack/puppet-modulesync-configs)。
