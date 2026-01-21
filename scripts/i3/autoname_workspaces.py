#!/usr/bin/env python3
#
# github.com/justbuchanan/i3scripts
#
# This script listens for i3 events and updates workspace names to show icons
# for running programs.  It contains icons for a few programs, but more can
# easily be added by editing the WINDOW_ICONS list below.
#
# It also re-numbers workspaces in ascending order with one skipped number
# between monitors (leaving a gap for a new workspace to be created). By
# default, i3 workspace numbers are sticky, so they quickly get out of order.
#
# Dependencies
# * xorg-xprop  - install through system package manager
# * i3ipc       - install with pip
# * fontawesome - install with pip
#
# Installation:
# * Download this repo and place it in ~/.config/i3/ (or anywhere you want)
# * Add "exec_always ~/.config/i3/i3scripts/autoname_workspaces.py &" to your i3 config
# * Restart i3: $ i3-msg restart
#
# Configuration:
# The default i3 config's keybindings reference workspaces by name, which is an
# issue when using this script because the "names" are constantly changing to
# include window icons.  Instead, you'll need to change the keybindings to
# reference workspaces by number.  Change lines like:
#   bindsym $mod+1 workspace 1
# To:
#   bindsym $mod+1 workspace number 1

import argparse
import logging
import signal
import sys
import fontawesome as fa
import re
import subprocess as proc
from collections import namedtuple, Counter
from i3ipc import Connection, Event

# A type that represents a parsed workspace "name".
NameParts = namedtuple('NameParts', ['num', 'shortname', 'icons'])


def get_focused_workspaces(i3):
    return [w for w in i3.get_workspaces() if w.focused]


# Takes a workspace 'name' from i3 and splits it into three parts:
# * 'num'
# * 'shortname' - the workspace's name, assumed to have no spaces
# * 'icons' - the string that comes after the
# Any field that's missing will be None in the returned dict
def parse_workspace_name(name):
    m = re.match('(?P<num>\d+):?(?P<shortname>\w+)? ?(?P<icons>.+)?',
                 name).groupdict()
    return NameParts(**m)


# Given a NameParts object, returns the formatted name
# by concatenating them together.
def construct_workspace_name(parts):
    new_name = str(parts.num)
    if parts.shortname or parts.icons:
        new_name += ':'

        if parts.shortname:
            new_name += parts.shortname

        if parts.icons:
            new_name += ' ' + parts.icons + ' '

    return new_name


# Return an array of values for the X property on the given window.
# Requires xorg-xprop to be installed.
def xprop(win_id, property):
    try:
        prop = proc.check_output(
            ['xprop', '-id', str(win_id), property], stderr=proc.DEVNULL)
        prop = prop.decode('utf-8')
        return re.findall('"([^"]*)"', prop)
    except proc.CalledProcessError as e:
        logging.warn("Unable to get property for window '%d'" % win_id)
        return None


# Unicode subscript and superscript numbers
_superscript = "⁰¹²³⁴⁵⁶⁷⁸⁹"
_subscript = "₀₁₂₃₄₅₆₇₈₉"


def _encode_base_10_number(n: int, symbols: str) -> str:
    """Write a number in base 10 using symbols from a given string.

    Examples:
    >>> _encode_base_10_number(42, "0123456789")
    "42"
    >>> _encode_base_10_number(42, "abcdefghij")
    "eb"
    >>> _encode_base_10_number(42, "₀₁₂₃₄₅₆₇₈₉")
    "₄₂"
    """
    return ''.join([symbols[int(digit)] for digit in str(n)])


def format_icon_list(icon_list, icon_list_format='default'):
    if icon_list_format.lower() == 'default':
        # Default (no formatting)
        return ' '.join(icon_list)

    elif icon_list_format.lower() == 'mathematician':
        # Mathematician mode
        # aababa -> a⁴b²
        new_list = []
        for icon, count in Counter(icon_list).items():
            if count > 1:
                new_list.append(icon +
                                _encode_base_10_number(count, _superscript))
            else:
                new_list.append(icon)
        return ' '.join(new_list)

    elif icon_list_format.lower() == 'chemist':
        # Chemist mode
        # aababa -> a₄b₂
        new_list = []
        for icon, count in Counter(icon_list).items():
            if count > 1:
                new_list.append(icon +
                                _encode_base_10_number(count, _subscript))
            else:
                new_list.append(icon)
        return ' '.join(new_list)

    else:
        raise ValueError("Unknown format name for the list of icons: ",
                         icon_list_format)

