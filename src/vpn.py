import subprocess
import time
import os
import shutil
import base64
import json
import textwrap
import socket


import interface
import daemon


from ipaddress import IPv4Network, IPv4Address
from pathlib import Path

CONFIG_DIR = Path('/home/phablet/.local/share/amneziawg.client')
PROFILES_DIR = CONFIG_DIR / 'profiles'
LOG_DIR = Path('/home/phablet/.cache/amneziawg.client')

LOG_DIR.mkdir(parents=True, exist_ok=True)

class Vpn:
    def __init__(self):
        self._pwd = ''
        # self.wg_tool = 'vendored/wg'  # wg-tools для генерации ключей

    def set_pwd(self, sudo_pwd):
        self._sudo_pwd = sudo_pwd
        self.interface = interface.Interface(sudo_pwd)

    def serve_sudo_pwd(self):
        return subprocess.Popen(['echo', self._sudo_pwd], stdout=subprocess.PIPE)

    def can_use_kernel_module(self):
        # """Проверяем поддержку WireGuard kernel module (для AmneziaWG тоже работает)"""
        if not Path('/usr/bin/sudo').exists():
            return False
        try:
            serve_pwd = self.serve_sudo_pwd()
            subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'link', 'add', 'test_wg0', 'type', 'wireguard'], 
                          stdin=serve_pwd.stdout, check=True)
            serve_pwd = self.serve_sudo_pwd()
            subprocess.run(['/usr/bin/sudo', '-S', 'ip', 'link', 'del', 'test_wg0'], 
                          stdin=serve_pwd.stdout, check=True)
        except subprocess.CalledProcessError:
            return False
        return True

    def _connect(self, profile_name, use_kmod):
        try:
            return self.interface._connect(
                self.get_profile(profile_name), 
                PROFILES_DIR / profile_name / 'config.ini', 
                use_kmod
            )
        except Exception as e:
            return str(e)

    
    def genkey(self):
        return subprocess.check_output(['vendored/wg', 'genkey']).strip().decode()

    def genpubkey(self, privkey):
        p = subprocess.Popen(['vendored/wg', 'pubkey'],
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,)

        stdout, stderr = p.communicate(privkey.encode())
        if p.returncode == 0:
            return stdout.strip().decode()
        return stderr.strip().decode()



    def save_profile(self, profile_name, ip_address, private_key, interface_name,
                 extra_routes, dns_servers, peers,
                 jc=None, jmin=None, jmax=None,
                 s1=None, s2=None, h1=None, h2=None, h3=None, h4=None):
    # """Сохранение профиля с поддержкой AmneziaWG параметров"""

        # --- базовая валидация профиля ---
        if "/" in profile_name:
            return {"ok": False, "message": '"/" is not allowed in profile names'}

        if len(private_key) != 44:
            return {"ok": False, "message": "Private key must be exactly 44 bytes long"}

        _pub = self.genpubkey(private_key)
        if not isinstance(_pub, str):
            _pub = _pub.decode()
        if len(_pub) != 44:
            return {"ok": False, "message": "Bad private key: " + _pub}

        try:
            IPv4Network(ip_address, strict=False)
        except Exception as e:
            return {"ok": False, "message": "Bad ip address: " + str(e)}

        try:
            base64.b64decode(private_key)
        except Exception:
            return {"ok": False, "message": "Bad private key"}

        # --- нормализация AmneziaWG параметров (строки из QML -> int/None) ---
        def _to_int_or_none(v):
            if v is None:
                return None
            if isinstance(v, str):
                v = v.strip()
                if not v:
                    return None
            try:
                return int(v)
            except Exception:
                return None

        jc = _to_int_or_none(jc)
        jmin = _to_int_or_none(jmin)
        jmax = _to_int_or_none(jmax)
        s1 = _to_int_or_none(s1)
        s2 = _to_int_or_none(s2)
        h1 = _to_int_or_none(h1)
        h2 = _to_int_or_none(h2)
        h3 = _to_int_or_none(h3)
        h4 = _to_int_or_none(h4)

        # простая валидация диапазонов
        if jc is not None and not (1 <= jc <= 128):
            return {"ok": False, "message": "Jc must be in range 1–128"}

        if jmin is not None and not (0 <= jmin <= 300):
            return {"ok": False, "message": "Jmin must be in range 0–300"}

        if jmax is not None and not (0 <= jmax <= 3000):
            return {"ok": False, "message": "Jmax must be in range 0–3000"}

        # --- валидация пиров ---
        for peer in peers:
            name = peer.get("name", "")
            key = peer.get("key", "")
            endpoint = peer.get("endpoint", "")
            preshared = peer.get("presharedKey", "")
            allowed_prefixes = peer.get("allowed_prefixes", "")

            if not name:
                return {"ok": False, "message": "Peer name is incomplete"}

            if len(key) != 44:
                return {
                    "ok": False,
                    "message": "Peer key ({name}) must be exactly 44 bytes long".format_map(peer)
                }

            try:
                base64.b64decode(key)
            except Exception:
                return {
                    "ok": False,
                    "message": "Bad peer ({name}) key".format_map(peer)
                }

            if ":" not in endpoint:
                return {
                    "ok": False,
                    "message": 'Bad endpoint ({name}) -- missing ":"'.format_map(peer)
                }

            if len(preshared) > 0 and len(preshared) != 44:
                return {
                    "ok": False,
                    "message": "Preshared key ({name}) must be exactly 44 bytes long".format_map(peer)
                }

            try:
                if preshared:
                    base64.b64decode(preshared)
            except Exception:
                return {
                    "ok": False,
                    "message": "Bad peer ({name}) preshared key".format_map(peer)
                }

            for allowed_prefix in allowed_prefixes.split(","):
                allowed_prefix = allowed_prefix.strip()
                if not allowed_prefix:
                    continue
                try:
                    IPv4Network(allowed_prefix, strict=False)
                except Exception as e:
                    return {
                        "ok": False,
                        "message": (
                            "Bad peer ({name}) prefix ".format_map(peer)
                            + allowed_prefix + ": " + str(e)
                        )
                    }

        # --- extra_routes ---
        if extra_routes:
            for route in extra_routes.split(","):
                route = route.strip()
                if not route:
                    continue
                try:
                    IPv4Network(route, strict=False)
                except Exception as e:
                    return {
                        "ok": False,
                        "message": "Bad route " + route + ": " + str(e)
                    }

        # --- dns_servers ---
        if dns_servers:
            for dns in dns_servers.split(","):
                dns = dns.strip()
                if not dns:
                    continue
                try:
                    IPv4Address(dns)
                except Exception as e:
                    return {
                        "ok": False,
                        "message": "Bad dns " + dns + ": " + str(e)
                    }

        # --- сохранение профиля ---
        PROFILE_DIR = PROFILES_DIR / profile_name
        PROFILE_DIR.mkdir(exist_ok=True, parents=True)

        PRIV_KEY_PATH = PROFILE_DIR / "privkey"
        PROFILE_FILE = PROFILE_DIR / "profile.json"
        CONFIG_FILE = PROFILE_DIR / "config.ini"

        with PRIV_KEY_PATH.open("w") as fd:
            fd.write(private_key)

        profile = {
            "peers": peers,
            "ip_address": ip_address,
            "dns_servers": dns_servers,
            "extra_routes": extra_routes,
            "profile_name": profile_name,
            "private_key": private_key,
            "interface_name": interface_name,
            "jc": jc,
            "jmin": jmin,
            "jmax": jmax,
            "s1": s1,
            "s2": s2,
            "h1": h1,
            "h2": h2,
            "h3": h3,
            "h4": h4,
        }

        with PROFILE_FILE.open("w") as fd:
            json.dump(profile, fd, indent=4, sort_keys=True)

        # --- генерация AmneziaWG-конфига ---
        with CONFIG_FILE.open("w") as fd:
            fd.write("[Interface]\n")
            fd.write("PrivateKey = {private_key}\n".format_map(profile))
            fd.write("Address = {ip_address}/32\n".format_map(profile))

            # AmneziaWG параметры (0 тоже пишем, поэтому проверка на None)
            if jc is not None:
                fd.write(f"Jc = {jc}\n")
            if jmin is not None:
                fd.write(f"Jmin = {jmin}\n")
            if jmax is not None:
                fd.write(f"Jmax = {jmax}\n")
            if s1 is not None:
                fd.write(f"S1 = {s1}\n")
            if s2 is not None:
                fd.write(f"S2 = {s2}\n")
            if h1 is not None:
                fd.write(f"H1 = {h1}\n")
            if h2 is not None:
                fd.write(f"H2 = {h2}\n")
            if h3 is not None:
                fd.write(f"H3 = {h3}\n")
            if h4 is not None:
                fd.write(f"H4 = {h4}\n")

            if dns_servers:
                fd.write("DNS = {dns_servers}\n".format_map(profile))
            fd.write("\n")

            for peer in peers:
                if len(peer.get("presharedKey", "")) > 0:
                    fd.write(textwrap.dedent("""
                    [Peer]
                    PublicKey = {key}
                    AllowedIPs = {allowed_prefixes}
                    Endpoint = {endpoint}
                    PresharedKey = {presharedKey}
                    PersistentKeepalive = 25
                    """.format_map(peer)))
                else:
                    fd.write(textwrap.dedent("""
                    [Peer]
                    PublicKey = {key}
                    AllowedIPs = {allowed_prefixes}
                    Endpoint = {endpoint}
                    PersistentKeepalive = 25
                    """.format_map(peer)))
                fd.write("\n")

        return {"ok": True, "message": "Profile saved successfully"}




    def delete_profile(self, profile):
        PROFILE_DIR = PROFILES_DIR / profile
        try:
            shutil.rmtree(PROFILE_DIR.as_posix())
            return {"ok": True, "message": "Profile deleted"}
        except OSError as e:
            return {"ok": False, "message": "Error deleting profile: " + str(e)}


    

    def get_profile(self, profile):
        with (PROFILES_DIR / profile / 'profile.json').open() as fd:
            data = json.load(fd)
            data.setdefault('interface_name', 'awg0')  # AmneziaWG интерфейс
            return data

    def list_profiles(self):
        profiles = []
        for path in PROFILES_DIR.glob('*/profile.json'):
            with path.open() as fd:
                data = json.load(fd)
                data.setdefault('interface_name', 'awg0')
                data['c_status'] = {}
                profiles.append(data)
        return profiles

# Глобальный экземпляр
instance = Vpn()
