#!/usr/bin/env python3

### venv stuff first
python_home = '/home/sjm/pwr'
import sys
import site
python_version = '.'.join(map(str, sys.version_info[:2]))
site_packages = python_home + '/lib/python%s/site-packages' % python_version
site.addsitedir(site_packages)
###

import logging, sys
logging.basicConfig(stream=sys.stderr)

from flask import Flask, render_template
application = Flask(__name__)

@application.route('/')
def pwr():
    return render_template('pwr.html')

if __name__ == "__main__":
    application.run()
# EOF
