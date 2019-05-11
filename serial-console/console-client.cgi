#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, time, socket, re, string

###########
# Constants

READSZ = 1024
PRINTABLE = string.ascii_letters + string.digits + string.punctuation + ' '


###############
# Configurables

TCP_HOST = 'localhost'
TCP_PORT = 14242

################
# Program begins

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_HOST, TCP_PORT))

sys.stdout.write('Status: 200 OK\r\n'
                 'Content-Type: text/event-stream\r\n'
                 'Cache-Control: no-cache\r\n'
                 '\r\n')
sys.stdout.flush()


buf = b''
while True:
    try:
        d = s.recv(READSZ)
    except:
        d = None

    # Socket was closed?
    if not d: sys.exit(1)

    buf += d
    while True:
        i = buf.find(b'\n')
        if i < 0: break

        out = buf[:i].decode('utf-8', errors='replace')
        buf = buf[i+1:]

        out = out.rstrip('\r')
        out = ''.join(c if c in PRINTABLE else r'\x{0:02x}'.format(ord(c)) for c in out)
        sys.stdout.write('retry: 999999\r\n'
                         'id: %f\r\n'
                         'data: %s\r\n'
                         '\r\n' % (time.time(), out))
        sys.stdout.flush()

# not reached
sys.exit(0)
# EOF
