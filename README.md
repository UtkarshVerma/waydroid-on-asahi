# waydroid-on-asahi

Apple Silicon MacBooks are well suited to running Android natively: they are fast ARM64 machines with powerful GPUs. The main catch is that M-series chips use 16 KiB memory pages, while Android historically assumed 4 KiB pages. Android only gained support for 16 KiB page sizes recently,[^1] and the Asahi + Waydroid setup is still niche enough that ready-made images are not generally available.

This repository documents how I built a custom Android image for Waydroid on Asahi Linux. The process is based on [Waydroid's custom image guide](https://docs.waydro.id/faq/using-custom-waydroid-images), the [Waydroid-ATV build instructions](https://github.com/WayDroid-ATV/waydroid-builds/blob/main/BUILDING.md), and [build notes shared by a very helpful contributor on the Asahi IRC](https://paste.sh/o5VtbQ3M#DWggLqDtBk6eomDsVemc-sV3).

## Known issues

- Camera support does not work.

## Building

Android is a large project. On a Google Cloud Platform VM with 32 vCPUs, 32 GiB of memory, and 400 GiB of attached storage, the build took roughly four hours, excluding setup time.

### 1. Install Nix

Install the [Nix package manager](https://nixos.org/download/).

### 2. Clone this repository

```sh
git clone https://github.com/UtkarshVerma/waydroid-on-asahi.git
cd waydroid-on-asahi
```

Optionally configure Git if this is a fresh build machine:

```sh
git config --global user.name "Placebo"
git config --global user.email "placebo@mail.com"
```

### 3. Enter the development shell

The repository provides a `shell.nix` with the required build tools.

```sh
nix-shell
```

### 4. Fetch the Android sources

```sh
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs

repo sync build/make

wget -O - https://raw.githubusercontent.com/WayDroid-ATV/android_vendor_waydroid/lineage-23.0/manifest_scripts/generate-manifest.sh | bash

repo sync -j"$(nproc --all)"
```

`repo sync` may fail partway through, especially on large or unreliable connections. If it does, retry with lower parallelism:

```sh
repo sync -j1 --fail-fast
```

### 5. Fetch Git LFS assets

Some prebuilts are stored through Git LFS and need to be pulled explicitly:

```sh
git -C prebuilts/mesa-tools lfs pull

git -C external/chromium-webview/prebuilt/arm64 lfs install
git -C external/chromium-webview/prebuilt/arm64 lfs pull
```

If the build later fails because of missing prebuilt files, run `git lfs pull` in the relevant repository.

### 6. Apply the Waydroid patches

```sh
. build/envsetup.sh
apply-waydroid-patches
```

### 7. Configure the build for Asahi

Edit `device/waydroid/waydroid/waydroid_arm64_only/lineage_waydroid_arm64_only.mk`.

Optionally remove Google apps by commenting out this line:

```makefile
$(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)
```

Then add the 16 KiB page-size configuration:

```makefile
PRODUCT_NO_BIONIC_PAGE_SIZE_MACRO := true
PRODUCT_MAX_PAGE_SIZE_SUPPORTED := 16384
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := true
```

Next, edit `device/waydroid/waydroid/waydroid_arm64_only/BoardConfig.mk`.

Enable the Asahi Mesa driver and disable `MALLOC_SVELTE`:

```makefile
BOARD_MESA3D_VULKAN_DRIVERS += asahi
BOARD_MESA3D_GALLIUM_DRIVERS += asahi

# MALLOC_SVELTE := true
```

Then edit `device/waydroid/waydroid/device.mk`.

Remove the external camera provider package:

```makefile
android.hardware.camera.provider@2.7-external-service
```

Also remove the unnecessary Vulkan drivers from the non-x86 branch:

```makefile
ifneq ($(filter %_x86 %_x86_64,$(TARGET_PRODUCT)),)
PRODUCT_PACKAGES += \
    vulkan.intel \
    vulkan.intel_hasvk \
    vulkan.radeon \
    vulkan.nouveau
else
    # Remove the unnecessary Vulkan drivers here.
endif
```

Finally, edit `external/ffmpeg/libavcodec/mpegvideo.c` and add `&& ARCH_ARM` to the `ff_mpv_common_init_neon` condition.

### 8. Build the images

```sh
lunch lineage_waydroid_arm64_only-bp2a-userdebug

make systemimage -j"$(nproc --all)"
make vendorimage -j"$(nproc --all)"
```

The system image builds cleanly. The vendor image was more troublesome: the Android build system accepted host tools from `/bin`, but not equivalent tools from `/nix/store`. I did not investigate this deeply and instead installed the offending tools directly on the host OS.

If someone figures out how to fix this properly, contributions would be very welcome. It would make the build much more reproducible across distributions.

[^1]: Android added support for 16 KiB page sizes starting with Android 15.
