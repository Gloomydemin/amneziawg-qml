import logging
import subprocess
import os
from pathlib import Path

WG_PATH = Path(os.getcwd()) / "vendored/amnezia"  # ← ✅ ИЗМЕНИЛИ на amneziawg
log = logging.getLogger(__name__)

class Interface:
    def __init__(self, sudo_pwd):
        self._sudo_pwd = sudo_pwd

    def serve_sudo_pwd(self):
        return subprocess.Popen(['echo', self._sudo_pwd], stdout=subprocess.PIPE)

    def _connect(self, profile, config_file, use_kmod):
        interface_name = profile['interface_name']
        self.disconnect(interface_name)

        if use_kmod:
            # Kernel module логика (оставляем, но AmneziaWG лучше в userspace)
            serve_pwd = self.serve_sudo_pwd()
            subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'link', 'add', interface_name, 'type', 'wireguard'],
                            stdin=serve_pwd.stdout,
                            check=True)
            self.config_interface(profile, config_file)
        else:
            # Userspace AmneziaWG через daemon
            self.start_daemon(profile, config_file)

    def start_daemon(self, profile, config_file):
        # """Запускает daemon.py который сам стартует amneziawg"""
        serve_pwd = self.serve_sudo_pwd()
        p = subprocess.Popen(['/usr/bin/sudo', '-S', '/usr/bin/python3', 'src/daemon.py', 
                             profile['profile_name'], self._sudo_pwd],
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              stdin=serve_pwd.stdout,
                              start_new_session=True,
                            )
        print('Started AmneziaWG daemon for', profile['profile_name'])
        log.info('Started daemon for %s', profile['profile_name'])

    def config_interface(self, profile, config_file):
        # """Конфигурирует интерфейс через wg setconf (работает с amneziawg socket!)"""
        interface_name = profile['interface_name']
        log.info('Configuring AmneziaWG interface %s', interface_name)
        
        serve_pwd = self.serve_sudo_pwd()
        subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'link', 'set', 'down', 'dev', interface_name], 
                      check=False)
        log.info('Interface down')

        # wg setconf awg0 config.ini ← КЛЮЧЕВОЕ: amneziawg-go понимает wg-tools команды!
        serve_pwd = self.serve_sudo_pwd()
        p = subprocess.Popen(['/usr/bin/sudo', '-S', str(WG_PATH),  # vendored/amnezia/awg0
                              'setconf', interface_name, str(config_file)],
                              stdin=serve_pwd.stdout,
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              )
        p.wait()
        log.info('AmneziaWG interface %s configured with %s', interface_name, config_file)
        
        err = p.stderr.read().decode()
        if p.returncode != 0:
            log.error('wg setconf failed!')
            log.error(p.stdout.read().decode())
            log.error(err.strip())
            return err

        log.info('AmneziaWG configuration successful')
        
        # IP адрес
        serve_pwd = self.serve_sudo_pwd()
        subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'address', 'add', 'dev', interface_name, 
                       profile['ip_address'] + '/32'],  # /32 для point-to-point
                        stdin=serve_pwd.stdout,
                        check=True)
        log.info('Address %s set', profile['ip_address'])

        # DNS (prepend в resolv.conf)
        if profile.get('dns_servers'):
            for dns in profile['dns_servers'].split(','):
                dns = dns.strip()
                if not dns:
                    continue
                serve_pwd = self.serve_sudo_pwd()
                subprocess.run(['/usr/bin/sudo', '-S', 'sed', '-i', '1i'+'nameserver '+ dns, 
                               '/run/resolvconf/resolv.conf'],
                               stdin=serve_pwd.stdout,
                               check=True)
                log.info('Added DNS server %s', dns)

        # Поднимаем интерфейс
        serve_pwd = self.serve_sudo_pwd()
        subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'link', 'set', 'up', 'dev', interface_name],
                        stdin=serve_pwd.stdout,
                        check=True)
        log.info('AmneziaWG interface %s UP', interface_name)

        # Дополнительные роуты
        if profile.get('extra_routes'):
            for extra_route in profile['extra_routes'].split(','):
                extra_route = extra_route.strip()
                if not extra_route:
                    continue
                serve_pwd = self.serve_sudo_pwd()
                subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'route', 'add', extra_route, 
                               'dev', interface_name],
                               stdin=serve_pwd.stdout,
                               check=True)
                log.info('Added route %s', extra_route)

    def disconnect(self, interface_name):
        # """Остановка интерфейса"""
        serve_pwd = self.serve_sudo_pwd()
        subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'link', 'del', 'dev', interface_name],
                       stdin=serve_pwd.stdout,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       check=False)

        # Сброс DNS
        serve_pwd = self.serve_sudo_pwd()
        subprocess.run(['/usr/bin/sudo', '-S', 'resolvconf', '-u'],
                       stdin=serve_pwd.stdout,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       check=False)

        log.info('Disconnected %s', interface_name)

    def _get_wg_status(self):
        # """Получаем статус wg/amneziawg через wg show (работает идентично!)"""
        if Path('/usr/bin/sudo').exists():
            serve_pwd = self.serve_sudo_pwd()
            p = subprocess.Popen(['/usr/bin/sudo', '-S', str(WG_PATH), 'show', 'all', 'dump'],
                                 stdin=serve_pwd.stdout,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE,
                                 )
            p.wait()
            if p.returncode != 0:
                log.error('Failed to run wg show all dump')
                return []
            return p.stdout.read().decode().strip().splitlines()
        return []

    def current_status_by_interface(self):
        # """Парсинг статуса (без изменений, формат тот же)"""
        last_interface = None
        data = self._get_wg_status()
        interface_status = {}
        status_by_interface = {}
        
        for line in data:
            parts = line.split('\t')
            iface = parts[0]
            
            if iface != last_interface and interface_status:
                status_by_interface[last_interface] = interface_status
                interface_status = {}

            if len(parts) == 5:
                # Interface строка
                iface, private_key, public_key, listen_port, fwmark = parts
                interface_status['my_privkey'] = private_key
                interface_status['peers'] = []
                last_interface = iface
            elif len(parts) == 9:
                # Peer строка
                iface, public_key, preshared_key, endpoint, allowed_ips, latest_handshake, transfer_rx, transfer_tx, persistent_keepalive = parts
                peer_data = {
                    'public_key': public_key,
                    'rx': transfer_rx,
                    'tx': transfer_tx,
                    'latest_handshake': latest_handshake,
                    'up': int(latest_handshake) > 0 if latest_handshake.isdigit() else False,
                }
                interface_status['peers'].append(peer_data)
                interface_status['peers'] = sorted(interface_status['peers'], key=lambda x: not x['up'])

        if last_interface:
            status_by_interface[last_interface] = interface_status
        return status_by_interface
