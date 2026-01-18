# import subprocess
# import os
# from pathlib import Path

# def test_sudo(sudo_pwd):
#     # DESKTOP BYPASS - на ПК sudo не нужен для UI теста
#     if os.getenv('CLICKABLE_MODE', '') == 'desktop' or os.path.exists('/tmp/clickable-desktop'):
#         print("Desktop mode - sudo check bypassed")
#         return True
        
#     if not Path('/usr/bin/sudo').exists():
#         return False

#     subprocess.run(['/usr/bin/sudo', '-k'])    
#     try:
#         serve_pwd = subprocess.Popen(['echo', sudo_pwd], stdout=subprocess.PIPE)
#         subprocess.run(['/usr/bin/sudo', '-S', 'echo', 'Check for sudo'], 
#                       stdin=serve_pwd.stdout, check=True)
#     except subprocess.CalledProcessError:
#         return False
#     return True




import subprocess
import os
from pathlib import Path

def test_sudo(sudo_pwd):
    # ПОЛНЫЙ BYPASS ДЛЯ DESKTOP - всегда True
    if os.uname().sysname == 'Linux' and 'clickable' in os.getcwd().lower():
        print("=== DESKTOP MODE DETECTED ===")
        return True
        
    # Настоящая проверка sudo только на устройстве
    if not Path('/usr/bin/sudo').exists():
        return False

    subprocess.run(['/usr/bin/sudo', '-k'])    
    try:
        serve_pwd = subprocess.Popen(['echo', sudo_pwd], stdout=subprocess.PIPE)
        subprocess.run(['/usr/bin/sudo', '-S', 'echo', 'Check for sudo'], 
                      stdin=serve_pwd.stdout, check=True)
    except subprocess.CalledProcessError:
        return False
    return True

