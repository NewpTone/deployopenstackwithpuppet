# puppet-oslo

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 公共define库](#核心代码讲解)
   - [define oslo::log](###define log )
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 30m**

这是读者和作者都会感到轻松又欢快的一章，因为puppet-oslo模块的结构非常简单。
回到正题，puppet-oslo模块是有我(xingchao)在16年年初提出并贡献到社区的puppet module。它的目的就是为了消灭当时存在于各模块中大量的冗余代码，例如：每个模块当中都有rabbitmq的配置，都有log的配置，都有db的配置，那么为何不做一个公共库，把这些代码抽取出来呢？

## 先睹为快

很可惜，这是一个公共define库，不会单独存在，而是被其他模块调用来使用。

## 核心代码讲解

所有代码的结构都是一样的，就是针对某个oslo.xxx库的参数设置，因此在这里我们只举一个例子来说明：

### define oslo::log

在oslo::log的代码中，继续给大家讲解一些函数的使用。

以下代码中，我们看到了：

- is_service_default用于判断变量是否使用了默认值；
- validate_hash用于判断变量是否为hash类型；
- join使用分隔符将list连接成字符串;
- sort将字符串和数组进行按单词排序；
- join_keys_to_values将key和value使用分隔符连接，例如：join_keys_to_values({'a'=>1,'b'=>2}, " is ")` 结果为 ["a is 1","b is 2”]

```puppet
  if is_service_default($default_log_levels) {
    $default_log_levels_real = $default_log_levels
  } else {
    validate_hash($default_log_levels)
    $default_log_levels_real = join(sort(join_keys_to_values($default_log_levels, '=')), ',')
  }
```

我们接着往下看，下面的关键是create_resources函数，终于到了值得讲一讲的地方了。

#### Puppet中的迭代用法

学习Puppet的人常会问起Puppet中的迭代用法，因为多数Puppet用户都有命令式编程的经验，比如说在Bash Shell下，使用for语句来表示循环。但是Puppet是一门声明式DSL( [domain-specific language](https://en.wikipedia.org/wiki/Domain-specific_language) )，DSL不是图灵完备的([Turing complete](https://en.wikipedia.org/wiki/Turing_completeness))。因此在Puppet 4.x之前([Language: Iteration and Loops](https://docs.puppet.com/puppet/latest/reference/lang_iteration.html#language:-iteration-and-loops))，是不支持迭代语法的，不过从Puppet 3.3开始，可以通过一定的配置来开启Puppet中的试验性迭代功能。

我们还有另外一种方式来实现迭代功能，那就是使用create_resources函数，create_resource可以接受3个参数:

- resource名称
- hash类型变量
- 可选，hash变量，用于设置resrouce公共属性

```puppet
# A hash of user resources:
$myusers = {
  'nick' => { uid    => '1330',
              gid    => allstaff,
              groups => ['developers', 'operations', 'release'], },
  'dan'  => { uid    => '1308',
              gid    => allstaff,
              groups => ['developers', 'prosvc', 'release'], },
}
create_resources(user, $myusers)

$defaults = {
  'ensure'   => present,
  'provider' => 'ldap',
}
create_resources(user, $myusers, $defaults)
```

OK，我们再回过头来看这段代码，是不是就很容易理解了？

```puppet
  $log_options = {
    'DEFAULT/debug'                         => { value => $debug },
    'DEFAULT/verbose'                       => { value => $verbose },
    'DEFAULT/log_config_append'             => { value => $log_config_append },
    'DEFAULT/log_date_format'               => { value => $log_date_format },
    'DEFAULT/log_file'                      => { value => $log_file },
    'DEFAULT/log_dir'                       => { value => $log_dir },
    'DEFAULT/watch_log_file'                => { value => $watch_log_file },
    'DEFAULT/use_syslog'                    => { value => $use_syslog },
    'DEFAULT/syslog_log_facility'           => { value => $syslog_log_facility },
    'DEFAULT/use_stderr'                    => { value => $use_stderr },
    'DEFAULT/logging_context_format_string' => { value => $logging_context_format_string },
    'DEFAULT/logging_default_format_string' => { value => $logging_default_format_string },
    'DEFAULT/logging_debug_format_suffix'   => { value => $logging_debug_format_suffix },
    'DEFAULT/logging_exception_prefix'      => { value => $logging_exception_prefix },
    'DEFAULT/logging_user_identity_format'  => { value => $logging_user_identity_format },
    'DEFAULT/default_log_levels'            => { value => $default_log_levels_real },
    'DEFAULT/publish_errors'                => { value => $publish_errors },
    'DEFAULT/instance_format'               => { value => $instance_format },
    'DEFAULT/instance_uuid_format'          => { value => $instance_uuid_format },
    'DEFAULT/fatal_deprecations'            => { value => $fatal_deprecations },
  }

  create_resources($name, $log_options)
```

## 小结

这章的内容比较简单，我们主要介绍了几个函数的使用说明，着重说明了Puppet中的迭代，它们的加入使得代码逻辑变得更加强大。

## 动手练习

1. define和class有什么区别？为什么要使用define而不使用class？