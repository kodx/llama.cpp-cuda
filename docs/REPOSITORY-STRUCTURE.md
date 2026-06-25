# Repository Structure

```
kodx/llama.cpp-cuda/
├── .github/
│   ├── workflows/
│   │   └── build-cuda.yml          # Main CI/CD workflow for building with CUDA
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md            # Bug report template
│       └── feature_request.md       # Feature request template
│
├── docs/
│   ├── QUICKSTART.md                # Quick start guide for new users
│   ├── GPU-COMPATIBILITY.md         # Comprehensive GPU/CUDA compatibility reference
│   ├── REPOSITORY-STRUCTURE.md      # This file
│   └── TROUBLESHOOTING.md           # Detailed troubleshooting guide
│
├── scripts/
│   ├── test-build.sh                # Local build testing script
│   └── check-releases.sh            # Check for new upstream releases
│
├── README.md                        # Main project documentation
├── LICENSE                          # MIT License
├── CONTRIBUTING.md                  # Contribution guidelines
└── .gitignore                       # Git ignore rules
```

## File Descriptions

### Core Files

#### `.github/workflows/build-cuda.yml`
The heart of the project. This GitHub Actions workflow:
- Runs daily at 00:00 UTC
- Checks for new llama.cpp releases
- Builds llama.cpp with CUDA for 2 versions (12.9 + 13.3), each for 2 architectures (amd64 + arm64)
- CUDA runtime libraries in separate tarball (one-time download)
- Creates GitHub releases with binary artifacts
- Can be manually triggered

**Key features:**
- Matrix: 4 builds (2 CUDA versions × 2 architectures)
- `ubuntu-24.04` for amd64, `ubuntu-24.04-arm` for arm64
- `maximize-build-space` cleanup step for CI runners
- GPU architectures split by CUDA version:
  - 12.9: sm_60, sm_61, sm_62, sm_70, sm_72 (Pascal, Volta)
  - 13.3: sm_75–sm_121 (Turing and newer)
- CPU multi-architecture dispatch: `GGML_CPU_ALL_VARIANTS=ON`, `GGML_BACKEND_DL=ON`
- CUDA .so bundling via `ldd` detection, shipped as separate `cuda-runtime-<ver>-<arch>.tar.gz`
- CUDA Docker images based on Ubuntu 24.04 (instead of 22.04)
- Release body with per-CUDA-version GPU architecture table and driver requirements

#### `README.md`
Main documentation covering:
- Project overview and fork notice
- List of changes from original kodx/llama.cpp-cuda
- Supported CUDA versions and architectures
- Usage instructions with CUDA version selection guide
- System requirements with driver version tables

### Documentation (`docs/`)

#### `QUICKSTART.md`
Step-by-step guide for new users:
1. Determine GPU compute capability
2. Choose correct CUDA version (12.9 vs 13.3)
3. Check driver compatibility
4. Download and extract binaries
5. Run first model

Target audience: Users who want to get started immediately.

#### `GPU-COMPATIBILITY.md`
Comprehensive reference for:
- Full compute capability breakdown by GPU model
- Architecture-to-CUDA-version mapping
- Minimum driver requirements for each CUDA version
- CUDA compatibility matrix
- Recommendations by use case (legacy vs modern GPUs)

Target audience: Users who need to verify compatibility or troubleshoot driver issues.

#### `TROUBLESHOOTING.md`
Detailed solutions for:
- Installation issues
- CUDA runtime problems
- Performance problems
- Build architecture issues (CUDA version mismatch)
- Server issues

Target audience: Users experiencing problems.

### Scripts (`scripts/`)

#### `test-build.sh`
Allows local testing of the build process:
```bash
./scripts/test-build.sh [CUDA_VERSION] [LLAMA_TAG]
```

Supported CUDA versions: 12.9.2, 13.3.0

Features:
- Uses same Docker images and cmake flags as CI
- Includes CPU ALL_VARIANTS and CUDA .so bundling
- Validates CUDA version vs supported architectures
- Creates test tarball for verification
- Useful for development and debugging

#### `check-releases.sh`
Checks for new llama.cpp releases:
```bash
./scripts/check-releases.sh
```

Features:
- Compares upstream vs our latest release
- Shows when builds are needed
- Provides release links

### Issue Templates

#### `bug_report.md`
Structured template for bug reports with:
- System information collection
- Steps to reproduce
- Checklist for common issues
- Required context

#### `feature_request.md`
Template for enhancement suggestions with:
- Clear description format
- Use case explanation
- Implementation ideas
- Feasibility considerations

### Supporting Files

#### `LICENSE`
MIT License covering the build scripts and configuration.
Notes that llama.cpp binaries are under their own license.

