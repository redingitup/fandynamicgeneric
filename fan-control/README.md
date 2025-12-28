# Fan Control for Dell PowerEdge R730xd

Automated fan speed management based on system temperatures.

## Installation

1. Edit fandynamic.conf in the folder
2. Change IDRAC_IP, IDRAC_USER, IDRAC_PASS to match your server
3. Run: sudo cp fandynamic.conf /etc/
4. Run: sudo systemctl start fandynamic.service

## License

MIT License
