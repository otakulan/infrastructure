#!/usr/bin/env python
import os
import logging
from napalm import get_network_driver
from jinja2 import Environment, FileSystemLoader

logging.basicConfig(level=logging.INFO, format="%(asctime)s: %(levelname)s:%(message)s")
logger = logging.getLogger()

class Switch():
  """
  Representation of a physical Cisco Network Switch
  """
  def __init__(self, ssh_address: str,template: str, index: int, enable_secret: str, admin_secret: str):
    self.ssh_address = ssh_address
    self.template = template
    self.index = index
    self.enable_secret = enable_secret
    self.admin_secret = admin_secret

class AccessSwitch(Switch):
  """
  Representation of a physical Cisco Network Switch
  """
  def __init__(self, ssh_address: str, template: str, index: int, vlan: int, enable_secret: str, admin_secret: str):
    Switch.__init__(self, ssh_address, template, index, enable_secret, admin_secret)
    self.vlan = vlan

enable_secret = os.getenv("CISCO_ENABLE_SECRET")
admin_secret = os.getenv("CISCO_ADMIN_SECRET")
admin_password = os.getenv("CISCO_ADMIN_PASSWORD")

switches = [
  AccessSwitch("172.16.2.31", "OTLAN-AXS-3560G-48.j2", 1, 31, enable_secret, admin_secret), # OTLAN-AXS1
  AccessSwitch("172.16.2.32", "OTLAN-AXS-3560G-48.j2", 2, 32, enable_secret, admin_secret), # OTLAN-AXS2
  AccessSwitch("172.16.2.33", "OTLAN-AXS-3560G-48.j2", 3, 33, enable_secret, admin_secret), # OTLAN-AXS3
  AccessSwitch("172.16.2.34", "OTLAN-AXS-2960G-24.j2", 4, 34, enable_secret, admin_secret), # OTLAN-AXS4
  Switch("172.16.2.30", "OTLAN-D-3560G-24.j2", 1, enable_secret, admin_secret), # OTLAN-D1
]

logger.info("Initializing Jinja templating environment")
env = Environment(
  loader=FileSystemLoader("./templates"),
)

logger.info("Starting switch deployment")
for switch in switches:
  logger.info("Preparing switch")
  template = env.get_template(switch.template)
  cisco_config = template.render(vars(switch))
  driver = get_network_driver('ios')
  # device = driver('172.17.51.253', 'admin', 'ultraconfig', optional_args={'transport': 'telnet', 'port': 5000}) # GNS3 Testing
  device = driver(switch.ssh_address, 'admin', admin_password, timeout=300, optional_args={'secret':admin_password})
  device.open()
  device.load_replace_candidate(config=cisco_config)
  print(device.compare_config())
  input("Press any key to deploy these changes...")
  device.commit_config()
  device.close()
  logger.info("Finished switch deployment")

logger.info("Done deploying all switches")
