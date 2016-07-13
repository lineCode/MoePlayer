const electron = require('electron');
const {app} = electron;
const {BrowserWindow} = electron;

const config = require('../config');

let win;

function createWin() {
	win = new BrowserWindow({
		width: 800,
		height: 600
	});

	win.loadURL(`file://${__dirname}/index.html`);

	// 调试用控制台
	if (config.debug === true) {
		win.webContents.openDevTools();
	}

	win.on('closed', () => {
		win = null;
	});
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
