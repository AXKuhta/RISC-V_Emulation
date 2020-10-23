# A RISC-V emulator written in BlitzMax NG

![The thing booting Linux; the bug with initcalls returning with interrupts disabled has since been fixed](LinuxHasBeenBooted!.PNG)
<sub>^^^ The thing booting Linux. Bug with "initcall 0x... returned with interrupts disabled" has since been fixed.</sub>

---

This emulator emulates a single-core RV64IMA machine. It is capable of running NOMMU builds of Linux.

You would probably be better off using [QEMU](https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html)

See [this repository](https://github.com/AXKuhta/RISC-V_Emulation_supplementals) for the kernel binaries

[UserspaceEmulator series by Andreas Kling served as great inspiration](https://www.youtube.com/watch?v=NVPavP9DP-c)

### Missing features:
- Some sort of actual I/O; We need to emulate at least an 8250 serial port
- Interrupt support is very very rudimentary
- Some instructions are still missing
