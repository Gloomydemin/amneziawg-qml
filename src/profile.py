from pathlib import Path

CONFIG_DIR = Path('/home/phablet/.local/share/amnezia.sysadmin')
PROFILES_DIR = CONFIG_DIR / 'profiles'


def extract_config_from_text(data: str):
    """
    Пытается распарсить amnezia://... или JSON из строки.
    Возвращает {"ok": True} или {"ok": False, "message": "..."}
    """
    try:
        if data.startswith("amnezia://"):
            # Декодировать base64 после amnezia://
            pass
        elif data.strip().startswith("{"):
            # Это JSON
            pass
        else:
            return {"ok": False, "message": "Invalid format"}
        # Сохранить как профиль
        return {"ok": True}
    except Exception as e:
        return {"ok": False, "message": str(e)}

def import_from_file(path: str):
    # уже должна быть у тебя
    pass