# -*- coding: utf-8 -*-
#
#  peertalk.py
#
# Copyright (C) 2012    David House <davidahouse@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
#
# This script depends on the usbmux python script that you can find here:
# http://code.google.com/p/iphone-dataprotection/source/browse/usbmuxd-python-client/?r=3e6e6f047d7314e41dcc143ad52c67d3ee8c0859
# Also only works with the PeerTalk iOS application that you can find here:
# https://github.com/rsms/peertalk
#

import os
import sys
import usbmux
import struct
import argparse

from queue import Queue
from threading import Thread
from matplotlib import animation
from matplotlib import pyplot as plt


parser = argparse.ArgumentParser()
parser.add_argument(
    "--port",
    help="Communication port",
    type=int,
    default=50444,
)


class PeerTalkThread(Thread):
    def __init__(self, p_sock, out_q):
        self._p_sock = p_sock
        self._out_q = out_q
        self._running = True
        Thread.__init__(self)

    def run(self):
        frame_structure = struct.Struct("! I I I I")
        while self._running:
            try:
                msg = self._p_sock.recv(16)
                if len(msg) > 0:
                    frame = frame_structure.unpack(msg)
                    size = frame[3]
                    msg_data = self._p_sock.recv(size)
                    msg = struct.unpack("Qdddddddddd", msg_data)
                    self._out_q.put(msg)
            except:
                pass

    def stop(self):
        self._running = False


def main(args):
    print("peertalk starting")
    mux = usbmux.USBMux()

    print("Waiting for devices...")
    if not mux.devices:
        mux.process(1.0)
    if not mux.devices:
        print("No device found")

    dev = mux.devices[0]
    print("connecting to device %s" % str(dev))
    p_sock = mux.connect(dev, 50444)
    p_sock.setblocking(0)
    p_sock.settimeout(2)

    q = Queue()
    p_thread = PeerTalkThread(p_sock, q)
    p_thread.start()

    fig = plt.figure()
    ax_1 = fig.add_subplot(3,1,1)
    ax_2 = fig.add_subplot(3,1,2)
    ax_3 = fig.add_subplot(3,1,3)
    
    xs = []
    acc_x = []
    acc_y = []
    acc_z = []
    
    omg_x = []
    omg_y = []
    omg_z = []
    
    rot_x = []
    rot_y = []
    rot_z = []
    
    line_a_x, = ax_1.plot(xs, acc_x)
    line_a_y, = ax_1.plot(xs, acc_y)
    line_a_z, = ax_1.plot(xs, acc_z)
    
    line_o_x, = ax_2.plot(xs, omg_x)
    line_o_y, = ax_2.plot(xs, omg_y)
    line_o_z, = ax_2.plot(xs, omg_z)
    
    line_r_x, = ax_3.plot(xs, rot_x)
    line_r_y, = ax_3.plot(xs, rot_y)
    line_r_z, = ax_3.plot(xs, rot_z)
    
    ax_1.set_title("Live Data Graph")
    ax_1.set_ylabel("Acc")
    
    ax_2.set_ylabel("Omg")
    
    ax_3.set_xlabel("Frame")
    ax_3.set_ylabel("Rot")
    
    def init_animate():
        return line_a_x, line_a_y, line_a_z, line_o_x, line_o_y ,line_o_z, line_r_x, line_r_y ,line_r_z
    
    def animate(frame, q, xs, acc_x, acc_y, acc_z, omg_x, omg_y, omg_z, rot_x, rot_y, rot_z):
        (_, o_x, o_y, o_z, r_x, r_y, r_z, a_x, a_y, a_z, _) = q.get()
        xs.append(frame)
        acc_x.append(a_x)
        acc_y.append(a_y)
        acc_z.append(a_z)
        omg_x.append(o_x)
        omg_y.append(o_y)
        omg_z.append(o_z)
        rot_x.append(r_x)
        rot_y.append(r_y)
        rot_z.append(r_z)
        
        if len(xs) > 50:
            xs.pop(0)
            acc_x.pop(0)
            acc_y.pop(0)
            acc_z.pop(0)
            omg_x.pop(0)
            omg_y.pop(0)
            omg_z.pop(0)
            rot_x.pop(0)
            rot_y.pop(0)
            rot_z.pop(0)
            
        line_a_x.set_xdata(xs)
        line_a_x.set_ydata(acc_x)
        
        line_a_y.set_xdata(xs)
        line_a_y.set_ydata(acc_y)
        
        line_a_z.set_xdata(xs)
        line_a_z.set_ydata(acc_z)
        
        line_o_x.set_xdata(xs)
        line_o_x.set_ydata(omg_x)
        
        line_o_y.set_xdata(xs)
        line_o_y.set_ydata(omg_y)
        
        line_o_z.set_xdata(xs)
        line_o_z.set_ydata(omg_z)
        
        line_r_x.set_xdata(xs)
        line_r_x.set_ydata(rot_x)
        
        line_r_y.set_xdata(xs)
        line_r_y.set_ydata(rot_y)
        
        line_r_z.set_xdata(xs)
        line_r_z.set_ydata(rot_z)
        
        ax_1.set_xlim(min(xs)-1, max(xs)+1)
        ax_1.set_ylim(min(acc_x + acc_y + acc_z)-1, max(acc_x + acc_y + acc_z)+1)
        ax_1.set_xticks(list())
        
        ax_2.set_xlim(min(xs)-1, max(xs)+1)
        ax_2.set_ylim(min(omg_x + omg_y + omg_z)-1, max(omg_x + omg_y + omg_z)+1)
        ax_2.set_xticks(list())
        
        ax_3.set_xlim(min(xs)-1, max(xs)+1)
        ax_3.set_ylim(min(rot_x + rot_y + rot_z)-1, max(rot_x + rot_y + rot_z)+1)
        ax_3.set_xticks(list())
        
        return line_a_x, line_a_y, line_a_z, line_o_x, line_o_y ,line_o_z, line_r_x, line_r_y ,line_r_z
    
    try:
        ani = animation.FuncAnimation(fig, animate, init_func=init_animate, fargs = (q, xs, acc_x, acc_y, acc_z, omg_x, omg_y, omg_z, rot_x, rot_y, rot_z), interval=4, cache_frame_data=False)
        plt.show()
    
    except KeyboardInterrupt:
        p_thread.stop()
        p_thread.join()
        p_sock.close()
        try:
            ani.event_source.stop()
        except:
            pass
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)


if __name__ == "__main__":
    args = parser.parse_args()
    main(args)
