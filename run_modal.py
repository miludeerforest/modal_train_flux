'''

ostris/ai-toolkit on https://modal.com
Run training with the following command:
modal run run_modal.py --config-file-list-str=/root/ai-toolkit/config/whatever_you_want.yml

'''

import os
import sys
import modal
import subprocess
from dotenv import load_dotenv
# Load the .env file if it exists
load_dotenv()

sys.path.insert(0, "/root/ai-toolkit")
# must come before ANY torch or fastai imports
# import toolkit.cuda_malloc

# turn off diffusers telemetry until I can figure out how to make it opt-in
os.environ['DISABLE_TELEMETRY'] = 'YES'

# define the volume for storing model outputs, using "creating volumes lazily": https://modal.com/docs/guide/volumes
# you will find your model, samples and optimizer stored in: https://modal.com/storage/your-username/main/flux-lora-models
model_volume = modal.Volume.from_name("flux-lora-models", create_if_missing=True)

# modal_output, due to "cannot mount volume on non-empty path" requirement
MOUNT_DIR = "/root/ai-toolkit/modal_output"  # modal_output, due to "cannot mount volume on non-empty path" requirement

FLUX_MODEL_VOLUME = modal.Volume.from_name(
    "flux-base-model", 
)
FLUX_MODEL_PATH = "/root/FLUX.1-dev"

# Function to fix diffusers version and gradient checkpointing issues
def fix_diffusers_version():
    print("Fixing diffusers version to avoid gradient checkpointing issues...")
    try:
        # 修复diffusers版本
        subprocess.check_call([sys.executable, "-m", "pip", "uninstall", "-y", "diffusers"])
        subprocess.check_call([sys.executable, "-m", "pip", "install", "diffusers==0.32.2"])
        print("Successfully installed diffusers 0.32.2")
        
        # 应用梯度检查点修复
        try:
            # 导入必要的模块
            import torch
            from diffusers.models.transformers import transformer_flux
            
            # 修复FluxTransformer的梯度检查点功能
            if hasattr(transformer_flux, 'FluxTransformer') and hasattr(transformer_flux.FluxTransformer, 'enable_gradient_checkpointing'):
                original_enable_gradient_checkpointing = transformer_flux.FluxTransformer.enable_gradient_checkpointing
                
                def patched_enable_gradient_checkpointing(self, gradient_checkpointing_kwargs=None):
                    if gradient_checkpointing_kwargs is None:
                        gradient_checkpointing_kwargs = {"use_reentrant": False}
                    elif "use_reentrant" not in gradient_checkpointing_kwargs:
                        gradient_checkpointing_kwargs["use_reentrant"] = False
                    
                    return original_enable_gradient_checkpointing(self, gradient_checkpointing_kwargs)
                
                transformer_flux.FluxTransformer.enable_gradient_checkpointing = patched_enable_gradient_checkpointing
                print("Successfully patched FluxTransformer gradient checkpointing")
            
            # 修复StableDiffusionModel初始化方法
            from toolkit.stable_diffusion_model import StableDiffusionModel
            if hasattr(StableDiffusionModel, '__init__'):
                original_init = StableDiffusionModel.__init__
                
                def patched_init(self, *args, **kwargs):
                    original_init(self, *args, **kwargs)
                    
                    if hasattr(self, 'unet') and self.unet is not None:
                        model_config = self.model_config
                        train_config = getattr(self, 'train_config', None)
                        
                        gradient_checkpointing_enabled = False
                        if train_config and hasattr(train_config, 'gradient_checkpointing'):
                            gradient_checkpointing_enabled = train_config.gradient_checkpointing
                        
                        if gradient_checkpointing_enabled:
                            if hasattr(self.unet, 'enable_gradient_checkpointing'):
                                print("Enabling UNet gradient checkpointing with use_reentrant=False")
                                self.unet.enable_gradient_checkpointing({"use_reentrant": False})
                
                StableDiffusionModel.__init__ = patched_init
                print("Successfully patched StableDiffusionModel.__init__ for gradient checkpointing")
        
        except ImportError as e:
            print(f"Note: Could not import diffusers modules for patching: {e}")
            print("This is normal if running before model initialization")
        except Exception as e:
            print(f"Warning: Failed to apply gradient checkpointing patches: {e}")
            print("Training will proceed, but may encounter errors if gradient checkpointing is enabled")
            
    except Exception as e:
        print(f"Error fixing diffusers version: {e}")

