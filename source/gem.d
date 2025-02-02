module atlant.gem;

import std.process: execute;
import std.file: read;

interface ICutGem
{
    immutable(void)[] getData();
    string getMIME();
    bool checkDirty();
}

class Gem : ICutGem
{
    private this(string reqPath)
    {
        this.path = reqPath;
		this.hash = object.hashOf(reqPath);
    }

	public this(string reqPath, string fsPath, bool isDir)
	{
        uniqueHash = true;
        import std.string: strip;
		import std.file: exists;
		this(reqPath);

		if (isDir)
		{
			// index file
			// TODO: config indices files
			if (exists(fsPath ~ "/index.html"))
			{
				auto filename = fsPath ~ "/index.html";
				auto result = execute(["file", "-ib", filename]);
				mime = strip(result.output);
				data = cast(immutable(void)[]) read(filename);
			}
			else
			{
                /*
                    Track directory contents by default
                */
                dirty = true;
                track = true;
			}
		}
		else
		{
			auto result = execute(["file", "-ib", fsPath]);
			mime = strip(result.output);
			data = cast(immutable(void)[]) read(fsPath);
		}
	}
	public string path;
	public bool uniqueHash;
	public ulong hash;
	public bool track;
	public bool dirty;

	public string mime; // GEM
	immutable(void)[] data; // GEM

	public void analyze()
	{
		import std.stdio;
		writeln("\tGem #", hash, ',', path, ',', uniqueHash, ',', mime);
	}

	immutable(void)[] getData()
	{
        return data;
	}

    string getMIME()
    {
        return mime;
    }

    bool checkDirty()
    {
        return dirty;
    }
}

class ProxyGem : Gem
{
    private Gem link;
    public this(Gem original, string reqPath)
    {
        super(reqPath);
        link = original;
    }

    override immutable(void)[] getData()
	{
        return link.data;
	}

    override string getMIME()
    {
        return link.mime;
    }

    override bool checkDirty()
    {
        return link.dirty;
    }
}
