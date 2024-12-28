# Introduction

Hello everyone!

I own a Remeha Calenta Ace boiler and I wanted to get some data out of it to store in Home Assistant. I had two main goals:
1. Use the boiler's status to determine if gas consumption should is for DHW (Domestic Hot Water) or central heating.
2. Get a pressure reading, so I can create an automation that will warn me when it's time to repressurize (i.e. add water to the system)

Initially, I thought the boiler had a serial interface so I connected an ESP8266 D1 Mini to what looked like a serial RJ11 port. Well, I was wrong about
that and it completely fried the D1 Mini. I later found out that older versions of the Calenta did have a serial interface, but mine is a newer Calenta
Ace and apparently that has a CAN interface. One of the lines on a CAN bus is 24V, so the first thing I found out was that I probably fed that into the
D1 Mini and that's what must have fried it. I started searching for more information and was actually hoping someone had already hooked this up and had a
working solution connecting to the boiler and feeding data into Home Assistant.

Unfortunately, I couldn't find anything... 

So, I set out to find it out myself. A CAN bus? I had never heard of such a thing, but hey, how hard can it be? It turned out not to be exactly trivial,
but I did manage to reach the goals I had set for myself. This Github page contains the scripts I created, as well as some documentation describing how
I got to this result. All documentation can be found on [the Wiki](https://github.com/ronbuist/remeha-can-interface/wiki).

I have also added some information on how to configure Home Assistant to get the data from the boiler.

For Dutch readers: I have already written a few things about this on [this forum message on circuitsonline.net](https://www.circuitsonline.net/forum/view/message/2502136#2502136).

# Disclaimer
Nothing described here is in any way approved or endorsed by Remeha. Connecting anything to the boiler could have unexpected results. I have not encountered any issues, but there is no public documentation by Remeha that states that what is described here, is possible and can be done without any consequences. If you decide to use the methods and software described here, you are doing so on your own risk!

_**All the findings described here are my interpretations and are the result of reverse engineering of the data. The scripts and documentation on this site come with ABSOLUTELY NO WARRANTY!**_
