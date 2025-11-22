#!/bin/bash

echo "=== FLUX LoRA Training Setup Script ==="
echo
echo "This script will help you set up the environment for training LoRA models with FLUX:"
echo " - Install required software (Python 3.10, Git) if not already installed"
echo " - Clone the ai-toolkit repository"
echo " - Set up virtual environment and dependencies"
echo " - Configure Modal and Hugging Face tokens"
echo
echo "IMPORTANT: Make sure you have:"
echo "- Registered accounts on Modal and Hugging Face"
echo "- Accepted FLUX.1-dev license on Hugging Face (if using it)"
echo

read -p "Do you want to continue? [Y/N]: " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled by user."
    exit 0
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Python not found. Please install Python 3.10 or higher."
    echo "You can download Python at: https://www.python.org/downloads/"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo "Git not found. Please install Git."
    echo "You can install Git using Homebrew: brew install git"
    exit 1
fi

echo "[1/6] Checking/Cloning ai-toolkit repository..."
if [ -d "ai-toolkit" ]; then
    echo "Found existing ai-toolkit folder, skipping clone..."
    cd ai-toolkit
else
    git clone https://github.com/miludeerforest/modal_train_flux.git ai-toolkit
    if [ $? -ne 0 ]; then
        echo "[ERROR] Could not clone repository."
        exit 1
    fi
    cd ai-toolkit
fi

echo "[2/6] Updating submodules..."
git submodule update --init --recursive

echo "[3/7] Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo "[4/7] Installing/Upgrading Modal CLI..."
pip install --upgrade modal

echo "[5/7] Installing required dependencies..."
pip install python-dotenv huggingface_hub oyaml

echo "[6/7] Running 'modal setup' (see https://modal.com/docs/guide/apps)..."
echo "============================================================"
echo "modal setup will open a browser for authentication."
echo "Afterwards, run 'modal token new --name flux-training' if you need an extra token."
echo "============================================================"
modal setup || {
    echo "[ERROR] modal setup failed. Please rerun after fixing the issue."
    exit 1
}
echo "Modal CLI initialized successfully!"
echo

echo "=== Next Steps ==="
echo "Required files to prepare:"
echo "1. Configuration file:"
echo "   - Customize settings according to your needs in config/modal_train_lora_flux.yaml"
echo "2. Environment file (.env):"
echo "   - Add your Hugging Face token"
echo "3. Training data files"
echo

read -p "Press Enter when you have prepared all required files to begin training..."

# Check required files
while true; do
    if [ ! -f ".env" ]; then
        echo "[ERROR] .env file not found!"
        echo "Please create .env file and add your Hugging Face token in format:"
        echo "HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo
        read -p "Press Enter after you have created the .env file..."
        continue
    fi

    if ! grep -q "^HF_TOKEN=hf_" .env; then
        echo "[ERROR] Invalid HF_TOKEN format in .env file!"
        echo "Token should be in format: HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo
        read -p "Press Enter after you have fixed the token format..."
        continue
    fi

    if [ ! -f "config/modal_train_lora_flux.yaml" ]; then
        echo "[ERROR] Configuration file not found!"
        echo "Please create config/modal_train_lora_flux.yaml"
        echo "You can copy from templates in config/examples/modal/"
        echo
        read -p "Press Enter after you have created the config file..."
        continue
    fi

    break
done

echo "All required files are present."
echo

echo "[1/2] Checking/Downloading FLUX model if needed (this may take a while)..."
modal run download_model.py || {
    echo "[ERROR] Failed to download FLUX model"
    exit 1
}
echo

echo "[2/2] Starting training process..."
modal run --detach run_modal.py::main --config-file-list-str=/root/ai-toolkit/config/modal_train_lora_flux.yaml || {
    echo "[ERROR] Failed to start training process"
    exit 1
}

echo
echo "Training process has started!"
echo "Open https://modal.com/apps and select flux-lora-training to inspect logs."
echo 
