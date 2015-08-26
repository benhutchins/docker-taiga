# Importing common provides default settings, see:
# https://github.com/taigaio/taiga-back/blob/master/settings/common.py
from .common import *

DATABASES = {
    'default': {
        'ENGINE': 'transaction_hooks.backends.postgresql_psycopg2',
        'NAME': os.getenv('TAIGA_DB_NAME'),
        'HOST': os.getenv('POSTGRES_PORT_5432_TCP_ADDR') or os.getenv('TAIGA_DB_HOST'),
        'USER': os.getenv('TAIGA_DB_USER'),
        'PASSWORD': os.getenv('POSTGRES_ENV_POSTGRES_PASSWORD') or os.getenv('TAIGA_DB_PASSWORD')
    }
}

TAIGA_HOSTNAME = os.getenv('TAIGA_HOSTNAME')

SITES['api']['domain'] = TAIGA_HOSTNAME
SITES['front']['domain'] = TAIGA_HOSTNAME

MEDIA_URL  = 'http://' + TAIGA_HOSTNAME + '/media/'
STATIC_URL = 'http://' + TAIGA_HOSTNAME + '/static/'

if os.getenv('TAIGA_SSL').lower() == 'true':
    SITES['api']['scheme'] = 'https'
    SITES['front']['scheme'] = 'https'

    MEDIA_URL  = 'https://' + TAIGA_HOSTNAME + '/media/'
    STATIC_URL = 'https://' + TAIGA_HOSTNAME + '/static/'

SECRET_KEY = os.getenv('TAIGA_SECRET_KEY')
