# A RISC-V emulator written in BlitzMax NG

![The thing booting Linux; it has successfully detected the filesystem in the initd image.](AnimatedDemo.webp)
<sub>^^^ The thing booting Linux; it has successfully detected the filesystem in the initd image.</sub>

---

This emulator emulates a single-core RV64IMA machine. It is capable of running NOMMU builds of Linux. Unfortunately, you can't do much with it. NOMMU Linux on RISC-V currently doesn't support loading ELF files (!!!), only FLAT binaries. [ELF support _may_ be added in the future](https://linuxplumbersconf.org/event/4/contributions/386/attachments/298/502/RISC-V-NOMMU-Linux-Plumbers-2019.pdf), but for now it can't run anything really. As for FLAT binaries, they are creted using [elf2flt](https://github.com/uclinux-dev/elf2flt/) -- riscv support is hanging in a pull request there. Sadly, elf2flt is not compatible with the riscv toolchain from the Ubuntu repositories.

You would probably be better off using [QEMU](https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html)

See [this repository](https://github.com/AXKuhta/RISC-V_Emulation_supplementals) for the kernel binaries

[UserspaceEmulator series by Andreas Kling served as great inspiration](https://www.youtube.com/watch?v=NVPavP9DP-c)

### Missing features:
- 8250 serial port still doesn't support input
- There's no actual MMU (as evident from the desription) 
- Some instructions are still missing
