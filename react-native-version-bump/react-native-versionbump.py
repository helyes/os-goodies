#!/usr/bin/python2.7
'''
Updates react native android and ios versions based on version number configured in package.json

Playground:
git checkout ios/ShiftCare/Info.plist; git checkout android/app/build.gradle; git checkout package.json; ./versionbump.py ShiftCare 1.99.2
'''
import os.path
import sys
import json
import re
import xml.etree.ElementTree as ElementTree
import plistlib
from collections import OrderedDict

PACKAGE_JSON_PATH = 'package.json'
BUILD_GRADE_PATH = 'android/app/build.gradle'
info_plist_path = None
semver = None

    
def setup():
    '''
    Validates given parameters where 
       - first parameter must be the ios project name
       - second parameter must be a valid semver version number
    '''
    assert len(sys.argv) == 3, "Project name and new version number must be passed. Example: {} MyProject 1.2.3".format(sys.argv[0])
    projectName = sys.argv[1]
    assert re.match("^[a-zA-Z0-9_]{4,}$", sys.argv[1]), "Project name {} must be at elast 4 characters and contain alphanumeric characters only".format(sys.argv[1]) 
    global info_plist_path
    info_plist_path = os.path.join('ios',projectName,'Info.plist')    
    version = sys.argv[2]
    assert re.match("^\\d+\\.\\d+\\.\\d+$", version), "Version {} does not match semver format (1.2.3)".format(version) 
    # Validates if files exist. This is here to keep update transactional, thus if any of the required files are missing, none of them will get updated
    assert os.path.isfile(PACKAGE_JSON_PATH), "File does not exist: {}".format(PACKAGE_JSON_PATH)
    assert os.path.isfile(BUILD_GRADE_PATH), "File does not exist: {}".format(BUILD_GRADE_PATH)
    assert os.path.isfile(info_plist_path), "File does not exist: {}".format(info_plist_path)
    global semver
    semver = Semver(version)
    print '\nUpdating {} version number to {}\n'.format(projectName, semver.version)
    print 'Package json: {}'.format(PACKAGE_JSON_PATH)
    print 'Build gradle: {}'.format(BUILD_GRADE_PATH)
    print 'Info plist: {}'.format(info_plist_path)

class Semver:

    def __init__(self, version):
        '''
        Takes dot separated semver version string (1.2.3)
        '''
        assert version is not None, "Can not parse None version"
        self.version = version.strip()
        assert re.match("^\\d+\\.\\d+\\.\\d+$", self.version), "Version {} does not match semver format (1.2.3)".format(self.version) 
        self.major, self.minor, self.patch = version.split('.')        


def update_package_json(file_path, semver):    
    file = open(file_path, 'r')
    package = file.read()
    file.close()
    package_conf = json.loads(package, object_pairs_hook=OrderedDict)
    version = package_conf['version']
    #print "Package json version: {}".format(version)
    package_conf['version'] = semver.version
    with open(file_path, "w") as text_file:
        text_file.write(json.dumps(package_conf, indent=2, separators=(',', ': '))+'\n')


def update_gradle(file_path, semver):
    file = open(file_path, 'r')
    build_gradle = file.read()
    file.close()
    updated_build_gradle = re.sub(r".*(ext\.versionMajor\s?=)(\s?\d)", r'\1 {}'.format(semver.major),  build_gradle)
    updated_build_gradle = re.sub(r".*(ext\.versionMinor\s?=)(\s?\d)", r'\1 {}'.format(semver.minor),  updated_build_gradle)
    updated_build_gradle = re.sub(r".*(ext\.versionPatch\s?=)(\s?\d)", r'\1 {}'.format(semver.patch),  updated_build_gradle)
    with open(file_path, "w") as text_file:
        text_file.write(updated_build_gradle)

def update_plist(file_path, semver):
    pl = plistlib.readPlist(file_path)
    #print pl["CFBundleShortVersionString"]
    pl["CFBundleShortVersionString"] = semver.version
    plistlib.writePlist(pl, file_path)   

setup()
update_package_json(PACKAGE_JSON_PATH, semver)
update_gradle(BUILD_GRADE_PATH, semver)
update_plist(info_plist_path, semver)
