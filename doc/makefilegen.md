# Using makefilegen.py

Here are the options supported by `makefilegen.py`

| Option | Long Option | Default | Description |
---------|-------------|---------|-------------------------------------|
| -b     | --bscflags  |         | Options to pass to the BSV compiler |
| -B     | --board     | zc702   | Board to generate code for (Mandatory) [bluesim, zedboard, zc702, vc707, kc705, ...]|
| -C     | --constraint|         | Additional constraint files (Optional) |
| -I     | --contentid |         | Specify 64-bit contentid for PCIe designs (Optional) |
| -M     | --make      |         | Run make on the specified targets after generating code (Optional) |
| -O     | --OS        |         | Operating system of platform, inferred from board (Optional) |
| -V     | --verilog   |         | Additional verilog sources to include in hardware synthesis. (Optional) |
| -h2s   | --h2sinterface |      | Hardware to software interface |
| -l     | --clib      |         | Additional C++ libary (Optional) |
| -p     | --project-dir | ./xpsproj | Directory in which to generate files (Optional) |
| -s     | --source    |         | C++ source files (Optional) |
| -s2h   |--s2hinterface |       | Software to hardware interface |
| -t     | --topbsv    |         | Top-level bsv file (Required) |
| -x     | --export    |         | Promote/export named interface from top module (Required) |

