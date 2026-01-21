#!/usr/bin/env python3

import sys
import json
import urllib3
import re
import time
import os
from subprocess import Popen, PIPE

SEPARATOR = " <span foreground='#777'>  |  </span>  "
FEED_FILE = "/home/kostia/.feed"

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

def currencies():
    def get_symbol(code):
        codes = {
            "USD": "<span><b>$</b></span>",
            "EUR": "<span><b>€</b></span>",
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
        return f"<span foreground='#EBDBB2'>{res}</span> <span font_size='small'>{change}</span>"

    try:
        url = "https://www.cbr-xml-daily.ru/daily_json.js"
        CURRENCIES = ["USD", "EUR"]
        
        http = urllib3.PoolManager()
        data = json.loads(str(http.request('GET', url).data, "utf8"))
        
        return SEPARATOR.join([format_currency(data["Valute"][v]) for v in CURRENCIES])
    except Exception as e:
        return "Error: currencies"

def kbsync():
    KB_DIR = "/home/kostia/org-roam"
    LOG_FILE = "/tmp/kb_sync.log"
    
    try:
        # Check for conflicts
        with Popen(['git', 'status'], cwd=KB_DIR, stdout=PIPE, stderr=PIPE) as proc:
            status_output = str(proc.stdout.read(), 'utf-8')
            
            if 'rebase in progress' in status_output or 'Unmerged paths' in status_output:
                return """<span><b>KB:</b> <span foreground="#eba0ac">⚠️ CONFLICT</span></span>"""
            
            # Check if there's an error in the log
            if os.path.exists(LOG_FILE):
                with open(LOG_FILE, 'r') as f:
                    log_content = f.read()
                    if 'Failed' in log_content or 'error' in log_content:
                        return """<span><b>KB:</b> <span foreground="#e8db92">⚠️ ERROR</span></span>"""
            
            if 'nothing to commit' in status_output:
                return """<span><b>KB:</b> <span foreground="#01c64d">✅</span></span>"""
            else:
                return """<span><b>KB:</b> <span foreground="#e8db92">✍</span></span>"""
    except Exception as e:
        return """<span><b>KB:</b> <span foreground="#eba0ac">ERROR</span></span>"""

def main():
    feed = f"{currencies()}  {SEPARATOR}   {kbsync()}      "
    
    # Write to feed file
    output_file = sys.argv[1] if len(sys.argv) > 1 else FEED_FILE
    
    try:
        with open(output_file, 'w') as fp:
            fp.write(feed)
        print(feed)
    except Exception as e:
        print(f"Error writing feed: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
