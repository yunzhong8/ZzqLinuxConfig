# 保存所有linux的脚本
### alias保存的是常用的linux命令重命名

### .sh保存的是shell脚本
## 规定
### 脚本开头名称
zzq
避免和官方名称冲突
### into
intofile_name表示进入那个文件
eg
```
zzqintoMarkdown
```
一般使用alias命令实现
表示进入Markdown文件
### set
setconfig_name表示：设置某个配置文件
```
zzqsetvimrc
```
表示我要设置vimrc文件

# 如何使用这个仓库代码，将
+ step1:拉取仓库
```bash
git clone  git@github.com:yunzhong8/ZzqLinuxConfig.git ~/.zzq_config
```
+ step2:添加bashrc配置 
然后将下面代码添加到~/.bashrc上
```bash
# 平台配置
UBUNTU_SPECIAL_CONFIG="false"
WSL_SPECIAL_CONFIG="true"

# 配置文件主目录
CONFIG_DIR="${Home}.zzq_config"

# 导入通用 bashrc 配置
if [ -d "${CONFIG_DIR}/bashrc" ]; then
    for file in "${CONFIG_DIR}"/bashrc/*.sh; do
        if [ -f "$file" ]; then
            source "$file"
        fi
    done
fi
```
+ step3: 赋予脚本执行权
```bash
chmod -R +x ${Home}/.zzq_config/zzqScript
```
+ step4:私有内容防止命名为private的目录下
#
#
#
#
#
#
#
#
#
#
#
