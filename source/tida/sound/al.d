/++
    Module for playing sound and music using the OpenAL library.

    Authors: TodNaz
    License: MIT
+/
module tida.sound.al;

/++
    Library initialization.
+/
public void initSoundLibrary() @trusted
{
    import bindbc.openal;

    auto ret = loadOpenAL();

    if(ret == ALSupport.noLibrary)
        throw new Exception("Not load OpenAL!");
}

/++
    Device for playback.
+/
public class Device
{
    import bindbc.openal;

    private
    {
        ALCdevice* device;
        ALCcontext* context;
    }

    /// Automatic context discovery.
    this() @trusted
    {
        this.open();
    }

    /// ditto
    public void open() @trusted
    {
        device = alcOpenDevice(null);

        if(!device) {
            throw new Exception("Not open device!");
        }

        context = alcCreateContext(device,null);

        if(!alcMakeContextCurrent(context)) {
            throw new Exception("Not make context audio!");
        }

        ALfloat[] listenerOri = [ 0.0f, 0.0f, 1.0f, 0.0f, 1.0f, 0.0f ];

        alListener3f(AL_POSITION, 0, 0, 1.0f);
        alListener3f(AL_VELOCITY, 0, 0, 0);
        alListenerfv(AL_ORIENTATION, cast(float*) listenerOri);

        auto error = alGetError();

        if(error != AL_NO_ERROR) {
            throw new Exception("Error make context!");
        }
    }

    /// Close the context.
    public void close() @trusted
    {
        alcMakeContextCurrent(null);
        alcDestroyContext(context);
        alcCloseDevice(device);
    }

    ~this() @trusted
    {
        close();
    }
}

/++
    Sound object.
+/
public class Sound
{
    import bindbc.openal;
    import std.datetime;
    import std.path;

    private
    {
        uint _source;
        uint _buffer;
        ubyte[] _bufferData;

        bool _isPlay;
    }

    /++
        Allocates space for buffer and source.
    +/
    this() @safe
    {
        this.allocateSource();
        this.allocateBuffer();
    }

    /++
        Load a file.
    +/
    public void load(string path) @safe
    {
        switch(path.extension) {
            case ".wav":
                Wav wav = new Wav();
                wav.load(path);

                bindWAV(wav);
            break;

            case ".mp3":
                MP3 mp3 = new MP3();
                mp3.load(path);

                bindWAV(mp3);
            break;

            default:
                throw new Exception("Unknown formt audio.");
        }

        sourceBindBuffer();
    }

    /// Allocates space for source.
    public void allocateSource() @trusted
    {
        alGenSources(1,&_source);

        alSourcef(_source, AL_PITCH, 1.0f);
        alSourcef(_source, AL_GAIN, 1.0f);
        alSource3f(_source, AL_POSITION, 0, 0, 0);
        alSource3f(_source, AL_VELOCITY, 0, 0, 0);
        alSourcei(_source, AL_LOOPING, AL_FALSE);
    }

    /// Do I need to repeat the sample.
    public void loop(bool value) @trusted @property
    {
        alSourcei(_source, AL_LOOPING, value ? AL_TRUE : AL_FALSE);
    }

    /// Alloctes space for buffer.
    public void allocateBuffer() @trusted
    {
        alGenBuffers(1,&_buffer);
    }

    /++
        Attaches WAV format audio data.

        Params:
            wave = WAV format.

        Example:
        ---
        sound.bindWAV(new Wav().load("my.wav"));
        ---
    +/
    public void bindWAV(Wav wave) @trusted
    {
        const format = wave.numChannels > 1 ?
            (wave.bitsPerSample == 8 ? AL_FORMAT_STEREO8 : AL_FORMAT_STEREO16) :
            (wave.bitsPerSample == 8 ? AL_FORMAT_MONO8 : AL_FORMAT_MONO16);

        _bufferData = wave.data;

        alBufferData(_buffer,format,cast(void*) _bufferData,
        cast(int) _bufferData.length, wave.sampleRate);
    }

    /++
        Attaches a buffer to the source.
    +/
    public void sourceBindBuffer() @trusted
    {
        alSourcei(_source, AL_BUFFER, _buffer);
    }

    public void volume(uint volume) @trusted
    in
    {
        assert(volume < 100 && volume > 0);
    }body
    {
        alSourcef(_source,AL_GAIN,cast(float) volume / 100);
    }

