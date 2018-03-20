# Bugshot

#### 基于GitLab的bug-reporter, QA可以直接将app的bug以issue的格式提交到gitlab分支

用法:

`

1. 将.h&.m文件拖入自己的项目;
2. 修改 BSKGitlabReporter 中的 gitlab url 和 project id 为自己项目的信息即可.`

支持:

`

* 当前屏幕自动截图;
* 自动收集当前设备信息、版本信息;
* 利用GitLab API 提交 issues(包含:tittle、description、attachment、assignee、labels).

`

TODO:
`

* 支持pod集成;
* assigne读取配置文件;
* 支持外部配置gitlab地址、project id;
* ...  


`
