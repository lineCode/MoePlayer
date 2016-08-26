const config = {
    // 服务器
    host: 'http://localhost',
    // 端口
    port: 5000,
    // 是否开启调试面板
    debug: false,
    // 是否可以调整窗口大小
    resizable: false,
    // 窗口宽度
    width: 1000,
    // 窗口高度
    height: 640,
    // 每页显示的歌曲数
    num_per_page: 15,
    // 歌曲存储路径
    save_path: './download',
    // 发布配置
    // 详见: https://github.com/electron-userland/electron-packager/blob/master/usage.txt
    release: {
        appName: 'MoePlayer',
        copyright: '©VenDream',
        platform: 'win32',
        arch: 'ia32',
        appVer: '1.0.0',
        packVer: '1.2.7',
        icon: 'assets/icon.ico'
    }
};

module.exports = config;
