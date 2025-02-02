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

class FileGem : CutGem
{
	private this(string reqPath)
	{
		uniqueHash = true;
		super(reqPath);
		payload = new GemData();
	}

	public this(string reqPath, string fsPath, bool isDir)
	{
        import std.string: strip;
		this(reqPath);

		auto result = execute(["file", "-ib", fsPath]);
		payload.mime = strip(result.output);
		payload.data = cast(immutable(void)[]) read(fsPath);
	}
}

class DirGem : FileGem
{
	public this(string reqPath, string fsPath, bool isDir)
	{
		import std.file: exists;
        import std.string: strip;
		super(reqPath);

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
	public bool track;
}


class ProxyGem : CutGem
{
	public this(CutGem original, string reqPath)
	{
		uniqueHash = true;
		super(reqPath);
		payload = original.payload;
	}
}
