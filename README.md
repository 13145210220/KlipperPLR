# PLR Klipper

KlipperPLR(forked from [YUMI_PLR](https://github.com/Yumi-Lab/YUMI_PLR/)) is a simple print recovery system for Klipper, a 3D printer firmware. It allows you to resume prints after a power loss or other types of MCU disconnection interruption. Please note there is no guarantee that it will work in 100% of cases because the Z-axis must not have moved, so do not touch the machine in case of a power cut.

## Prerequisites
having already installed Klipper, Moonraker, and Mainsail (you can use Kiauh).

To install KlipperPLR Klipper, follow the steps below:

## Installation
* Clone the KlipperPLR Klipper repository from GitHub to your local machine:
    ```bash
    git clone https://github.com/bigtreetech/KlipperPLR.git
    cd KlipperPLR
    ./install.sh
    ```

* start-gcode add in your slicer:
    ```bash
    G31
    save_last_file
    SAVE_VARIABLE VARIABLE=was_interrupted VALUE=True
    ```

* end-gcode add in your slicer:
    ```bash
    SAVE_VARIABLE VARIABLE=was_interrupted VALUE=False
    clear_last_file
    G31
    ```
* Before layer change G-gcode add in your slicer:
    ```bash
    LOG_Z
    ```
* To resume printing after a power cut, simply execute the 'RESUME_INTERRUPTED' macro in the MAINSAIL console or via the Macro button on the MAINSAIL dashboard.

## Known Bugs:
The preview image of the gcode file is not rebuilt.
 




