# puppet-heat

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理heat服务？](#核心代码讲解)
    - [class heat](#class heat)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**本节作者：余兴超**    
**阅读级别：必读 **  
**阅读时间: 1小时**

AWS CloudFormation服务，为用户提供了编排AWS中的资源的能力。Openstack社区在2012年推出了类似支持编排功能的服务Heat。Heat基本的workflow是这样的：
![](../images/03/heat.png)                

## 先睹为快

在了解完Heat后，我们首先通过快速部署一个带有heat所有服务的环境来快速地上手，首先我们需要做一点hack，在`fixtures/scenario-aio.pp`文件中追加:
```puppet
include ::openstack_integration::heat
```
然后在终端下执行:
```bash
   puppet apply -v fixtures/scenario-aio.pp
```
在执行完成后，我们通过systemctl命令，可以看到以下服务并启动：
```bash
 openstack-heat-api-cfn.service                                                   loaded    active   running   Openstack Heat CFN-compatible API Service
  openstack-heat-api-cloudwatch.service                                           loaded    active   running   OpenStack Heat CloudWatch API Service
  openstack-heat-api.service                                                      loaded    active   running   OpenStack Heat API Service
  openstack-heat-engine.service                                                   loaded    active   running   Openstack Heat Engine Service
  ```

先在终端下执行list命令，正常的返回值为空:
```bash
  openstack stack list
```

接着我们使用一个简单HOT模板来验证一下刚才heat的部署工作是否work，手动创建一个test.yaml文件：

```yaml
heat_template_version: 2015-04-30

description: Simple template to deploy a single compute instance

resources:
  my_instance:
    type: OS::Nova::Server
    properties:
      image: a0a885b4-4045-4dee-bb91-c163c4ba429a
      flavor: m1.nano
```

在终端下输入以下命令：
```
openstack stack create -t test.yaml test
```
观察输出信息中的`stack_status_reason`，若为`started`，则说明stack创建完成:
```
+---------------------+-----------------------------------------------------+
| Field               | Value                                               |
+---------------------+-----------------------------------------------------+
| id                  | 89ccfa5b-31c6-4a86-abe9-72c0a44729f8                |
| stack_name          | test                                                |
| description         | Simple template to deploy a single compute instance |
| creation_time       | 2016-05-31T11:50:39                                 |
| updated_time        | None                                                |
| stack_status        | CREATE_IN_PROGRESS                                  |
| stack_status_reason | Stack CREATE started                                |
+---------------------+-----------------------------------------------------+
```
  
## 核心代码讲解

### class heat::api
和其他服务类似，heat::api完成了对heat-api软件包，相关配置文件和服务管理。
   
### class heat::api_cfn
和其他服务类似，heat::api_cfn完成了对heat-api-cfn软件包，相关配置文件和服务管理。

### class heat::api_cloudwatch

和其他服务类似，heat::api_cloudwatch完成了对heat-api-cloudwatch软件包，相关配置文件和服务管理。

   
### class heat::engine 
和其他服务类似，heat::engine完成了对heat-engine软件包，相关配置文件和服务管理。
这里有一个关于`size`和`member`的用法实例：
 - `size`的作用是返回一个字符串，列表或者哈希的长度。
 - `member`函数则是判断一个变量是否为一个列表的成员。

```puppet
  $allowed_sizes = ['16','24','32']
  $param_size = size($auth_encryption_key)
  if ! (member($allowed_sizes, "${param_size}")) { # lint:ignore:only_variable_string
    fail("${param_size} is not a correct size for auth_encryption_key parameter, it must be either 16, 24, 32 bytes long.")
  }
```
### 其他class
   - heat::client完成对heatclient软件包的安装配置
   - heat::keystone::auh完成heat user,role,endpoint的管理
   - heat::keystone::domain完成默认heat domain的创建
   - heat::db::mysql完成了heat数据库的创建

## 小结

   Heat服务的架构比较简单，因此在配置上并没有太多复杂的地方，它的核心还是在于结合业务，完成HOT模板的编写。
   
## 动手练习

1. 在keystone中添加heat-api-cfn user，service和endpoint
2. 仅部署heat-api和heat-engine服务
