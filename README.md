# My personal mpv config setup

This is a backup of my highly optimized `mpv` multimedia configuration. It is fine-tuned to squeeze the absolute best image quality and frame pacing out of my laptop without causing high CPU load or overheating. 

It drops legacy rendering paths entirely to use the modern `gpu-next` pipeline (via libplacebo), Vulkan under Wayland, and a direct PipeWire audio sync layer.

## ⚠️ Compatibility Check Before You Copy

I built and audited this setup specifically for my machine's hardware capabilities and OS configuration. **If your specs don't match, you will likely get heavy stuttering or dropped frames.** 

Unless you are running a very similar setup, you will need to adjust the video rendering scales and audio pipelines to match your own gear.

### My Machine & OS Baseline:
* **OS / Desktop:** Fedora Linux 44 running native KDE Plasma (Wayland)
* **Kernel:** 7.2.7-200.fc44.x86_64
* **Hardware:** Samsung 750XGK Laptop
* **CPU / GPU:** 12-core Intel Core 5 120U with integrated Intel Graphics
* **Memory:** 16 GiB RAM

---

## 🎯 Hard Requirements

If you want to use this configuration files directly, your system needs to meet these baselines at a minimum:

* **mpv 0.41+** – Essential for the updated `gpu-next` and UI layers to function correctly.
* **Wayland & Vulkan** – The config actively targets `waylandvk`. Running this over an X11 backend or standard OpenGL will cause timing errors.
* **Modern Integrated/Dedicated GPU** – Must have full VA-API hardware decoding support for heavy codecs like AV1 and 10-bit HEVC.
* **Linux Kernel 7.2+** – Needed for the memory and process scheduling handling the video stream.
* **PipeWire** – The audio sync layer relies on native PipeWire mixing.

---

## 🛠️ What's Inside

* **`mpv.conf`:** Next-gen rendering settings, premium mathematical upscalers (`ewa_lanczossharp`), and smart downscaling to keep things smooth.
* **Custom ModernZ UI:** Heavily modified Lua scripts to overhaul the default ModernZ skin layout for cleaner desktop tracking.
* **`input.conf`:** Rebuilt keyboard shortcuts tailored for navigating fast video pipelines.

Feel free to pick through the configs, pull out the scaling algorithms, or adapt the script optimizations for your own system!
