#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys, time, cgi
import subprocess as sp

import cgitb
cgitb.enable()

COAPC = ['/usr/bin/coap-client', '-m', 'post']
URL_PRE = 'coap://pwr.siu.ro/v1/f/'


def myexec(cmd):
    myout = []
    p = sp.Popen(cmd, shell=False, stdout=sp.PIPE, stderr=sp.STDOUT)
    while True:
        p_out = p.stdout.readline()
        exitcode = p.poll()
        if len(p_out)<1  and exitcode is not None: break
        myout.append(p_out.rstrip())
    return myout

f = cgi.FieldStorage(keep_blank_values=True)

coapc = COAPC[:]
if 'on' in f:
    coapc.append(URL_PRE + 'pwr_on')
elif 'off' in f:
    coapc.append(URL_PRE + 'pwr_off')
else:
    coapc.append(URL_PRE + 'pwr_get')

sys.stdout.write('Status: 200 OK\r\n'
                 'Content-Type: text/plain\r\n'
                 'Cache-Control: no-cache\r\n'
                 '\r\n')
sys.stdout.flush()

c_output = myexec(coapc)

sys.stdout.write('POWER %s\r\n' % (c_output[1].decode('utf-8', 'replace')))
sys.stdout.flush()

sys.exit(0)
# EOF
