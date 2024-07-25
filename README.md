# LinkArrivalsBoard
A Sound Transit Link light rail station arrivals board mock-up made in Godot

![Sample screenshot](https://i.imgur.com/kGuq9Xm.png)

> warning: potential spaghetti code inside

## Process

* The app downloads a Sound Transit *GTFS Schedule Files* zip file (https://www.soundtransit.org/GTFS-rail/40_gtfs.zip); this stays on the computer as a cached copy for 3 days before a re-download.
* The *stops-for-route* [OneBusAway API](https://developer.onebusaway.org/api/where/methods) endpoint is invoked for a list of stop IDs associated with the relevant route (in this case, the 1 Line).
* A collection of stop IDs associated with station names is built from the GTFS data and *stops-for-route* list obtained above, so that station names (i.e. "Westlake") can be translated to a list of stop IDs to check arrivals for.
* The app enters its "running" loop, where all relevant stop IDs for the currently selected station name are queried against the OneBusAway *arrivals-and-departures-for-stop* endpoint every 30 seconds. Every 5 seconds, the displayed arrival time label (i.e. "5 min") is updated using the last available arrival timestamp and current system timestamp.

## Setup

Create an `oba-api-key` environment variable containing your OneBusAway API key. Info on requesting an API key is available on [Sound Transit's website](https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd#:~:text=OneBusAway%20API%20Library-,Request%20an%20API%20key,-To%20request%20an). Once you have the key set, run the app (in editor is fine; if built and run on a standalone executable it will launch in exclusive fullscreen unless otherwise configured).