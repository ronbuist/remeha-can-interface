# Analysis of CAN bus data

## Standards
After looking at several sites with information about the CAN standard, it seems that the Calenta Ace is following
the [CANopen protocol](https://en.wikipedia.org/wiki/CANopen), which is a layer on top of CAN.

## A counter?
The message with ID 076 appears to be a counter. It's one byte and it increases with every message. After reaching
value 255 (0xFF), it resets to 0. OK. That's not very useful for what I'm trying to achieve, so let's ignore this one.

## Date and time
At some point, I looked at [this tutorial](https://www.csselectronics.com/pages/canopen-tutorial-simple-intro) and found
that the message with CAN ID 100 represents the current date and time, as configured in the boiler. There are six bytes
in the message. I found out, that the bytes are sent little endian, meaning we'll have to read from right to left. An example:

```
can0  100   [6]  C8 2B 0A 02 7C 3A
```
* The first four bytes contain the numer of milliseconds since midnight. In this example, reading from right to left, it's
  0x020a2bc8, which is 34221000 milliseconds or 34221 seconds. This is 570 minutes and 21 seconds, or 9 hours, 30 minutes and 21
  seconds. The time is 9:30:21. As you can see, even though the standard specifies the time in milliseconds, the boiler returns
  the time in seconds: the last three digits are always 000.
* The last two bytes hold the number of days since January 1st, 1984. In this example: 0x3a7c, which is 14972 days. Now I could
  do the calculation by hand, but I didn't feel like that and asked Google instead and it gave me December 28, 2024. Which is
  the date I'm writing this.

So, the Calenta Ace sends out the date and time as its set on the device. Slightly more useful than the counter I found earlier,
but still not the information I was looking for. I am pulling this information, though. If anything, it will allow me to see if
the clock on the boiler is still OK.

## Enter SavvyCAN

I created logfiles using `candump` when I performed actions that I hoped would be visible in the data:
* Turning the hot water faucet on, let it run for a while, and switch it off again.
* Change the setpoint for the temperature in one room, so that the boiler would start heating the radiators.
* Repressurizing, adding water, increasing the pressure in the system.

The data just didn't make sense to me, so I looked for a tool that would allow me to analyse the logfiles and search for
meaningful signals in the data. Enter [SavvyCAN](https://www.savvycan.com), which has a "range state" function that can be
used to search for possible signals. This proved to be a really useful tool, allowing me to find two temperature readings,
as well as the relative power the boiler the heater is using.

Please note that this is my interpretation of the data! Basically this is reverse engineering. As far as I know, Remeha
has not published any public documentation allowing me to be certain.

### Setpoint

The boiler's setpoint (the target temperature) can be found in CAN ID 382. It's the second and third byte. An example,
using `candump can0 -tz`:

```
(4168.571293) can0 382 [8] 00 40 1F 07 FF FF FF 00
```

Bytes 2 and 3 are 0x1f40, which is 8000. We need to divide this by 100 to get to the setpoint of 80.00 &deg;C.

### Flow temperature

The flow temperature is the temperature of the water flowing through the boiler. This can be found in CAN ID 282, in the
second and third byte. Example:

```
(5003.564265) can0 282 [5] 30 18 1A 1F 00

```

The flow temperature here is 0x1a18, which translates into 66,80 &deg;C.

### Relative power

As far as I understand, the relative power is a percentage describing how much of its total power the boiler is currently
applying to heat the water flowing through the system. This appears to be in CAN ID 282 as well, in the first byte.

## Pressure

So I found out that temperatures are sent as integers, representing the temperature times 100. On the boiler's display,
the pressure can be seen. For example, 1.5 bar. Could it be, that the pressure is sent as a whole number as well? I
assumed the pressure in the example would be sent as 15 (0x0f). In the logfile I created while repressurizing the system,
could I then see the change in one location? As it turned out, I could!

The data is in CAN ID 1C1. This is a bit tricky, because it seems lots of data is sent using that ID. It is sent in blocks.
An example:

```
 (003.200254)  can0  1C1   [8]  41 3F 50 00 28 00 00 00
 (003.200503)  can0  1C1   [8]  00 03 00 04 09 11 1E 14
 (003.202036)  can0  1C1   [8]  10 00 00 00 FF FF FF FF
 (003.202247)  can0  1C1   [8]  00 00 00 00 00 60 14 00
 (003.202500)  can0  1C1   [8]  10 80 FF FF 00 00 00 00
 (003.202746)  can0  1C1   [8]  00 00 00 00 00 00 00 00
 (003.203005)  can0  1C1   [8]  15 00 00 00 00 00 00 00
```
In this example, the pressure is in the second line, in the sixth byte (value 0x11). This is 17 in decimal and dividing
by 10 gives the pressure of 1.7 bar.

The only reliable way I could think of to get the pressure, is to use the first line of the block as an indicator. I'm
checking if it starts with the bytes `41 3F 50` and if it does, I'll use the sixth byte of the next line with ID 1C1 to
get a pressure reading.

## Status

Initially, I used a combination of the CAN IDs 282 and 382 to determine the boiler status. However, Remeha's
[Installation and Service Manual](https://edge.sitecorecloud.io/bdrthermea1-platform-production-864a/media/Project/RemehaNL/RemehaNL/Documentatie/Consument/01---CV-ketels/Calenta-Ace/Documentatie-voor-installateurs/Installatie--en-servicehandleiding-Calenta-Ace-25ds-28c-35ds-40c.pdf)
has an interesting table on page 96 (table 75): AM012 - status.

Would it be possible to find the numerical status as displayed in the table? I turned to the logfiles to see if I could
find a change from 0 (Standby) to either 3 (in use for central heating) or 4 (in use for domestic hot water). Again, the answer is yes!
The status is in CAN ID 481, in the first byte and it exactly corresponds with the numbers in the table.
