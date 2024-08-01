# Link arrivals board OneBusAway API proxy server
# Responses from the OBA API are cached for 30 seconds

import secret
import requests
import time
from datetime import datetime
from io import BytesIO
from zipfile import ZipFile
from flask import Flask, Response, request, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from apscheduler.schedulers.background import BackgroundScheduler

server = Flask(__name__)
limiter = Limiter(
    key_func=get_remote_address,
    app=server,
    default_limits=["300 per hour", "1 per second"],
)

scheduler = BackgroundScheduler()

gtfs_url = "https://www.soundtransit.org/GTFS-rail/40_gtfs.zip"
routes = {
    "40_100479": {}, # 1 line
    # "40_2LINE": [],
    # "40_TLINE": [],
    # "40_SNDR_TL": [], # Sounder S line (seattle - tacoma dome/lakewood)
    # "40_SNDR_EV": [] # Sounder N line (seattle - everett)
}

cache = {

}

def make_request(url):
    cached_request = cache.get(url, [None, 0])
    current_time = int(time.time())
    if (current_time - cached_request[1] < 30):
        print("returning cached request")
        return cached_request[0]

    print("making new request")

    new_request = requests.get(url)
    cached_request[0] = new_request.json()
    cached_request[1] = current_time
    cache[url] = cached_request

    return cached_request[0]

def update_gtfs():
    # get stops data
    archive = ZipFile(BytesIO(requests.get(gtfs_url).content))
    stops_file = archive.open("stops.txt")

    # generate a stop name to stop ID dict
    stop_id_to_name = {}
    for line in stops_file.readlines():
        contents = line.decode('utf-8').split(",")
        id = contents[0]
        name = contents[1]
        stop_id_to_name["40_" + id] = name

    # get list of stops for each relevant route, copy translations to relevant routes
    for route in routes.keys():
        stops_for_route = requests.get(f"https://api.pugetsound.onebusaway.org/api/where/stops-for-route/{route}.json?key={secret.api_key}").json()
        route_dict = routes[route]
        stop_list = stops_for_route['data']['entry']['stopIds']
        for stop_id in stop_list:
            stop_name = stop_id_to_name[stop_id]
            id_list = route_dict.get(stop_name, [])
            id_list.append(stop_id)
            route_dict[stop_name] = id_list

@server.route('/stops/<route>')
def get_stops(route):
    if not route in routes: return Response("The specified route is not tracked on the server", status=400)
    print(routes)
    return list(routes[route])

@server.route('/arrivals/<route>')
def get_arrivals(route):
    if not route in routes: return Response("The specified route is not tracked on the server", status=400)
    stop = request.data.decode()
    if not stop in routes[route]: return Response("The specified stop name does not exist on the route", status=400)

    arrivals = []

    for stop_id in routes[route][stop]:
        response = make_request(f"https://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/{stop_id}.json?key={secret.api_key}")
        if response and response['code'] and response['code'] == 200:
            arrivals += response['data']['entry']['arrivalsAndDepartures']
            #arrivals.update(response['data']['entry']['arrivalsAndDepartures'])


    return arrivals
    #return arrivals[route][stop]


scheduler.add_job(update_gtfs, trigger='interval', days=1, id='update_gtfs', next_run_time=datetime.now())
scheduler.start()
server.run()