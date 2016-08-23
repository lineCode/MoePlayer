const _ = require('underscore');
const fs = require('fs');

const electron = require('electron');
const {app, ipcMain, Menu, BrowserWindow} = electron;

const devtron = require('devtron')
const config = require('./config');
const client = require('electron-connect').client;

let win;
let session;
let webController;
let dlQueue = [];
let contextMenu;

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

    // Whether To Open Dev Tools
    if (config.debug === true) {
        win.webContents.openDevTools();
        devtron.install();
        client.create(win, {
            sendBounds: false
        });
    }
}

/**
 * Download Item Setting
 * @param  {object} event       event
 * @param  {object} item        download item
 * @param  {object} webContents webContents
 */
function dlSetting(event, item, webContents) {
    let dlItem = dlQueue.shift();
    let suffix = dlItem.save_path.slice(-4);
    // sen -> download success event name
    // fen -> download failed  event name
    let type, sen, fen; 

    switch (suffix) {
        case '.mp3':
            type = 'Song';
            break;
        case '.jpg':
            type = 'Cover';
            break;
        case '.lrc':
            type = 'Lyric';
            break;
    }

    sen = `ipcMain::Download${type}Success`;
    fen = `ipcMain::Download${type}Failed`;

    // Set Savepath
    item.setSavePath(dlItem.save_path);

    // Sync Download Status
    item.once('done', (event, state) => {
        if (state == 'completed') {
            webController.send(sen, {
                song_id: dlItem.song_id,
                song_name: dlItem.song_name
            });
        } else {
            if (type == 'Song') {
                webController.send(fen, {
                    song_id: dlItem.song_id,
                    song_name: dlItem.song_name,
                    state: state
                });
            } else {
                webController.send(fen, state);
            }
        }
    });
}

/**
 * Trigger To Download Cover
 * @param  {object} event event
 * @param  {object} song  songInfo
 */
function dlCover(event, song) {
    let savePath = `${config.save_path}/专辑封面/《${song.song_album}》.jpg`;
    let c = _.assign({
        save_path: savePath
    }, song);

    dlQueue.push(c);

    try {
        let stat = fs.statSync(savePath);
        // If Already Exists
        if (stat)
            webController.send('ipcMain::DownloadCoverSuccess', {});
    }
    catch (e) {
        // If Not Exists
        webController.downloadURL(song.song_cover);
    }
}

/**
 * Trigger To Download Song
 * @param  {object} event event
 * @param  {object} song  songInfo
 */
function dlSong(event, song) {
    let savePath = `${config.save_path}/${song.song_artist}/[${song.song_id}] ${song.song_artist} - ${song.song_name}.mp3`;
    let s = _.assign({
        save_path: savePath
    }, song);

    dlQueue.push(s);

    try {
        let stat = fs.statSync(savePath);
        // If Already Exists
        if (stat)
            webController.send('ipcMain::DownloadSongSuccess', {
                song_id: song.song_id,
                song_name: song.song_name
            });
    }
    catch (e) {
        // If Not Exists
        webController.downloadURL(song.song_url);
    }
}

/**
 * Open Context Menu
 * @param  {object} event    event
 */
function openMenu(event) {
    let template = [{
        label: '搜索这位歌手',
        click: () => {
            webController.send('ipcMain::SearchArtist');
        }
    }, {
        label: '搜索这张专辑',
        click: () => {
            webController.send('ipcMain::SearchAlbum');
        }
    }, {
        label: '下载全部歌曲',
        click: () => {
            webController.send('ipcMain::DownloadAllSongs');
        }
    }];

    !contextMenu && (
        contextMenu = Menu.buildFromTemplate(template)
    );

    contextMenu.popup(win);
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
ipcMain.on('ipcRenderer::DownloadCover', dlCover);
ipcMain.on('ipcRenderer::OpenContextMenu', openMenu);
