/++

+/
module tida.sound.al;

public void initSoundLibrary() @trusted
{
    import bindbc.openal;

    auto ret = loadOpenAL();

    if(ret == ALSupport.noLibrary)
        throw new Exception("Not load OpenAL!");
}

public class Device
{
    import bindbc.openal;

    private
    {
        ALCdevice* device;
        ALCcontext* context;
    }

    this() @trusted
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
}

public class Sound
{
    import bindbc.openal;

    private
    {
        uint _source;
        uint _buffer;
        ubyte[] _bufferData;
    }

    this() @safe
    {
        this.allocateSource();
        this.allocateBuffer();
    }

    public void allocateSource() @trusted
    {
        alGenSources(1,&_source);

        alSourcef(_source, AL_PITCH, 1);
        alSourcef(_source, AL_GAIN, 1.0f);
        alSource3f(_source, AL_POSITION, 0, 0, 0);
        alSource3f(_source, AL_VELOCITY, 0, 0, 0);
        alSourcei(_source, AL_LOOPING, AL_TRUE);
    }

    public void allocateBuffer() @trusted
    {
        alGenBuffers(1,&_buffer);
    }

    public void bindWAV(Wav wave) @trusted
    {
        const format = wave.numChannels > 1 ?
            (wave.bitsPerSample == 8 ? AL_FORMAT_STEREO8 : AL_FORMAT_STEREO16) :
            (wave.bitsPerSample == 8 ? AL_FORMAT_MONO8 : AL_FORMAT_MONO16);

        _bufferData = wave.data;

        alBufferData(_buffer,format,cast(void*) _bufferData,
        cast(int) _bufferData.length, wave.sampleRate);
    }

    public void sourceBindBuffer() @trusted
    {
        alSourcei(_source, AL_BUFFER, _buffer);
    }

    public void play() @trusted
    {
        alSourcePlay(_source);
    }
}

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data |= cast(T) (((data & 0xFF) << 8) + bytes[i]);

    return data;
}

public class Wav
{
    import std.file;

    public
    {
        ushort audioFormat;
        ushort numChannels;
        uint sampleRate;
        uint byteRate;
        ushort blockAlign;
        ushort bitsPerSample;
        ubyte[] data;
        uint size;
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

    public Wav load(string file) @trusted
    {
        ubyte[] dat = cast(ubyte[]) read(file);

        if(cast(string) dat[0 .. 4] != "RIFF")
            throw new Exception("It not sound file!");

        ubyte[] cDat = dat[19 .. 35];
        audioFormat = cDat[0 .. 2].byteTo!ushort;
        numChannels = cDat[2 .. 4].byteTo!ushort;
        sampleRate = cDat[4 .. 8].byteTo!uint;
        byteRate = cDat[8 .. 12].byteTo!uint;
        blockAlign = cDat[12 .. 14].byteTo!ushort;
        bitsPerSample = cDat[14 .. 16].byteTo!ushort;
        
        data = dat[44 .. $];

        return this;
    }
}