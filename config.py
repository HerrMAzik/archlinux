#!/usr/bin/env python

import re
import os
import sys


def makepkg():
    CFLAGS = 'CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fstack-protector-strong -fno-plt"'
    NEW_CFLAGS = 'CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"\n'

    CXXFLAGS = 'CXXFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fstack-protector-strong -fno-plt"'
    NEW_CXXFLAGS = 'CXXFLAGS="${CFLAGS}"\n'
    with open('/etc/makepkg.conf') as f:
        lines = f.readlines()
    if CFLAGS in lines:
        idx = lines.index(CFLAGS)
        lines[idx] = NEW_CFLAGS

        if CXXFLAGS in lines:
            idx = lines.index(CXXFLAGS)
            lines[idx] = NEW_CXXFLAGS
        else:
            print('CXXFLAGS not found')
    else:
        print('CFLAGS not found')
        print('CXXFLAGS not found')
    ids = [i for i in range(len(lines)) if re.search('^#?\\s*MAKEFLAGS\\s*=', lines[i])]
    if len(ids) == 1:
        idx = ids[0]
        lines[idx] = 'MAKEFLAGS="-j$(nproc)"\n'
    else:
        print('MAKEFLAGS not found')
    ids = [i for i in range(len(lines)) if re.search('^COMPRESSGZ=', lines[i])]
    if len(ids) == 1:
        idx = ids[0]
        lines[idx] = 'COMPRESSGZ=(pigz -c -f -n)\n'
    else:
        print('COMPRESSGZ not found')
    ids = [i for i in range(len(lines)) if re.search('^COMPRESSBZ2=', lines[i])]
    if len(ids) == 1:
        idx = ids[0]
        lines[idx] = 'COMPRESSBZ2=(pbzip2 -c -f)\n'
    else:
        print('COMPRESSBZ2 not found')
    ids = [i for i in range(len(lines)) if re.search('^COMPRESSXZ=', lines[i])]
    if len(ids) == 1:
        idx = ids[0]
        lines[idx] = 'COMPRESSXZ=(xz -c -z - --threads=0)\n'
    else:
        print('COMPRESSXZ not found')
    ids = [i for i in range(len(lines)) if re.search('^COMPRESSZST=', lines[i])]
    if len(ids) == 1:
        idx = ids[0]
        lines[idx] = 'COMPRESSZST=(zstd -c -z -q - --threads=0)\n'
    else:
        print('COMPRESSZST not found')
    with open('/etc/makepkg.conf', 'w') as f:
        f.writelines(lines)


def pacman():
    with open('/etc/pacman.conf') as f:
        lines = f.readlines()
    ids = [i for i in range(len(lines)) if re.search('^[#\\s]*\\[multilib\\]', lines[i])]
    if len(ids) == 1:
        idx = ids[0]
        lines[idx] = '[multilib]\n'
        idx += 1
        if re.search('^[\\s#]*SigLevel.*', lines[idx]):
            ssi = lines[idx].index('SigLevel')
            lines[idx] = lines[idx][ssi:]
            idx += 1
        if re.search('^[\\s#]*Include.*', lines[idx]):
            ssi = lines[idx].index('Include')
            lines[idx] = lines[idx][ssi:]
            idx += 1
    else:
        if lines[-1] != '\n':
            lines.append('\n')
        lines.append('[multilib]\n')
        lines.append('SigLevel = PackageRequired\n')
        lines.append('Include = /etc/pacman.d/mirrorlist\n')
    with open('/etc/pacman.conf', 'w') as f:
        f.writelines(lines)


def sudo():
    euid = os.geteuid()
    if euid != 0:
        print("Script not started as root. Running sudo...")
        args = ['sudo', sys.executable] + sys.argv + [os.environ]
        os.execlpe('sudo', *args)
    print('Running. Your euid is', euid)


def main():
    sudo()
    makepkg()
    pacman()


if __name__ == '__main__':
    main()
