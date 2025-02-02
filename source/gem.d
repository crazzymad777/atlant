module atlant.gem;

import std.process: execute;
import std.file: read;

struct GemData
{
    public string mime;
	immutable(void)[] data;
	public bool dirty;
}

class CutGem
{
    private this(string reqPath)
    {
        this.path = reqPath;
		this.hash = object.hashOf(reqPath);
    }

    public bool uniqueHash;
	public string path;
	public ulong hash;
	public GemData* payload;

	public void analyze()
	{
		import std.stdio;
		writeln("\tGem #", hash, ',', path, ',', uniqueHash, ',', payload.mime);
	}
}

class Gem : CutGem
{
	public this(string reqPath, string fsPath, bool isDir)
	{
        uniqueHash = true;
        import std.string: strip;
		import std.file: exists;
		super(reqPath);
		payload = new GemData();

		if (isDir)
		{
			// index file
			// TODO: config indices files
			if (exists(fsPath ~ "/index.html"))
			{
				auto filename = fsPath ~ "/index.html";
				auto result = execute(["file", "-ib", filename]);
				payload.mime = strip(result.output);
				payload.data = cast(immutable(void)[]) read(filename);
			}
			else
			{
                /*
                    Track directory contents by default
                */
                payload.dirty = true;
                track = true;
			}
		}
		else
		{
			auto result = execute(["file", "-ib", fsPath]);
			payload.mime = strip(result.output);
			payload.data = cast(immutable(void)[]) read(fsPath);
		}
	}
	public bool track;
}

class ProxyGem : CutGem
{
	public this(Gem original, string reqPath)
	{
		uniqueHash = true;
		super(reqPath);
		payload = original.payload;
	}
}
