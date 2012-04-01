Music = {
    activeSong = nil,
    soundPath = 'sound/',
    seekTime = 2,
    badness = 0,
    songLib = {
        hug = {
            goodName = 'bearhug.wav',
            badName = 'bearhug_overlay.wav',
            badOverlay = true,
        },
        map = {
            goodName = 'overworld_light.wav',
            badName = 'overworld_dark.wav',
            badOverlay = false,
        },
    }
}

function _setupSong(songName)
    local song = MOAIUntzSound.new()
    print (Music.soundPath .. songName)
    song:load(Music.soundPath .. songName)
    song:setVolume(0)
    song:setLooping(true)
    song:play()
    return song
end

function Music.init()
    for key, song in pairs(Music.songLib) do
        song.goodSong = _setupSong(song.goodName)
        song.badSong = _setupSong(song.badName)
    end
end

function Music.setSong(name)
    local newSong = Music.songLib[name]

    if newSong == activeSong then
        return
    end

    if activeSong then
        activeSong.goodSong:seekVolume(0, Music.seekTime)
        activeSong.badSong:seekVolume(0, Music.seekTime)
    end

    local goodVolume = 1
    if newSong.badOverlay then
        goodVolume = 1 - Music.badness
    end

    if not activeSong then
        newSong.goodSong:setVolume(1)
    end

    newSong.goodSong:seekVolume(goodVolume, Music.seekTime)
    newSong.badSong:seekVolume(Music.badness, Music.seekTime)

    activeSong = newSong
end

function Music.setBadness(t)
    if activeSong then
        local goodVolume = 1
        if activeSong.badOverlay then
            goodVolume = 1 - Music.badness
        end

        activeSong.goodSong:setVolume(goodVolume)
        activeSong.badSong:setVolume(Music.badness)
    end
end

return Music
