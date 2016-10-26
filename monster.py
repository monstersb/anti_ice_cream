#! /usr/bin/env python2
# -*- coding: utf-8 -*-

import argparse
import logging
import ctypes

try:
    import facepp
except ImportError:
    raise ImportError('No API module found')

class antiIceCream(object):
    def __init__(self, api_key, api_secret, group_name = 'anti ice cream'):
        self.api = facepp.API(api_key, api_secret)
        self.group_name = group_name
        self._snap = ctypes.cdll.LoadLibrary('snap.so')
        self._snap.init()
        logging.basicConfig(format = '%(asctime)-15s %(message)s', level = logging.NOTSET)

    def install(self):
        try:
            rs = self.api.group.create(group_name = self.group_name)
            rs = self.api.train.identify(group_name = self.group_name)
            rs = self.api.wait_async(rs['session_id'])
        except facepp.APIError as e:
            logging.error(e.body)
            return e.code
        return 0

    def add(self, name, img):
        try:
            rs = self.api.detection.detect(img = facepp.File(img))
            rs = self.api.person.create(person_name = name, face_id = rs['face'][0]['face_id'])
            rs = self.api.group.add_person(group_name = self.group_name, person_name = name)
            rs = self.api.train.identify(group_name = self.group_name)
            rs = self.api.wait_async(rs['session_id'])
        except facepp.APIError as e:
            logging.error(e.body)
            return e.code
        return 0

    def recognise(self, img):
        try:
            self.snap()
            rs = self.api.recognition.identify(group_name = self.group_name, img = facepp.File(img))
        except facepp.APIError as e:
            logging.error(e.body)
            return []
        result = {'confidence': 0}
        for face in rs['face']:
            for candidate in face['candidate']:
                if candidate['confidence'] > result['confidence']:
                    result = candidate
        if result['confidence'] > 30:
            return result


    def snap(self):
        self._snap.snap()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("cmd", help="Command")
    parser.add_argument("-n", '--name', help="name")
    parser.add_argument("-m", '--image', help="image")
    opts = parser.parse_args()
    yf = antiIceCream('99e47e6c2f649d80e93c53c9837a3e99', 'reeY9XwOHkUBG43MmXWJ4vk0ywRK41St')
    if opts.cmd == 'install':
        yf.install()
    elif opts.cmd == 'add':
        yf.add(opts.name, opts.image)
    elif opts.cmd == 'run':
        while True:
            logging.info(yf.recognise('./ice.png'))

if __name__ == '__main__':
    main()
