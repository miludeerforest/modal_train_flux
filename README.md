# FLUX LoRA 训练快速引导

> 基于 ostris 的 [ai-toolkit](https://github.com/ostris/ai-toolkit) 在 Modal 上适配 FLUX LoRA 训练。文档仅保留必要步骤，避免上传任何私人配置/图片。

## 1. 前提条件
- Windows（建议管理员权限）或 Mac/Linux 终端
- 账号：Modal、Hugging Face；已在 HF 接受 FLUX.1-dev 许可（如使用）
- 安装 Git、Python ≥ 3.10

## 2. 推荐路径（Windows）
- 仓库路径建议 `C:\ai-toolkit` 以避免路径过长。
- 运行脚本：右键 `setup_modal_training.bat` → “以管理员身份运行”。
- 脚本可：自定义/确认 Python 路径、仓库目录/URL、配置文件路径、是否克隆仓库；Modal 初始化支持浏览器登录或粘贴整行 token 命令。

## 3. Modal CLI 初始化
- 浏览器模式：在脚本中选 `M`，或手动执行 `python -m modal setup`。
- 手动 token 模式：选 `T`，可粘贴整行命令
  `modal token set --token-id ak-xxx --token-secret as-xxx`
  或逐项输入 id/secret。
- 额外令牌（可选）：`python -m modal token new --name flux-training`

## 4. 必备文件
- 配置：`config/modal_train_lora_flux.yaml`（可从 `config/examples/modal/` 拷贝并修改）。
- 环境：根目录 `.env`，内容示例：`HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- 训练数据：放在仓库内（例如 `linyaru/`），对应 caption `.txt` 文件同名。

## 5. 训练命令（提交到 Modal）
- 确认 `.env` 和配置文件存在后，脚本会自动调用：
  `python -m modal run download_model.py`
  `python -m modal run --detach run_modal.py::main --config-file-list-str=/root/ai-toolkit/config/modal_train_lora_flux.yaml`
- 手动执行时也请使用 `python -m modal ...` 形式，避免缺少全局 `modal` 可执行文件。
- 运行状态与日志：Modal 控制台 Apps → `flux-lora-training`。

## 6. 常见问题
- “modal 未找到”：使用 `python -m modal ...`。
- token 问题：确认 `HF_TOKEN`、Modal token 格式正确；可用脚本手动模式重新写入。
- 路径/权限：在 Windows 尽量使用管理员；仓库放在短路径（如 `C:\ai-toolkit`）。

## 7. 下载已训练模型
- 将模型从 Modal Volume 下载到本地（示例路径为 ComfyUI LoRA 目录）：
  ```powershell
  python -m modal volume get flux-lora-models linyaru_v1/linyaru_v1.safetensors F:\env\ComfyUI\models\loras
  ```
- 按需替换模型名与目标路径；如未激活虚拟环境，可用脚本同款 Python 路径执行：
  `C:\Users\sxm2\scoop\apps\miniforge\25.9.1-0\python.exe -m modal volume get ...`

## 8. 安全提示
- 不要将私人数据、图片、token、.env 提交到仓库。
- 推送前检查 `git status`，仅提交必要代码/配置模板。

---
英文版参见 `README.en.md`。
