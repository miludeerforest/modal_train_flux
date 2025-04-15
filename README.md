# FLUX LoRA训练指南

[English](README.en.md) | 中文

> 感谢 ostris 的 [ai-toolkit](https://github.com/ostris/ai-toolkit) 项目，本项目是在其基础上针对Modal上的FLUX LoRA训练进行了优化和改进。

## 视频教程
[![FLUX LoRA训练教程](https://img.youtube.com/vi/Xjuz92Xmv5w/0.jpg)](https://www.youtube.com/watch?v=Xjuz92Xmv5w)

本指南将帮助您设置在Modal上使用FLUX训练LoRA模型的环境

## 前提条件

开始前，请确保您有：
- Windows系统上的管理员权限（对于Windows用户）
- 已注册 [Modal](https://modal.com) 和 [Hugging Face](https://huggingface.co) 账号
- 在Hugging Face上接受FLUX.1-dev许可（如果使用）

## 设置说明

### 对于Windows用户：

1. 以管理员身份运行 `setup_modal_training.bat`
   - 右键点击脚本
   - 选择"以管理员身份运行"

### 对于MacOS用户：

1. 打开终端并导航到项目目录
2. 使脚本可执行：
   ```bash
   chmod +x setup_modal_training.sh
   ```
3. 运行设置脚本：
   ```bash
   ./setup_modal_training.sh
   ```

### 两个平台的通用步骤：

1. 按照Modal令牌设置：
   - 访问 https://modal.com/settings/tokens
   - 点击"New Token"
   - 复制类似如下的命令：
     ```
     modal token set --token-id ak-xxxx --token-secret as-xxxx
     ```
   - 在提示时粘贴命令

2. 准备所需文件：
   - 配置文件：
   - 根据您的需求自定义config/file modal_train_lora_flux.yaml中的设置
   - 环境文件(`.env`)：
     - 按以下格式添加您的Hugging Face令牌：
     ```
     HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     ```

## 安装过程

设置脚本将自动：
1. 安装必需的软件（如果尚未安装）：
   - Python 3.10或更高版本
   - Git（在MacOS上，如果需要可以通过Homebrew安装）

2. 克隆仓库：
   - Windows：到`C:\ai-toolkit`（以防止路径长度限制）
   - MacOS：到当前目录
   
3. 设置虚拟环境和依赖项
4. 配置Modal和Hugging Face令牌

## 开始训练

所有文件准备好后，训练过程将通过以下命令自动启动：
```
modal run --detach run_modal.py --config-file-list-str=/root/ai-toolkit/config/modal_train_lora_flux.yaml
```

您可以在以下位置监控训练进度和日志：https://modal.com/logs

## 故障排除

如果遇到任何问题：
1. 确保您以管理员身份运行脚本
2. 检查所有必需的令牌是否正确设置
3. 验证Python和Git是否正确安装并添加到PATH
4. 确保所有必需文件都存在且格式正确

## 注意

如果需要重新启动设置过程：
1. 关闭当前窗口
2. 打开新的命令提示符或终端
3. 导航回安装文件夹
4. 再次以管理员身份运行脚本

## 下载内容
可以通过运行以下命令下载训练好的模型：
```
modal volume get flux-lora-models your-model-name
```