# Image for training app
training_image = (
    modal.Image.from_registry("nvidia/cuda:12.4.0-devel-ubuntu22.04", add_python="3.12")
    .apt_install("libgl1", "libglib2.0-0")
    .pip_install(
        "python-dotenv",
        "torch", 
        "diffusers[torch]==0.32.2",  # 指定固定版本
        "transformers", 
        "ftfy", 
        "torchvision", 
        "oyaml", 
        "opencv-python", 
        "albumentations",
        "safetensors",
        "lycoris-lora==1.8.3",
        "flatten_json",
        "pyyaml",
        "tensorboard", 
        "kornia", 
        "invisible-watermark", 
        "einops", 
        "accelerate", 
        "toml", 
        "pydantic",
        "omegaconf",
        "k-diffusion",
        "open_clip_torch",
        "timm",
        "prodigyopt",
        "controlnet_aux==0.0.7",
        "bitsandbytes",
        "hf_transfer",
        "lpips", 
        "pytorch_fid", 
        "optimum-quanto", 
        "sentencepiece", 
        "huggingface_hub", 
        "peft"
    )
    .env({
        "HF_HUB_ENABLE_HF_TRANSFER": "1",
        "HF_TOKEN": os.getenv("HF_TOKEN"),
        "CUDA_HOME": "/usr/local/cuda-12"
    })
    # 添加命令以确保diffusers版本正确
    .run_commands("pip uninstall -y diffusers && pip install diffusers==0.32.2")
    # 添加本地目录，必须放在最后或设置copy=True
    .add_local_dir(
        local_path=os.path.dirname(os.path.abspath(__file__)),
        remote_path="/root/ai-toolkit",
        copy=True  # 设置为True以允许后续运行构建步骤
    )
)

# Training app
app = modal.App(
    name="flux-lora-training", 
    image=training_image,
    volumes={
        MOUNT_DIR: model_volume,
        FLUX_MODEL_PATH: FLUX_MODEL_VOLUME
    }
)

# Check if we have DEBUG_TOOLKIT in env
if os.environ.get("DEBUG_TOOLKIT", "0") == "1":
    # Set torch to trace mode
    import torch
    torch.autograd.set_detect_anomaly(True)

import argparse
from toolkit.job import get_job

def print_end_message(jobs_completed, jobs_failed):
    failure_string = f"{jobs_failed} failure{'' if jobs_failed == 1 else 's'}" if jobs_failed > 0 else ""
    completed_string = f"{jobs_completed} completed job{'' if jobs_completed == 1 else 's'}"

    print("")
    print("========================================")
    print("Result:")
    if len(completed_string) > 0:
        print(f" - {completed_string}")
    if len(failure_string) > 0:
        print(f" - {failure_string}")
    print("========================================")


@app.function( 
    # request a GPU with at least 24GB VRAM
    # more about modal GPU's: https://modal.com/docs/guide/gpu
    gpu=modal.gpu.H100(count=1), # L40S,A10G,A100,H100
    # more about modal timeouts: https://modal.com/docs/guide/timeouts
    timeout=7200  # 2 hours, increase or decrease if needed
)
def main(config_file_list_str: str, recover: bool = False, name: str = None):
    # 调用增强版函数修复diffusers版本和梯度检查点问题
    fix_diffusers_version()
    
    # convert the config file list from a string to a list
    config_file_list = config_file_list_str.split(",")

    jobs_completed = 0
    jobs_failed = 0

    print(f"Running {len(config_file_list)} job{'' if len(config_file_list) == 1 else 's'}")

    for config_file in config_file_list:
        try:
            job = get_job(config_file, name)
            
            job.config['process'][0]['training_folder'] = MOUNT_DIR
            os.makedirs(MOUNT_DIR, exist_ok=True)
            print(f"Training outputs will be saved to: {MOUNT_DIR}")
            
            # run the job
            job.run()
            
            # commit the volume after training
            model_volume.commit()
            
            job.cleanup()
            jobs_completed += 1
        except Exception as e:
            print(f"Error running job: {e}")
            jobs_failed += 1
            if not recover:
                print_end_message(jobs_completed, jobs_failed)
                raise e

    print_end_message(jobs_completed, jobs_failed)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    # require at least one config file
    parser.add_argument(
        'config_file_list',
        nargs='+',
        type=str,
        help='Name of config file (eg: person_v1 for config/person_v1.json/yaml), or full path if it is not in config folder, you can pass multiple config files and run them all sequentially'
    )

    # flag to continue if a job fails
    parser.add_argument(
        '-r', '--recover',
        action='store_true',
        help='Continue running additional jobs even if a job fails'
    )

    # optional name replacement for config file
    parser.add_argument(
        '-n', '--name',
        type=str,
        default=None,
        help='Name to replace [name] tag in config file, useful for shared config file'
    )
    args = parser.parse_args()

    # convert list of config files to a comma-separated string for Modal compatibility
    config_file_list_str = ",".join(args.config_file_list)

    main.call(config_file_list_str=config_file_list_str, recover=args.recover, name=args.name)
