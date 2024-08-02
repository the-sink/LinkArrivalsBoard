# LinkArrivalsBoard
A Sound Transit Link light rail station arrivals board mock-up made in Godot

![Raspberry Pi with display running arrivals board app](https://i.imgur.com/FoXd88i.jpeg)
![Arrivals screen at Westlake](https://i.imgur.com/kGuq9Xm.png)
![Arrivals screen at Columbia City with service disruption](https://i.imgur.com/VXxdz8n.png)
![Setup screen](https://i.imgur.com/juxzPWL.png)

> warning: potential spaghetti code inside


This is a [Godot](https://godotengine.org/) 4.3 project (developed on 4.3.rc1 for now). Binaries may or may not exist yet in the releases section of this repo. If not, you will need to launch the Godot project yourself and export to your desired platform. On an older version, a OneBusAway API key was required; however this is no longer required as the app uses a proxy server instead. This proxy server caches requests made to the OneBusAway API for 30 seconds and, as of right now, has a (fairly) strict rate limit. If you would like to use this for your own projects besides simply running an arrivals board, _*please run your own proxy server*!

As of v2, it supports more than just the 1 Line: it (should) support all three active Sound Transit light rail lines (1 Line, 2 Line, T Line) as well as the Sounder N and S lines.

> Reliability is **not** guaranteed; the proxy server could go down at any moment, the app could experience errors and/or crashes, etc. This is an experiment more than anything!