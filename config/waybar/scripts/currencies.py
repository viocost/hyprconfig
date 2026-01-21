#!/usr/bin/env python3

import sys
import json
import urllib3
import re

def re_test(regex, string):
    return bool(re.fullmatch(regex, string))

def colorize(text, color):
    """
    Function wraps text in pango markup colored format.
    Color is expected in hex form, i.e. #123456
    """
    if not re_test(r"\#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})", color):
        raise ValueError("Invalid color")
    return f'<span foreground="{color}">{text}</span>'

def get_symbol(code):
    codes = {
        "USD": "<b>$</b>",
        "EUR": "<b>€</b>",
        "GBP": "<b>£</b>",
    }
    if code in codes:
        return codes[code]
    return code

def format_currency(cur):
    val = float(cur["Value"])
    prev = float(cur["Previous"])
    code = get_symbol(cur["CharCode"])
    res = f"{code} {val:.2f}"
    change = colorize(f" +{abs(val-prev):.4f}", "#009966") \
        if val > prev else colorize(f" -{abs(val-prev):.4f}", "#C90000")
    return f'<span foreground="#EBDBB2">{res}</span> <span font_size="small">{change}</span>'

try:
    url = "https://www.cbr-xml-daily.ru/daily_json.js"
    CURRENCIES = ["USD", "EUR"]

    http = urllib3.PoolManager()
    data = json.loads(str(http.request('GET', url).data, "utf8"))

    text = " | ".join([format_currency(data["Valute"][v]) for v in CURRENCIES])
    
    # Output in waybar JSON format
    output = {
        "text": text,
        "tooltip": "Currency Exchange Rates",
        "class": "currencies"
    }
    print(json.dumps(output))

except Exception as e:
    output = {
        "text": "Error",
        "tooltip": f"Cannot get currencies: {str(e)}",
        "class": "currencies-error"
    }
    print(json.dumps(output))
