// pragma Singleton
import QtQml 2.12

QtObject {
    // Навигация
    enum PageEnum {
        PageStart,      // 0 - начальная страница
        PageHome,       // 1 - главный экран с подключением
        PageSettings,   // 2 - настройки
        PageWizard,     // 3 - мастер настройки
        PageConfigSource // 4 - выбор источника config
    }
    
    // Состояние VPN
    enum VpnState {
        Disconnected,   // 0
        Connecting,     // 1  
        Connected,      // 2
        Disconnecting   // 3
    }
    
    // Типы туннеля
    enum TunnelMode {
        FullTunnel,     // 0
        SplitTunnel,    // 1
        Off             // 2
    }
}
