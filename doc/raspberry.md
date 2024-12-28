# Raspberry Pi setup

## OS installation
To get the Raspberry Pi OS (Debian Linux based) installed, go to the [Raspberry Pi software site](https://www.raspberrypi.com/software/).
I have used the imager to write the image to the micro SD card, but just use whatever you're most comfortable with. Since the Pi will be
close to the boiler, I didn't want the full desktop version. I installed the 64 bit Lite image, making sure SSH was enabled from the
beginning so I could access the Pi from the network.

There are usually some updates since the OS image was published, so make sure you update the OS:

```
sudo apt-get update && sudo apt-get upgrade
```

## Install can-utils
The BASH script I've made, uses a utility called `candump` to get the data from the CAN bus. For this, we need to install the `can-utils`
package:

```
sudo apt-get install can-utils
```

## USB adapter
After connecting the USB adapter and firing up the Pi, I wanted to be sure the adapter was detected by the OS. The `dmesg` command gave
me the following:

```
[    4.049532] usb 1-1.1.3: new full-speed USB device number 4 using dwc_otg
[    4.152953] usb 1-1.1.3: New USB device found, idVendor=1d50, idProduct=606f, bcdDevice= 0.00
[    4.155668] usb 1-1.1.3: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[    4.157059] usb 1-1.1.3: Product: candleLight USB to CAN adapter
[    4.158456] usb 1-1.1.3: Manufacturer: bytewerk
[    4.159790] usb 1-1.1.3: SerialNumber: XXXXXXXXXXXXXXXXXXXXXXXX
```
This showed me that the USB adapter is recognized by the OS. But how to use it? Support for a CAN bus is through the Linux network layer.
So, we should be seeing a network interface and this would be called `can0`. To check if this is present use `ip addr show can0`. In my
case, I got the following reply.

```
3: can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN group default qlen 10
    link/can 
```

So, the network interface is there, but it is down.

## Activating the USB adapter
The CAN interface can be brought up by using the following command:

```
sudo ip link set dev can0 up type can bitrate 1000000
```

## Use candump to see messages on the bus
After the previous command, I saw the USB adapter coming to life. The LEDs on the adapter start blinking. A good sign! But is there any
data coming in? The `candump` utility gave me the answer:

```
candump can0

  can0  703   [1]  05
  can0  080   [0] 
  can0  382   [8]  00 40 1F 07 FF FF FF 00
  can0  282   [5]  00 74 13 1B 00
  can0  402   [0]  remote request
  can0  402   [8]  0A 01 24 28 08 00 0B 02
  can0  703   [1]  05
  can0  482   [8]  01 01 03 20 FF FF FF 03
  can0  482   [8]  01 03 1B 00 74 13 00 10
  can0  080   [0] 
  can0  382   [8]  00 40 1F 07 FF FF FF 00
  can0  282   [5]  00 74 13 1B 00
  can0  076   [1]  A4
  can0  7E5   [8]  51 0B 00 00 00 80 00 00
  can0  481   [7]  03 20 FF FF FF 01 21
  can0  402   [0]  remote request
  can0  402   [8]  0A 01 24 28 08 00 0B 02
  can0  703   [1]  05
  can0  100   [6]  C8 2B 0A 02 7C 3A
  can0  241   [8]  40 3F 50 00 00 00 00 00
  can0  1C1   [8]  41 3F 50 00 28 00 00 00
  can0  241   [8]  60 00 00 00 00 00 00 00
  can0  1C1   [8]  00 03 01 21 09 11 74 13
  can0  241   [8]  70 00 00 00 00 00 00 00
  can0  1C1   [8]  10 00 03 20 FF FF FF FF
  can0  241   [8]  60 00 00 00 00 00 00 00
  can0  1C1   [8]  00 00 00 00 00 62 13 00
  can0  241   [8]  70 00 00 00 00 00 00 00
  can0  1C1   [8]  10 80 FF FF 00 00 00 00
  can0  241   [8]  60 00 00 00 00 00 00 00
  can0  1C1   [8]  00 00 00 00 00 00 00 00
  can0  241   [8]  70 00 00 00 00 00 00 00
  can0  1C1   [8]  15 00 00 00 00 00 00 00
  can0  080   [0] 
  can0  382   [8]  00 40 1F 07 FF FF FF 00
  can0  282   [5]  00 74 13 1B 00

```

So, there is data coming in. Great! Now let's find out what this data means.
