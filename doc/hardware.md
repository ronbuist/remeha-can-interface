# Hardware
I used the following hardware for this project:
1. [Remeha Calenta Ace boiler](https://www.remeha.nl/product/calenta-ace#Documentatie).
2. Raspberry Pi 3B+.
3. USB CAN bus adapter. I have used [this one](https://nl.aliexpress.com/item/1005004969523882.html).
4. RJ12 cable.

## Pinout
The pinout for the RJ12 cable appears to be:
| Pin   | RJ12          | USB adapter   |
|-------|---------------|---------------|
| 1     | CAN L         | CAN_L         |
| 2     | CAN H         | CAN_H         |
| 3     | not connected | not connected |
| 4     | GND           | AGND          |
| 5     | not connected | not connected |
| 6     | 24V           | not connected |

Please be careful creating the cable! Please measure the voltage on the line before connecting it to the CAN USB adapter. Avoid
connecting the 24V line!

The USB adapter has a jumper marked "RES". With the jumper in place, the CAN bus end of line resistor is active. I have left it
in place and have not had any issues. I'm not entirely sure what the right configuration is...

More information about the physical layer of the CAN bus can be found [here](https://support.enovationcontrols.com/hc/en-us/articles/360038856494-CAN-BUS-Troubleshooting-Guide-with-Video#:~:text=CAN%20Bus%20Termination,with%20the%20device%20power%20off.).
