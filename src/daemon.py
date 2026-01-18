import struct
import socket
import subprocess
import time
import os
import sys
import logging

import interface
import vpn

from pathlib import Path

WG_PATH = Path(os.getcwd()) / "vendored/amneziawg"  # ← ИЗМЕНИЛИ путь
LOG_DIR = Path('/home/phablet/.cache/amneziawg.client')  # ← синхронизировали с vpn.py
log = None

def get_preferred_def_route():
    """Находим дефолтный маршрут (без изменений)"""
    metric = 999999999
    ip = None
    for line in open('/proc/net/route').readlines():
        line = line.split()
        if line[1] != '00000000' or not int(line[3], 16) & 2:
            continue
        _ip = socket.inet_ntoa(struct.pack("<L", int(line[2], 16)))
        _metric = int(line[6])
        if _metric > metric:
            continue
        metric = _metric
        ip = _ip
    return ip

def keep_tunnel(profile_name, sudo_pwd):
    """Основной цикл поддержания туннеля"""
    _vpn = vpn.Vpn()
    _vpn.set_pwd(sudo_pwd)

    PROFILE_DIR = vpn.PROFILES_DIR / profile_name
    CONFIG_FILE = PROFILE_DIR / 'config.ini'

    route = get_preferred_def_route()
    profile = _vpn.get_profile(profile_name)
    interface_name = profile['interface_name']
    interface_file = Path('/sys/class/net/') / interface_name
    
    bring_up_interface(interface_name)

    log.info('Setting up tunnel')
    _vpn.interface.config_interface(profile, CONFIG_FILE)
    log.info('Tunnel is up')

    while interface_file.exists():
        new_route = get_preferred_def_route()
        if route == new_route:
            log.debug('Routes did not change, sleeping')
            time.sleep(2)
            continue
        log.info('New route via %s, reconfiguring interface', new_route)
        route = new_route
        _vpn.interface.config_interface(profile, CONFIG_FILE)
    log.info("Interface %s no longer exists. Exiting", interface_name)

def bring_up_interface(interface_name):
    """Запуск amneziawg-go userspace"""
    log.info('Bringing up %s with amneziawg-go', interface_name)
    
    # ← ОСНОВНОЕ ИЗМЕНЕНИЕ: amneziawg-go с флагом -f (foreground)
    p = subprocess.Popen([
        '/usr/bin/sudo', '-E',
        str(WG_PATH / interface_name),  # vendored/amneziawg-arm/wg0 → amneziawg-go
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.DEVNULL,
      env={
          'LOG_LEVEL': 'info',  # логи amneziawg-go
          'WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD': '1',
          'WG_SUDO': '1',
      },
      start_new_session=True,
    )
    
    # Ждем создания интерфейса
    time.sleep(1)
    
    if p.returncode is not None and p.returncode != 0:
        log.error('Failed to execute amneziawg-go')
        try:
            stdout, stderr = p.communicate(timeout=1)
            log.error('stdout: %s', stdout.decode())
            log.error('stderr: %s', stderr.decode())
        except:
            pass
        raise RuntimeError('Failed to start amneziawg-go')

def daemonize():
    """UNIX daemonization (без изменений)"""
    try:
        pid = os.fork()
        if pid > 0:
            sys.exit(0)
    except OSError as e:
        sys.stderr.write("fork #1 failed: %d (%s)\n" % (e.errno, e.strerror))
        sys.exit(1)

    os.chdir('/')
    os.setsid()
    os.umask(0)

    try:
        pid = os.fork()
        if pid > 0:
            sys.exit(0)
    except OSError as e:
        sys.stderr.write("fork #2 failed: %d (%s)\n" % (e.errno, e.strerror))
        sys.exit(1)

    sys.stdout.flush()
    sys.stderr.flush()

if __name__ == '__main__':
    profile_name = sys.argv[1]
    sudo_pwd = sys.argv[2]
    
    # Создаем папку логов
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    
    logging.basicConfig(
        filename=str(LOG_DIR / 'daemon-{}.log'.format(profile_name)),
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(name)s %(message)s'
    )
    log = logging.getLogger()
    
    log.info('Started daemon for %s', profile_name)
    log.info('Using amneziawg-go from %s', WG_PATH)
    
    daemonize()
    log.info('Successfully daemonized')
    
    try:
        keep_tunnel(profile_name, sudo_pwd)
    except Exception as e:
        log.exception('Daemon error: %s', e)
    finally:
        log.info('Daemon exiting')
