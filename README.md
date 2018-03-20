# Bugshot

基于GitLab的bug-reporter, QA可以直接将app的bug以issue的格式提交到gitlab分支

用法:
1.修改 BSKGitlabReporter 中的 gitlab url 和 project id 为自己项目的信息即可.

支持:
1.当前屏幕自动截图;
2.自动收集当前设备信息、版本信息;
3.利用GitLab API 提交 issues(包含:tittle、description、attachment、assignee、labels).
