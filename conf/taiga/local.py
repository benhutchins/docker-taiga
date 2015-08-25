# If you want to modify this file, I recommend check out docker-taiga-example
# https://github.com/benhutchins/docker-taiga-example
#
# Please modify this file as needed, see the local.py.example for details:
# https://github.com/taigaio/taiga-back/blob/master/settings/local.py.example
#
# Importing docker provides common settings, see:
# https://github.com/benhutchins/docker-taiga/blob/master/docker-settings.py
# https://github.com/taigaio/taiga-back/blob/master/settings/common.py

from .docker import *

PUBLIC_REGISTER_ENABLED = True
DEBUG = False
TEMPLATE_DEBUG = False
