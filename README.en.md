# FLUX LoRA Training Guide

English | [中文](README.md)

> Thanks to ostris's [ai-toolkit](https://github.com/ostris/ai-toolkit) project. This project is an optimized and improved version for FLUX LoRA training on Modal.

## Video Tutorial
[![FLUX LoRA Training Tutorial](https://img.youtube.com/vi/Xjuz92Xmv5w/0.jpg)](https://www.youtube.com/watch?v=Xjuz92Xmv5w)

This guide will help you set up the environment for training LoRA models with FLUX on Modal.

## Prerequisites

Before starting, make sure you have:
- Administrator privileges on your Windows system (for Windows users)
- Registered accounts on [Modal](https://modal.com) and [Hugging Face](https://huggingface.co)
- Accepted FLUX.1-dev license on Hugging Face (if using it)

## Setup Instructions

### Manual Repository Clone (Optional)
If you want to set up the environment manually, you can clone the repository using:
```bash
git clone https://github.com/miludeerforest/modal_train_flux.git ai-toolkit
```
This will clone the repository to a folder named `ai-toolkit`. On Windows, it's recommended to clone to C drive root to avoid path length issues:
```bash
cd C:\
git clone https://github.com/miludeerforest/modal_train_flux.git ai-toolkit
```

### For Windows Users:

1. Run `setup_modal_training.bat` as Administrator
   - Right-click on the script
   - Select "Run as administrator"
   - The script will automatically clone the repository to `C:\ai-toolkit` directory

### For MacOS Users:

1. Open Terminal and navigate to the project directory
2. Make the setup script executable:
   ```bash
   chmod +x setup_modal_training.sh
   ```
3. Run the setup script:
   ```bash
   ./setup_modal_training.sh
   ```
   - The script will automatically clone the repository to an `ai-toolkit` folder in the current directory

### Common Steps for Both Platforms:

1. Install and initialize the Modal CLI (see https://modal.com/docs/guide/apps for the latest workflow):
   ```bash
   pip install --upgrade modal
   modal setup
   ```
   - `modal setup` opens a browser window for authentication and writes the default API token locally.
   - If you need a dedicated token for training, run:
     ```
     modal token new --name flux-training
     ```
     and follow the prompts to save the credential.

2. Prepare required files:
   - Configuration file:
   - Customize settings according to your needs in config/file modal_train_lora_flux.yaml
   - Environment file (`.env`):
     - Add your Hugging Face token in format:
     ```
     HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     ```

## Installation Process

The setup script will automatically:
1. Install required software (if not already installed):
   - Python 3.10 or higher
   - Git (on MacOS, you can install it via Homebrew if needed)

2. Clone the repository:
   - Windows: to `C:\ai-toolkit` (to prevent path length limitations)
   - MacOS: to the current directory
   
3. Set up virtual environment and dependencies
4. Configure Modal and Hugging Face tokens

## Starting Training

Once all files are prepared, launch the training job on Modal with the modern entrypoint syntax (`::main` corresponds to the `main` function in `run_modal.py`):
```
modal run --detach run_modal.py::main --config-file-list-str=/root/ai-toolkit/config/modal_train_lora_flux.yaml
```

After deployment, monitor logs and historical runs from the Modal dashboard under Apps (https://modal.com/apps, accessible via the “Apps” link in the top navigation) and open the `flux-lora-training` app to inspect live output.

## Troubleshooting

If you encounter any issues:
1. Make sure you're running the script as Administrator
2. Check that all required tokens are correctly set up
3. Verify that Python and Git are properly installed and added to PATH
4. Ensure all required files are present and correctly formatted

## Note

If you need to restart the setup process:
1. Close the current window
2. Open a new Command Prompt or Terminal
3. Navigate back to the installation folder
4. Run the script again as Administrator

## Download Content
Download trained checkpoints from the configured volume (see https://modal.com/docs/reference/modal.Volume ):
```
modal volume get flux-lora-models your-model-name
```
