#!/usr/bin/env python3
import json
import subprocess

def get_block_devices():
    try:
        # Get all block devices in JSON format with necessary columns
        output = subprocess.check_output(
            ["lsblk", "-J", "-o", "NAME,TRAN,MOUNTPOINT,SIZE,LABEL,MODEL,FSTYPE"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8")
        return json.loads(output).get("blockdevices", [])
    except Exception:
        return []

def get_usb_info(device, partitions_info, indent=0):
    """
    Recursively collect info about partitions.
    """
    name = device.get("name")
    label = device.get("label")
    size = device.get("size")
    mountpoint = device.get("mountpoint")
    model = device.get("model")
    
    # Format line
    prefix = "  " * indent + ("└─ " if indent > 0 else "")
    info_parts = [name]
    
    if label:
        info_parts.append(f'"{label}"')
    
    if model and indent == 0:
        info_parts.append(f"[{model}]")
        
    if size:
        info_parts.append(f"({size})")
        
    if mountpoint:
        info_parts.append(f"-> {mountpoint}")

    partitions_info.append(prefix + " ".join(info_parts))
    
    for child in device.get("children", []):
        get_usb_info(child, partitions_info, indent + 1)

def main():
    devices = get_block_devices()
    usb_devices = [d for d in devices if d.get("tran") == "usb"]

    if not usb_devices:
        # Output empty JSON to hide module
        print(json.dumps({"text": "", "tooltip": "", "class": "empty"}))
        return

    count = len(usb_devices)
    tooltip_lines = []

    for dev in usb_devices:
        get_usb_info(dev, tooltip_lines)

    tooltip = "USB Devices:\n" + "\n".join(tooltip_lines)
    
    # Output for Waybar
    output = {
        "text": f" {count}",
        "tooltip": tooltip,
        "class": "connected"
    }
    print(json.dumps(output))

if __name__ == "__main__":
    main()
