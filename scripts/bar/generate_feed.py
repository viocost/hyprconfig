#!/bin/env python
import sys
import json
import urllib3
import re
import time
from subprocess import Popen, PIPE


SEPARATOR=" <span foreground='#777'>  |  </span>  "

def colorize(text, color):
    """
    Function wraps text in pango markup colored format.
    Color is expected in hex form, i.e. #123456
    """
    if not re_test(r"\#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})", color):
        raise ValueError("Invalid color")
    return f'<span foreground="{color}">{text}</span>'

def re_test(regex, string):
    return bool(re.fullmatch(regex, string))

def covid():
    try:
        country = "Russia"

        url =  f"https://corona.lmao.ninja/v2/countries/{country}"


        http = urllib3.PoolManager()

        data = json.loads(str(http.request('GET', url).data, "utf8"))

        return f"""<span><b>COVID</b> </span> <span font_size="small">{colorize(f"+{data['todayCases']}", '#9b4800')}  {colorize(f"+{data['todayDeaths']}", '#777')} </span> """
    except Exception as e:
        print(e)
        return 'Error: COVID'


#<span foreground="#EBDBB2" font_size="xx-small"> (Rus)</span>


def currencies():

    def get_symbol(code):
        codes = {
            "USD": "<span ><b>$</b></span>",
            "EUR": "<span ><b>€</b></span>",
        }
        if code in codes:
            return codes[code]
        return code

    def format_currency(cur):
        val = float(cur["Value"])
        prev = float(cur["Previous"])
        code = get_symbol(cur["CharCode"])
        res = f"{code} {val}"
        change = colorize(" +%.4f" % abs(val-prev), "#009966") \
            if val > prev else colorize(" -%.4f" % abs(val-prev), "#C90000")
        return f"<span foreground='#EBDBB2'>{res}</span> <span font_size='small'>{change}</span>"


    try:
        country = "Russia"
        if len(sys.argv) > 1:
            country = sys.argv[1]

        url =  f"https://www.cbr-xml-daily.ru/daily_json.js"

        CURRENCIES = ["USD", "EUR"]

        http = urllib3.PoolManager()

        data = json.loads(str(http.request('GET', url).data, "utf8"))

        return(SEPARATOR.join([format_currency(data["Valute"][v]) for v in CURRENCIES]))

    except Exception as e:
        return("Error: currencies" )

def get_time():
    return time.strftime('%H:%M:%S', time.localtime())

def kbsync():
    with Popen(['git status'], cwd="/home/kostia/org-roam", shell=True, stdout=PIPE) as proc:
        if " ".join(str(proc.stdout.read()).split('\n')).find('nothing to commit') >= 0:
            return """<span><b> KB: </b> <span foreground="#01c64d"> ✅ </span></span>"""
        else:
            return """<span> KB <span foreground="#01c64d"> ✍ </span></span>"""

def main():

    #feed = f"{currencies()}  <span>    <span foreground='#777'>        |          </span>     {covid()}</span>"
    feed = f"{currencies()}  {SEPARATOR}   { kbsync() }      "

    if len(sys.argv) < 2:
        print(feed)
        exit()

    with open(sys.argv[1], 'w') as fp:
        fp.write(feed)

if __name__ == "__main__":
    main()