#### `CONTRIBUTING.md`
Guidelines for contributors covering:
- How to report issues
- How to suggest improvements
- Development workflow
- Testing procedures
- Pull request process

#### `.gitignore`
Excludes from version control:
- Build artifacts
- Downloaded source
- Temporary files
- OS-specific files

## Workflow Details

### Build Process Flow

```
Scheduled Trigger (00:00 UTC) or Manual Trigger
              ↓
    Check for New Release
              ↓
      [New Release?] ━━━━━━━━━━━→ [No] → Exit
              ↓
            [Yes]
              ↓
    Build Matrix (4 variants)
              ↓
    ┌─────────────────────────┬─────────────────────────┐
    │       CUDA 12.9         │       CUDA 13.3         │
    │   sm_60,61,62,70,72     │   sm_75–sm_121          │
    ├────────────┬────────────┼────────────┬────────────┤
    │   amd64    │   arm64    │   amd64    │   arm64    │
    │ubuntu-24.04│ubuntu-24.04│ubuntu-24.04│ubuntu-24.04│
    │            │  -arm      │            │  -arm      │
    └────────────┴────────────┴────────────┴────────────┘
              ↓
    Docker Build (nvidia/cuda Docker image)
    cmake: GGML_NATIVE=OFF, GGML_BACKEND_DL=ON,
           GGML_CPU_ALL_VARIANTS=ON
              ↓
    Bundle CUDA .so via ldd
              ↓
    Package as Tarball
    llama.cpp-bXXXX-cuda-<ver>-<arch>.tar.gz
              ↓
    Upload Artifact
              ↓
    (all 4 artifacts collected)
              ↓
    Generate SHA256SUMS
              ↓
    Create GitHub Release with one body
              ↓
    Delete old releases (keep last 5)
```

### Architecture Selection Logic

```
CUDA 12.9 (last CUDA 12.x for legacy GPUs):
    Architectures: 60, 61, 62, 70, 72
    (Pascal, Volta — dropped from CUDA 13)
    Driver 525-575

CUDA 13.3 (modern GPUs):
    Architectures: 75, 80, 86, 89, 90, 100, 103, 110, 120, 121
    (Turing, Ampere, Ada, Hopper, Blackwell)
    Driver 580+
```

### Runner strategy

| Arch | Runner | maximize-build-space |
|---|---|---|
| amd64 | ubuntu-24.04 | yes |
| arm64 | ubuntu-24.04-arm | yes |

### CUDA runtime bundling

After the build, `ldd` is run on every binary in `build/bin/` to detect which CUDA
shared libraries are needed. Those `.so` files (libcudart, libcublas, etc.) are copied
into a separate `cuda-runtime-<ver>-<arch>.tar.gz` archive, separate from the llama.cpp
binaries. This allows users to download the CUDA runtime once and reuse it across
llama.cpp builds that use the same CUDA version.

The binaries have RPATH set to `$ORIGIN:$ORIGIN/../cuda-runtime-<ver>`, so they first
look for CUDA libraries in their own directory, then in the sibling `cuda-runtime-<ver>/`
directory, and finally fall back to the system library path. This means both tarballs
should be extracted in the same parent directory.

`libcuda.so` is NOT bundled — it must come from the NVIDIA driver.

## Maintenance

### Regular Tasks

1. **Monitor upstream releases** (automated)
   - Workflow checks daily
   - Builds trigger automatically

2. **Update CUDA versions** (when needed)
   - Check new CUDA Docker image availability
   - Verify architecture support changes
   - Update workflow matrix
   - Test with `test-build.sh`
   - Update all documentation

3. **Review issues** (as needed)
   - Check for build problems
   - Update documentation based on common issues

4. **Update driver/CUDA compatibility tables** (quarterly)
   - Check NVIDIA documentation
   - Update GPU-COMPATIBILITY.md

### Future Enhancements

Potential improvements:
- Add support for ROCm (AMD GPUs)
- Provide Docker images
- Add automated benchmarking
- Support for other GGML projects

## Best Practices

### When Adding New CUDA Versions

1. Verify CUDA Docker image exists
2. Check minimum driver requirements
3. Determine architecture support
4. Update all documentation
5. Test build locally first
6. Update workflow matrix
7. Update README tables

### When Modifying Build Process

1. Test locally with `test-build.sh`
2. Check disk space requirements
3. Verify all binaries are copied
4. Test tarball extraction
5. Validate binary execution
6. Update documentation if needed

### Documentation Updates

Keep these in sync:
- README.md architecture tables
- GPU-COMPATIBILITY.md compatibility matrix
- QUICKSTART.md driver requirements
- Workflow CUDA versions
- REPOSITORY-STRUCTURE.md workflow description
