# 在Modal上训练FLUX LoRA模型完整指南

> **备注**：modal绑定信用卡可白嫖每个月30$的额度使用H100，3000步20张图片大概半个小时训练结束，花费$4。

## 前言

本教程将详细介绍如何在Modal云平台上训练FLUX.1模型的LoRA微调。FLUX作为新一代生成式AI模型，其训练过程有一些特殊要求，本文将一步步引导大家完成整个过程。

## 环境准备

### 前提条件
- Windows或MacOS系统
- 已注册[Modal](https://modal.com)和[Hugging Face](https://huggingface.co)账号
- 在Hugging Face上接受FLUX.1-dev许可协议

### 必备软件
- Python 3.10或更高版本
- Git版本控制工具

## 安装步骤

### 手动克隆仓库（可选）
如果您想手动设置环境，可以使用以下命令克隆仓库：
```bash
git clone https://github.com/miludeerforest/modal_train_flux.git ai-toolkit
```
这将把仓库克隆到名为`ai-toolkit`的文件夹中。在Windows上，推荐克隆到C盘根目录下以避免路径长度问题：
```bash
cd C:\
git clone https://github.com/miludeerforest/modal_train_flux.git ai-toolkit
```

### Windows用户
1. 以管理员身份运行`setup_modal_training.bat`
   - 右键点击脚本
   - 选择"以管理员身份运行"
   - 脚本会自动将仓库克隆到`C:\ai-toolkit`目录下

### MacOS用户
1. 打开终端并导航至项目目录
2. 执行以下命令使脚本可执行：
   ```bash
   chmod +x setup_modal_training.sh
   ```
3. 运行设置脚本：
   ```bash
   ./setup_modal_training.sh
   ```
   - 脚本会自动将仓库克隆到当前目录下的`ai-toolkit`文件夹中

## 配置Modal和Hugging Face

1. 获取Modal令牌
   - 访问 https://modal.com/settings/tokens
   - 点击"New Token"
   - 复制生成的命令，形如：
     ```
     modal token set --token-id ak-xxxx --token-secret as-xxxx
     ```
   - 在终端中执行此命令

2. 准备环境文件
   - 创建`.env`文件
   - 添加Hugging Face令牌：
     ```
     HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     ```

## 训练配置详解

我们使用YAML文件配置训练参数。以下是关键参数的详细说明：

```yaml
name: "example_model_v1"  # 项目名称，也是输出文件名
trigger_word: "example_person"  # 触发词，用于激活LoRA效果

network:
  type: "lora"  # 使用LoRA网络
  linear: 16    # LoRA秩
  linear_alpha: 16  # LoRA缩放因子

datasets:
  - folder_path: "/root/ai-toolkit/example_dataset"  # 训练数据集路径
    resolution: [ 512, 768, 1024 ]  # FLUX支持多分辨率训练

train:
  steps: 4000  # 总训练步数
  gradient_accumulation_steps: 1  # 梯度累积步数
  noise_scheduler: "flowmatch"  # FLUX必须使用flowmatch
  lr: 1e-4  # 学习率

sample:
  seed: 42  # 样本生成的固定种子
  guidance_scale: 4  # CFG引导程度
  sample_steps: 28  # 采样步数
```

### 重要说明

1. **数据集准备**：
   - 图片格式支持jpg、jpeg和png
   - 每张图片需要对应同名的.txt文件作为标注
   - 标注中可以包含[trigger]标签，会被自动替换为触发词

2. **FLUX特有设置**：
   - 必须使用flowmatch调度器
   - 推荐使用bf16数据类型
   - 暂不支持训练text_encoder

## 训练启动

### Windows一键启动
Windows用户可以使用项目中提供的一键启动脚本：

1. 在项目目录中找到`run_modal_training.bat`
2. 双击运行或右键以管理员身份运行
3. 脚本会自动配置环境并启动训练

### 手动启动
准备就绪后，使用以下命令启动训练：

```bash
modal run --detach run_modal.py --config-file-list-str=/root/ai-toolkit/config/modal_train_lora_flux.yaml
```

可在https://modal.com/logs查看训练进度和日志。

## 训练结果下载

训练完成后，使用以下命令下载模型：

```bash
modal volume get flux-lora-models your-model-name
```

## 常见问题

1. **VRAM需求**：训练FLUX.1的LoRA至少需要24GB显存。

2. **训练样本差异**：使用固定种子(seed: 42)可确保每次生成的样本保持一致，便于比较训练进度。这不会影响实际训练效果，只影响可视化样本。

3. **文件路径问题**：在Windows上，为避免路径长度限制，仓库默认克隆到`C:\ai-toolkit`。

4. **成本控制**：
   - 20张图片训练3000步约需半小时，花费约$4
   - Modal绑定信用卡后每月有$30免费额度
   - 可以通过减少steps或batch_size降低成本

## 总结

通过本教程，您应该能够在Modal上成功训练FLUX LoRA模型。随着训练的进行，您会看到模型逐渐学习您的训练数据特征。如有问题，欢迎在评论区交流讨论。 