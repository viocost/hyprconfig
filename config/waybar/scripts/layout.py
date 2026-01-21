#!/usr/bin/env python3
import socket
import json
import subprocess
import sys
import os

KEYBOARD_NAME = os.getenv("KEYBOARD_NAME", "at-translated-set-2-keyboard")

def get_layout():
    """Get current keyboard layout from hyprctl"""
    try:
        result = subprocess.run(
            ["hyprctl", "devices", "-j"],
            capture_output=True,
            text=True,
            check=True
        )
        devices = json.loads(result.stdout)
        
        # Find the specified keyboard
        layout = None
        for keyboard in devices.get("keyboards", []):
            if keyboard.get("name") == KEYBOARD_NAME:
                layout = keyboard.get("active_keymap")
                break
        
        # Fallback to first keyboard if not found
        if not layout and devices.get("keyboards"):
            layout = devices["keyboards"][0].get("active_keymap")
        
        # Map full names to short codes
        layout_map = {
            "English (US)": "US",
            "Russian": "RU",
            "Hebrew": "IL"
        }
        
        if layout:
            short = layout_map.get(layout, layout[:2].upper())
        else:
            short = "??"
        return short
    except Exception as e:
        print(json.dumps({"text": " ??", "tooltip": f"Error: {e}"}), flush=True)
        return "??"

def output_json(layout=None):
    """Output waybar JSON format"""
    if layout is None:
        layout = get_layout()
    data = {
        "text": f" {layout}",
        "tooltip": f"Keyboard Layout: {layout}",
        "class": "layout"
    }
    print(json.dumps(data), flush=True)

def listen_to_hyprland():
    """Listen to Hyprland IPC socket for layout changes"""
    signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    
    if not signature:
        return False
    
    runtime_dir = os.getenv("XDG_RUNTIME_DIR", "/run/user/1000")
    socket_path = f"{runtime_dir}/hypr/{signature}/.socket2.sock"
    
    if not os.path.exists(socket_path):
        return False
    
    try:
        # Connect to Hyprland event socket
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.connect(socket_path)
        
        # Read events line by line
        buffer = b""
        while True:
            data = sock.recv(4096)
            if not data:
                break
            
            buffer += data
            while b"\n" in buffer:
                line, buffer = buffer.split(b"\n", 1)
                event = line.decode("utf-8", errors="ignore")
                
                # activelayout event format: activelayout>>keyboard_name,layout_name
                if event.startswith("activelayout>>"):
                    output_json()
        
        return True
    except Exception:
        return False

def main():
    # Output initial state
    output_json()
    
    # Try to listen to Hyprland events
    if not listen_to_hyprland():
        # Fallback to polling if socket listening fails
        import time
        last_layout = get_layout()
        while True:
            time.sleep(0.5)
            current_layout = get_layout()
            if current_layout != last_layout:
                output_json(current_layout)
                last_layout = current_layout

if __name__ == "__main__":
    main()
