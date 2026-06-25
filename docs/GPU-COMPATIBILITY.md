# GPU Compatibility Reference

## Finding Your GPU's Compute Capability

### Method 1: Using nvidia-smi

```bash
nvidia-smi --query-gpu=name,compute_cap --format=csv
```

### Method 2: Check NVIDIA Documentation

Visit: https://developer.nvidia.com/cuda-gpus

### Method 3: Using PyTorch (if installed)

```python
import torch
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"Compute Capability: {torch.cuda.get_device_capability(0)}")
```

## Compute Capability Breakdown

### CUDA 12.9 (legacy — Pascal, Volta)

Minimum driver: Linux **525-575**

| Compute Cap. | Architecture | GPUs |
|---|---|---|
| 6.0 | Pascal — Data Center | Tesla P100 |
| 6.1 / 6.2 | Pascal — Consumer/Pro | GTX 10xx, Titan XP, Titan X (Pascal), Tesla P40 |
| 7.0 | Volta | Tesla V100, Titan V |
| 7.2 | Tegra | Xavier |

### CUDA 13.3 (modern — Turing and newer)

Minimum driver: Linux **580+**

| Compute Cap. | Architecture | GPUs |
|---|---|---|
| 7.5 | Turing | Tesla T4, RTX 2060–2080 Ti, Quadro RTX, GTX 1650/1660 |
| 8.0 | Ampere — Data Center | A100, A30 |
| 8.6 | Ampere — Consumer/Pro | RTX 3050–3090, RTX A-series, A10, A40 |
| 8.9 | Ada Lovelace / Hopper-L | RTX 4060–4090, RTX 6000 Ada, L4, L40, L40S |
| 9.0 | Hopper | H100, H200 |
| 10.0 | Blackwell | B100, B200, GB200 |
| 10.3 | Blackwell Ultra | GB300 |
| 11.0 | Grace Blackwell | DGX Spark |
| 12.0 / 12.1 | Blackwell — Consumer | RTX Pro 6000, RTX 5000 series |

> **Linux only** — NVIDIA drivers on Windows are not bundled with the CUDA toolkit since CUDA 13.1; install the display driver separately from [nvidia.com](https://www.nvidia.com/download/index.aspx).

## Checking Your Driver Version

### Linux
```bash
nvidia-smi
# or
cat /proc/driver/nvidia/version
```

## CUDA Compatibility Matrix

| GPU Architecture | Compute Cap. | CUDA 12.9 | CUDA 13.3 |
|-----------------|--------------|-----------|-----------|
| Pascal (DC)     | 6.0          | ✅        | ❌        |
| Pascal          | 6.1 / 6.2    | ✅        | ❌        |
| Volta           | 7.0          | ✅        | ❌        |
| Tegra           | 7.2          | ✅        | ❌        |
| Turing          | 7.5          | ❌        | ✅        |
| Ampere (DC)     | 8.0          | ❌        | ✅        |
| Ampere          | 8.6          | ❌        | ✅        |
| Ada/Hopper-L    | 8.9          | ❌        | ✅        |
| Hopper          | 9.0          | ❌        | ✅        |
| Blackwell       | 10.0         | ❌        | ✅        |
| Blackwell Ultra | 10.3         | ❌        | ✅        |
| Grace Blackwell | 11.0         | ❌        | ✅        |
| Blackwell (con) | 12.0 / 12.1  | ❌        | ✅        |

## Recommendations by Use Case

### Legacy GPUs (Pascal, Volta — GTX 10xx, Tesla P100, V100)
**Use:** CUDA 12.9
- These architectures were removed from CUDA 13
- Requires driver 525-575
- Builds available for both amd64 and arm64

### Modern GPUs (Turing and newer — RTX 20/30/40/50 series, A100, H100, B200)
**Use:** CUDA 13.3
- Full support for all modern architectures
- Requires driver 580+
- Latest CUDA optimizations

### Latest Hardware (Blackwell GB300, DGX Spark)
**Use:** CUDA 13.3
- Required for sm_103, sm_110, sm_120, sm_121 support
- Latest Blackwell optimizations

### Data Center (A100, H100, B200)
**Use:** CUDA 13.3
- Best performance for data center GPUs
- Support for latest Hopper and Blackwell features

## Troubleshooting

### "CUDA driver version is insufficient"
- Update your NVIDIA driver to meet minimum requirements
- Or download the other CUDA version build:
  - Use CUDA 12.9 if your driver is 525-575
  - Use CUDA 13.3 if your driver is 580+
- See the table above for exact minimum versions

### "No CUDA-capable device detected"
- Check if GPU is properly installed: `nvidia-smi`
- Verify NVIDIA driver is loaded: `lsmod | grep nvidia`
- Check PCIe connection if recent hardware changes

### Performance issues
- Ensure correct CUDA version for your GPU architecture
  - Pascal/Volta → CUDA 12.9
  - Turing+ → CUDA 13.3
- Check GPU utilization: `nvidia-smi dmon`

### Binary not found
- Verify you extracted the entire tarball
- Check permissions: `chmod +x llama-*`
- Ensure you're in the correct directory

## GPU Architecture by CUDA Version

```
CUDA 12.9 (legacy): sm_60, sm_61, sm_62, sm_70, sm_72
CUDA 13.3 (modern): sm_75, sm_80, sm_86, sm_89, sm_90,
                     sm_100, sm_103, sm_110, sm_120, sm_121
```

## Additional Resources

- [NVIDIA CUDA Compatibility Guide](https://docs.nvidia.com/deploy/cuda-compatibility/index.html)
- [CUDA Toolkit, Driver, and Architecture Matrix](https://docs.nvidia.com/datacenter/tesla/drivers/cuda-toolkit-driver-and-architecture-matrix.html)
- [GPU Compute Capability Table](https://developer.nvidia.com/cuda-gpus)
- [NVIDIA Driver Downloads](https://www.nvidia.com/download/index.aspx)
