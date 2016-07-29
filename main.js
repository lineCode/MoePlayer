const electron = require('electron');
const {
	app
} = electron;
const {
	BrowserWindow
} = electron;
const config = require('./config');
const client = require('electron-connect').client;
const powerSaveBlocker = require('electron').powerSaveBlocker;
powerSaveBlocker.start('prevent-app-suspension');

let win;

function createWin() {
	win = new BrowserWindow({
		width: config.width,
		height: config.height,
		resizable: config.resizable,
		webPreferences: {
			backgroundThrottling: false
		}
	});

	win.loadURL(`file://${__dirname}/index.html`);
	win.on('closed', () => {
		win = null;
	});

	// 是否开启调试
	if (config.debug === true) {
		win.webContents.openDevTools();
		client.create(win, {
			sendBounds: false
		});
	}
}

app.on('ready', createWin);

app.on('window-all-closed', () => {
	if (process.platform != 'darwin') {
		app.quit();
	}
});

app.on('activate', () => {
	if (win === null) {
		createWin();
	}
});