    /++
        Plays sound.
    +/
    public void play() @trusted
    {
        alSourcePlay(_source);
    }

    /++
        Stop sound. 
    +/
    public void stop() @trusted
    {
        alSourceStop(_source);
    }

    /++
        Pause sound. 
    +/
    public void pause() @trusted
    {
        alSourcePause(_source);
    }

    /++
        Continues playback.
    +/
    public void resume() @trusted
    {
        alSourcePlay(_source);
    }

    /++
        Calculates the duration of the track.
    +/
    public Duration duration() @trusted
    {
        int size;
        int chn;
        int bits;
        int fq;

        alGetBufferi(_buffer,AL_SIZE,&size);
        alGetBufferi(_buffer,AL_CHANNELS,&chn);
        alGetBufferi(_buffer,AL_BITS,&bits);
        alGetBufferi(_buffer,AL_FREQUENCY,&fq);

        return dur!"seconds"(
            (size * 8 / (chn * bits)) / fq
        );
    }

    /++
        Whether the sound is playing at the moment or not.
    +/
    public bool isPlay() @trusted
    {
        int state;
        alGetSourcei(_source,AL_SOURCE_STATE,&state);

        return state == AL_PLAYING;
    }

    /++
        Is the track paused?
    +/
    public bool isPaused() @trusted
    {
        int state;
        alGetSourcei(_source,AL_SOURCE_STATE,&state);

        return state == AL_PAUSED;
    }

    /++
        Frees memory. After it, allocate space for the buffer 
        and the source when you need to reuse it.
    +/
    public void free() @trusted
    {
        if(_isPlay)
            stop();

        alDeleteSources(1,&_source);
        alDeleteBuffers(1,&_buffer);
        _bufferData = null;
    }

    ~this() @safe
    {
        free();
    }
}

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data = cast(T) (((data & 0xFF) << 8) + bytes[i]);

    return data;
}

/++
    Object describing the audio format WAV.
+/
public class Wav
{
    import std.file;

    public
    {
        ubyte audioFormat; /// Audio format.
        ushort numChannels; /// The number of channels.
        uint sampleRate; /// Channel speed.
        uint byteRate; /// Channel speed. in bytes.
        ushort blockAlign; /// Block Align
        ushort bitsPerSample; /// Significant Bits Per Sample
        ubyte[] data; /// Sound data
    }

    override string toString() @safe const
    {
        import std.conv : to;

        return "Format: "~audioFormat.to!string~"\n"~
               "Channels: "~numChannels.to!string~"\n"~
               "SampleRate: "~sampleRate.to!string~"\n"~
               "ByteRate: "~byteRate.to!string~"\n"~
               "blockAlign: "~blockAlign.to!string~"\n"~
               "bitsPerSample: "~bitsPerSample.to!string~"\n";
    }

    /++
        Loads an audio format from a file.

        Params:
            file = The path to the file.
    +/
    public void load(string file) @trusted
    {
        ubyte[] dat = cast(ubyte[]) read(file);

        if(cast(string) dat[0 .. 4] != "RIFF")
            throw new Exception("It not sound file!");

        ubyte[] cDat = dat[20 .. 36];
        audioFormat = cDat[0 .. 1].byteTo!ubyte;
        numChannels = cDat[1 .. 3].byteTo!ushort;
        sampleRate = cDat[3 .. 7].byteTo!uint;
        byteRate = cDat[7 .. 11].byteTo!uint;
        blockAlign = cDat[11 .. 13].byteTo!ushort;
        bitsPerSample = cDat[13 .. 15].byteTo!ushort;
        
        data = dat[44 .. $];
    }

    /// Free memory
    public void free() @trusted
    {
        destroy(data);
    }

    ~this() @trusted
    {
        free();
    }
}

/++
    Decoder for mp3.
+/
public class MP3 : Wav
{
    import mp3decoder;
    import mp3decoderex;

    override void load(string path) @trusted
    {
        import core.stdc.stdlib : free;

        mp3dec_t mp3d;
        mp3dec_file_info_t info = mp3dec_load(mp3d,path,null,null);

        audioFormat = 1;
        numChannels = cast(ushort) info.channels;
        sampleRate = info.hz;
        bitsPerSample = cast(ushort) info.avg_bitrate_kbps;

        data = cast(ubyte[]) info.buffer[0 .. info.samples].dup;
        free(cast(void*) info.buffer);
    }

    ~this() @safe
    {
        free();
    }
}