# Add icons here for common programs you use.  The keys are the X window class
# (WM_CLASS) names (lower-cased) and the icons can be any text you want to
# display.
#
# Most of these are character codes for font awesome:
#   http://fortawesome.github.io/Font-Awesome/icons/
#
# If you're not sure what the WM_CLASS is for your application, you can use
# xprop (https://linux.die.net/man/1/xprop). Run `xprop | grep WM_CLASS`
# then click on the application you want to inspect.
WINDOW_ICONS = {
    'alacritty': '',
    'atom': fa.icons['code'],
    'banshee': fa.icons['play'],
    'blender': fa.icons['cube'],
    'chromium': fa.icons['chrome'],
    'cura': fa.icons['cube'],
    'darktable': fa.icons['image'],
    'discord': fa.icons['discord'],
    'eclipse': fa.icons['code'],
    'emacs': "",
    'eog': fa.icons['image'],
    'evince': fa.icons['file-pdf'],
    'evolution': fa.icons['envelope'],
    'feh': fa.icons['image'],
    'file-roller': fa.icons['compress'],
    'filezilla': fa.icons['server'],
    'firefox': fa.icons['firefox'],
    'firefox-esr': fa.icons['firefox'],
    'gimp': fa.icons['image'],
    'gimp-2.8': fa.icons['image'],
    'gnome-control-center': fa.icons['toggle-on'],
    'gnome-terminal-server': '',
    'google-chrome': '',
    'prusa-slicer': fa.icons['cube'],
    'gpick': fa.icons['eye-dropper'],
    'imv': fa.icons['image'],
    'insomnia': fa.icons['globe'],
    'java': fa.icons['code'],
    'jetbrains-idea': fa.icons['code'],
    'jetbrains-studio': fa.icons['code'],
    'kdenlive': '', 
    'keepassxc': fa.icons['key'],
    'keybase': fa.icons['key'],
    'kicad': fa.icons['microchip'],
    'kitty': '',
    'libreoffice': fa.icons['file-alt'],
    'lua5.1': fa.icons['moon'],
    'mpv': fa.icons['tv'],
    'mupdf': fa.icons['file-pdf'],
    'mysql-workbench-bin': fa.icons['database'],
    'nautilus': fa.icons['copy'],
    'nemo': fa.icons['copy'],
    'neovide': '',
    'openscad': fa.icons['cube'],
    'obs': f'OBS',
    'pavucontrol': fa.icons['volume-up'],
    'postman': fa.icons['space-shuttle'],
    'rhythmbox': fa.icons['play'],
    'robo3t': fa.icons['database'],
    'signal': fa.icons['comment'],
    'slack': fa.icons['slack'],
    'slic3r.pl': fa.icons['cube'],
    'spotify': fa.icons['music'],  # could also use the 'spotify' icon
    'steam': fa.icons['steam'],
    'subl': fa.icons['file-alt'],
    'subl3': fa.icons['file-alt'],
    'sublime_text': fa.icons['file-alt'],
    'thunar': fa.icons['copy'],
    'thunderbird': fa.icons['envelope'],
    'tilix': '',
    'totem': fa.icons['play'],
    'tor': '﨩',
    'urxvt': '',
    'xfce4-terminal': '',
    'xournal': fa.icons['file-alt'],
    'yelp': fa.icons['code'],
    'zenity': fa.icons['window-maximize'],
    'zoom': fa.icons['video'],
}

TERMINAL_WINDOW_ICONS = {
    'npm': '',
    'git': '',
    'python': '',
    'node': '',
    'yarnpkg': 'ﯤ',
    'ts-node': 'ﯤ',
    'vim': '',
    'bpytop': '',
    'telegram': '',
    'pinta': ''
}


# Relying on domain names present in window name. Use browser extension for that
BROWSER_WINDOW_ICONS = {
    "jira": '',
    "youtube.com": '',
    'github.com': '',
    'orui': '囹',
    'facebook.com': '',
    'gmail.com': '',
    'mail.google.com': '',
    'calendar.google.com': '',
    'stackoverflow.com': '',
    'superuser.com': '',
    'contentsquare.com': '',
    'reddit.com': '',
    'quora.com': ''
}


KNOWN_TERMINALS = ["tilix", "urxvt", "alacritty", "tmux", "kitty"]
KNOWN_BROWSERS = ["chromium", "firefox"]

DEFAULT_TERMINAL_ICON=''
DEFAULT_BROWSER_ICON=''
# This icon is used for any application not in the list above
DEFAULT_ICON = '*'


def ensure_window_icons_lowercase():
    global WINDOW_ICONS
    WINDOW_ICONS = {name.lower(): icon for name, icon in WINDOW_ICONS.items()}


def is_terminal_app(wm_class):
    print('wm_class: ',wm_class )

    if wm_class:
        return wm_class in KNOWN_TERMINALS

    return False

def is_browser_app(wm_class):
    if wm_class:
        return wm_class in KNOWN_BROWSERS

    return False



