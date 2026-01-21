#!/bin/python

import sys
import json
import urllib3

try:
    country = "Russia"
    if len(sys.argv) > 1:
        country = sys.argv[1]

    url =  f"https://corona.lmao.ninja/v2/countries/{country}"


    http = urllib3.PoolManager()

    data = json.loads(str(http.request('GET', url).data, "utf8"))

    print(data)
    exit()
    print("""COVID-19 %s Cases: "\%{F#009966}%s\%{F-}" ; Today: %s | Deaths: %s ; Today: %s | Avtive: %s | Critical: %s | Recovered: %s """ % 
            
            (country, data['cases'],
                data['todayCases'],
                data['deaths'],
                data['todayDeaths'],
                data['active'],
                data['critical'],
                data['recovered']))
except Exception as e:
    print("Cannot get COVID-19 info: %s" % str(e))

