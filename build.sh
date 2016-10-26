#! /bin/sh

gcc ImageSnap.m -framework Foundation -framework QTKit -framework Cocoa -framework Quartz -shared -o snap.so