def get_browser_app_icon(cls, wm_names =[] ):
    default_icon = WINDOW_ICONS[cls] if cls in WINDOW_ICONS else DEFAULT_BROWSER_ICON

    if len(wm_names) == 0:
        return default_icon

    for wm_name in wm_names:
        for app, icon in BROWSER_WINDOW_ICONS.items():

            if app in wm_name.lower():
                return icon

    return default_icon


def get_terminal_app_icon(wm_names = []):
    if len(wm_names) == 0:
        return DEFAULT_TERMINAL_ICON
    for wm_name in wm_names:
        for app, icon in TERMINAL_WINDOW_ICONS.items():
            if app in wm_name.lower():
                return icon

    return DEFAULT_TERMINAL_ICON


def icon_for_window(window):
    # Try all window classes and use the first one we have an icon for
    classes = xprop(window.window, 'WM_CLASS')
    names = xprop(window.window, 'WM_NAME')
    if classes != None and len(classes) > 0:
        for cls in classes:
            cls = cls.lower()  # case-insensitive matching
            if is_terminal_app(cls):
                return get_terminal_app_icon(names)

            if is_browser_app(cls):
                return get_browser_app_icon(cls, names)

            if cls in WINDOW_ICONS:
                return WINDOW_ICONS[cls]
    logging.info('No icon available for window with classes: %s' %
                 str(classes))
    return DEFAULT_ICON


def log_error(error_msg):
    try:
        with open("home/kostia/.autoname_workspaces.log", "w") as fp:
            fp.append(error_msg)
    except Exception as e:
        pass


# renames all workspaces based on the windows present
# also renumbers them in ascending order, with one gap left between monitors
# for example: workspace numbering on two monitors: [1, 2, 3], [5, 6]
def rename_workspaces(i3, icon_list_format='default'):
    try: 
        ws_infos = i3.get_workspaces()
        focused_workspaces = get_focused_workspaces(i3)
        prev_output = None
        n = 1
        for ws_index, workspace in enumerate(i3.get_tree().workspaces()):
            ws_info = ws_infos[ws_index]

            name_parts = parse_workspace_name(workspace.name)
            icon_list = [icon_for_window(w) for w in workspace.leaves()]
            new_icons = format_icon_list(icon_list, icon_list_format)

            # As we enumerate, leave one gap in workspace numbers between each monitor.
            # This leaves a space to insert a new one later.
            if ws_info.output != prev_output and prev_output != None:
                n += 1
            prev_output = ws_info.output

            new_num = name_parts.num
            n += 1

            new_name = construct_workspace_name(
                NameParts(num=new_num,
                        shortname=name_parts.shortname,
                        icons=new_icons))
            if workspace.name == new_name:
                continue
            i3.command('rename workspace "%s" to "%s"' %
                        (workspace.name, new_name))
        for ws in focused_workspaces:
            i3.command(f'workspace number {ws.num}')
    except Exception as e:
        print("error")

        





# Rename workspaces to just numbers and shortnames, removing the icons.
def on_exit(i3):
    for workspace in i3.get_tree().workspaces():
        name_parts = parse_workspace_name(workspace.name)
        new_name = construct_workspace_name(
            NameParts(num=name_parts.num,
                      shortname=name_parts.shortname,
                      icons=None))
        if workspace.name == new_name:
            continue
        i3.command('rename workspace "%s" to "%s"' %
                   (workspace.name, new_name))
    i3.main_quit()
    sys.exit(0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        "Rename workspaces dynamically to show icons for running programs.")
    parser.add_argument(
        '--norenumber_workspaces',
        action='store_true',
        default=False,
        help=
        "Disable automatic workspace re-numbering. By default, workspaces are automatically re-numbered in ascending order."
    )
    parser.add_argument(
        '--icon_list_format',
        type=str,
        default='default',
        help="The formatting of the list of icons."
        "Accepted values:"
        "    - default: no formatting,"
        "    - mathematician: factorize with superscripts (e.g. aababa -> a⁴b²),"
        "    - chemist: factorize with subscripts (e.g. aababa -> a₄b₂).")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    ensure_window_icons_lowercase()

    i3 = Connection()

    # Exit gracefully when ctrl+c is pressed
    for sig in [signal.SIGINT, signal.SIGTERM]:
        signal.signal(sig, lambda signal, frame: on_exit(i3))

    rename_workspaces(i3, icon_list_format=args.icon_list_format)

    # Call rename_workspaces() for relevant window events
    def event_handler(i3, e):
        if e.change in ['new', 'close', 'move', 'title']:
            rename_workspaces(i3, icon_list_format=args.icon_list_format)

    i3.on(Event.WINDOW, event_handler)
    i3.on(Event.WORKSPACE_MOVE, event_handler)
    i3.main()
