# LinkArrivalsBoard
A Sound Transit arrivals board mock-up made in Godot. Supports arrivals for all rail routes operated by Sound Transit (1 Line, 2 Line, T Line, Sounder S & N Lines).

| | | |
|:---:|:---:|:---:|
| <img alt="Arrivals board set to Northgate" src="https://i.imgur.com/MrL0ldI.png"> | <img alt="Arrivals board set to Columbia City with service disruption" src="https://i.imgur.com/VXxdz8n.png"> | <img alt="Setup screen" src="https://i.imgur.com/juxzPWL.png"> |

![Raspberry Pi with display running arrivals board app](https://i.imgur.com/FoXd88i.jpeg)


> warning: potential spaghetti code inside

# Description

This is a [Godot](https://godotengine.org/) 4.3 project. Binaries may or may not exist yet in the releases section of this repo. If not, you will need to launch the Godot project yourself and export to your desired platform. On an older version, a OneBusAway API key was required; however this is no longer required as the app uses a proxy server instead. This proxy server caches requests made to the OneBusAway API for 30 seconds and, as of right now, has a (fairly) strict rate limit. If you would like to use this for your own projects besides simply running an arrivals board, *please run your own proxy server*!

As of v2, it supports more than just the 1 Line: it (should) support all three active Sound Transit light rail lines (1 Line, 2 Line, T Line) as well as the Sounder N and S lines. If there is a major service alert, it should be displayed accordingly.

> Reliability is **not** guaranteed; the proxy server could go down at any moment, the app could experience errors and/or crashes, etc. This is an experiment more than anything!