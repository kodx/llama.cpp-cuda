# Quick Start Guide

Get up and running with llama.cpp CUDA binaries in 5 minutes.

## Prerequisites

1. NVIDIA GPU (see [GPU compatibility](GPU-COMPATIBILITY.md) for supported architectures)
2. NVIDIA driver installed (check with `nvidia-smi`):
   - CUDA 12.9: Driver 525-575
   - CUDA 13.3: Driver 580+
3. Linux x86_64 or aarch64 (Ubuntu 24.04 compatible)

## Step 1: Check Your GPU

```bash
nvidia-smi --query-gpu=name,compute_cap --format=csv
```

This shows your GPU name and compute capability.

**Choosing the right CUDA version:**
- Pascal (6.x), Volta (7.0), Tegra (7.2) → **CUDA 12.9**
- Turing (7.5) and newer → **CUDA 13.3**

## Step 2: Check Your Driver

```bash
nvidia-smi | grep "Driver Version"
```

Compare against minimum requirements:
- CUDA 12.9: Driver 525-575
- CUDA 13.3: Driver 580+

**If your driver is too old, download the other CUDA version build or update your driver.**

## Step 3: Download Binaries

1. Go to [Releases](../../releases/latest)
2. Download both tarballs for your CUDA version and CPU architecture:
   ```bash
   # amd64 host, CUDA 13.3 (modern GPUs)
   wget https://github.com/kodx/llama.cpp-cuda/releases/download/bXXXX/llama.cpp-bXXXX-cuda-13.3-amd64.tar.gz
   wget https://github.com/kodx/llama.cpp-cuda/releases/download/bXXXX/cuda-runtime-13.3-amd64.tar.gz

   # arm64 host, CUDA 12.9 (legacy GPUs)
   wget https://github.com/kodx/llama.cpp-cuda/releases/download/bXXXX/llama.cpp-bXXXX-cuda-12.9-arm64.tar.gz
   wget https://github.com/kodx/llama.cpp-cuda/releases/download/bXXXX/cuda-runtime-12.9-arm64.tar.gz
   ```

**Not sure which CUDA version?** Most users with Turing+ GPUs should use CUDA 13.3.
Users with Pascal/Volta GPUs should use CUDA 12.9.

## Step 4: Extract

```bash
# amd64, CUDA 13.3
tar -xzf llama.cpp-bXXXX-cuda-13.3-amd64.tar.gz
tar -xzf cuda-runtime-13.3-amd64.tar.gz
cd cuda-13.3

# arm64, CUDA 12.9
tar -xzf llama.cpp-bXXXX-cuda-12.9-arm64.tar.gz
tar -xzf cuda-runtime-12.9-arm64.tar.gz
cd cuda-12.9
```

The CUDA runtime libraries are in the sibling `cuda-runtime-<ver>/` directory and are found automatically by the RPATH embedded in the binaries. No additional CUDA toolkit required — only the NVIDIA driver.

> **Tip:** The CUDA runtime tarball is a one-time download per CUDA version. Reuse it across llama.cpp builds that use the same CUDA version.

## Step 5: Download a Model

### Option A: via llama-cli (recommended)

Download and run a model directly from Hugging Face:

```bash
# Downloads and caches the model, then starts inference
./llama-cli -hf ggml-org/gemma-3-1b-it-GGUF
```

The `-hf` flag accepts `<user>/<model>[:quant]` format. The model is stored in the
standard Hugging Face cache directory (`~/.cache/huggingface/`).

### Option B: manual download

Get a GGUF file from [Hugging Face](https://huggingface.co/models?library=gguf):

```bash
# Download using llama-cli (recommended):
# ./llama-cli -hf ggml-org/gemma-3-1b-it-GGUF
# Or manually from Hugging Face: https://huggingface.co/models?library=gguf
```

## Step 6: Run!

### With automatic download (no local file needed)

```bash
# llama-cli downloads and runs the model in one step
./llama-cli -hf ggml-org/gemma-3-1b-it-GGUF
```

### With a local model file

```bash
./llama-cli -m llama-2-7b.Q4_K_M.gguf -p "Hello, how are you?"
```

### Interactive Chat

```bash
./llama-cli -m llama-2-7b.Q4_K_M.gguf --interactive
```

### Start Server

```bash
./llama-server -m llama-2-7b.Q4_K_M.gguf
# Then visit http://localhost:8080 in your browser
```

Or serve directly from Hugging Face:

```bash
./llama-server -hf ggml-org/gemma-3-1b-it-GGUF
```

## Common Options

### Adjust GPU Offloading
```bash
# Offload all layers to GPU (faster)
./llama-cli -m model.gguf -ngl 999

# Offload specific number of layers
./llama-cli -m model.gguf -ngl 32
```

### Change Context Size
```bash
# Use 4K context
./llama-cli -m model.gguf -c 4096

# Use 2K context (saves memory)
./llama-cli -m model.gguf -c 2048
```

### Adjust Temperature
```bash
# More creative (higher temperature)
./llama-cli -m model.gguf --temp 0.9

# More focused (lower temperature)
./llama-cli -m model.gguf --temp 0.5
```

### Set Seed for Reproducibility
```bash
./llama-cli -m model.gguf --seed 42
```

## Verify CUDA is Working

You should see output like:
```
ggml_cuda_init: GGML_CUDA_FORCE_MMQ:   no
ggml_cuda_init: CUDA_USE_TENSOR_CORES: yes
ggml_cuda_init: found 1 CUDA devices:
  Device 0: NVIDIA GeForce RTX 3090, compute capability 8.6
```

If you see this, CUDA is working!

## Troubleshooting

### "CUDA driver version is insufficient"
Your driver is too old. Either:
- Update driver to match your CUDA version
- Or download the other CUDA version build:
  - CUDA 12.9 requires driver 525-575
  - CUDA 13.3 requires driver 580+

### "no CUDA-capable device is detected"
```bash
# Check if GPU is visible
nvidia-smi

# Load NVIDIA modules if needed
sudo modprobe nvidia
```

### Out of memory
- Use smaller model (7B instead of 13B)
- Use more aggressive quantization (Q4_K_M instead of Q8_0)
- Reduce context: `-c 2048`
- Offload fewer layers: `-ngl 32`

### More help
See the [Troubleshooting Guide](TROUBLESHOOTING.md) for detailed solutions.

## Next Steps

- 📖 Read the [full documentation](../README.md)
- 🔧 Check [GPU compatibility](GPU-COMPATIBILITY.md)
- 🎯 Learn more [llama.cpp options](https://github.com/ggml-org/llama.cpp/blob/master/examples/main/README.md)
- 🚀 Run the [server](https://github.com/ggml-org/llama.cpp/tree/master/examples/server)

## Benchmark Your Setup

```bash
# Run benchmark
./llama-bench -m model.gguf

# Save results
./llama-bench -m model.gguf -o json > benchmark.json
```

## Getting Help

- Build issues: [Open an issue](../../issues)
- llama.cpp questions: [llama.cpp discussions](https://github.com/ggml-org/llama.cpp/discussions)

Happy prompting!
