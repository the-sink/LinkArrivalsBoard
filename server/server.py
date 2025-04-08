# Link arrivals board OneBusAway API proxy server
# Responses from the OBA API are cached for 30 seconds

import os
import secret
import requests
import time
from datetime import datetime
from io import BytesIO
from zipfile import ZipFile
from flask import Flask, Response, request
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from apscheduler.schedulers.background import BackgroundScheduler
from waitress import serve

server = Flask(__name__)
CORS(server)
limiter = Limiter(
    key_func=get_remote_address,
    app=server,
    default_limits=['600 per hour', '1 per second'],
)

scheduler = BackgroundScheduler()

gtfs_url = 'https://www.soundtransit.org/GTFS-rail/40_gtfs.zip'
routes = {
    '40_100479': {}, # 1 line
    '40_2LINE': {},
    '40_TLINE': {},
    '40_SNDR_TL': {}, # Sounder S line (seattle - tacoma dome/lakewood)
    '40_SNDR_EV': {} # Sounder N line (seattle - everett)
}
route_metadata = {}
cache = {}

def make_request(url):
    cached_request = cache.get(url, [None, 0])
    current_time = int(time.time())
    if (current_time - cached_request[1] < 30):
        return cached_request[0]

    new_request = requests.get(url)
    cached_request[0] = new_request.json()
    cached_request[1] = current_time
    cache[url] = cached_request

    return cached_request[0]

def update_gtfs():
    archive = ZipFile(BytesIO(requests.get(gtfs_url).content))

    # get stops data
    stops_file = archive.open('stops.txt')

    # generate a stop name to stop ID dict
    stop_id_to_name = {}
    for line in stops_file.readlines():
        contents = line.decode('utf-8').split(',')
        id = contents[0]
        name = contents[1]
        stop_id_to_name['40_' + id] = name

    # get list of stops for each relevant route, copy translations to relevant routes
    for route in routes.keys():
        stops_for_route = requests.get(f'https://api.pugetsound.onebusaway.org/api/where/stops-for-route/{route}.json?key={secret.api_key}').json()
        route_dict = routes[route]
        route_dict.clear()
        stop_list = stops_for_route['data']['entry']['stopIds']
        for stop_id in stop_list:
            stop_name = stop_id_to_name[stop_id]
            id_list = route_dict.get(stop_name, [])
            id_list.append(stop_id)
            route_dict[stop_name] = id_list
        time.sleep(0.1)
    
    # get routes metadata
    routes_file = archive.open('routes.txt')
    tracked_route_ids = routes.keys()
    route_metadata.clear()
    for line in routes_file.readlines():
        contents = line.decode('utf-8').split(',')
        agency_id = contents[0]
        route_id = contents[1]
        combined_id = f'{agency_id}_{route_id}'

        if combined_id in tracked_route_ids:
            short_name = contents[2]
            long_name = contents[3]
            desc = contents[5]
            color = contents[7]
            text_color = contents[8].strip()

            route_metadata[combined_id] = {
                'short_name': short_name,
                'long_name': long_name,
                'desc': desc,
                'color': color,
                'text_color': text_color
            }
    print(route_metadata)
    archive.close()

@server.route('/routes')
def get_routes():
    #if not request.headers.get('User-Agent').startswith('GodotEngine'): return Response(status=400)
    return route_metadata

@server.route('/stops/<route>')
def get_stops(route):
    #if not request.headers.get('User-Agent').startswith('GodotEngine'): return Response(status=400)
    if not route in routes: return Response("The specified route is not tracked on the server", status=400)
    return routes[route]

@server.route('/arrivals/<route>')
def get_arrivals(route):
    #if not request.headers.get('User-Agent').startswith('GodotEngine'): return Response(status=400)
    if not route in routes: return Response("The specified route is not tracked on the server", status=400)
    stop = request.args.get('stop') or request.data.decode()
    if not stop in routes[route]: return Response("The specified stop name does not exist on the route", status=400)

    arrivals = []
    for stop_id in routes[route][stop]:
        response = make_request(f'https://api.pugetsound.onebusaway.org/api/where/arrivals-and-departures-for-stop/{stop_id}.json?key={secret.api_key}&minutesAfter=90')
        if response and response['code'] and response['code'] == 200:
            arrivals += response['data']['entry']['arrivalsAndDepartures']
        time.sleep(0.1)
    return arrivals


scheduler.add_job(update_gtfs, trigger='interval', days=1, id='update_gtfs', next_run_time=datetime.now())
scheduler.start()
#serve(server, host='0.0.0.0', port=2053) ONLY UNCOMMENT if you're not using another WSGI server; only http will work