const _ = require('underscore');
const fs = require('fs');

const electron = require('electron');
const {app} = electron;
const {ipcMain} = electron;
const {BrowserWindow} = electron;

const config = require('./config');
const client = require('electron-connect').client;

let win;
let session;
let webController;

let songInfo = null;

/**************************************************
 *               Function Definition
 *************************************************/
function createWin() {
	win = new BrowserWindow({
		width: config.width,
		height: config.height,
		resizable: config.resizable,
		webPreferences: {
			backgroundThrottling: false
		}
	});

	webController = win.webContents;
	session = webController.session;

	win.on('closed', () => {
		win = null;
	});

	session.on('will-download', dlSetting);

	win.loadURL(`file://${__dirname}/index.html`);

	// 是否开启调试
	if (config.debug === true) {
		win.webContents.openDevTools();
		client.create(win, {
			sendBounds: false
		});
	}
}

function dlSetting(event, item, webContents) {
	let song = _.assign({}, songInfo);

	// Set Savepath
	item.setSavePath(song.savePath);

	// Sync Download Status
	item.once('done', (event, state) => {
		if (state =='completed') {
			webController.send('ipcMain::DownloadSongSuccess', song.song_name);
		} else {
			webController.send('ipcMain::DownloadSongFailed', state);
		}
	});
}

function dlSong(event, song) {
	songInfo = song;
	songInfo.savePath = `./download/${song.song_artist}/${song.song_artist} - ${song.song_name}.mp3`;

	fs.stat(songInfo.savePath, (err, stats) => {
		// If Already Exists
		if (err === null) {
			webController.send('ipcMain::DownloadSongSuccess', song.song_name);
		// If Not Exists
		} else {
			webController.downloadURL(songInfo.song_url);
		}
	});
}

/**************************************************
 *                 Event Listening
 *************************************************/

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

ipcMain.on('ipcRenderer::DownloadSong', dlSong);
