module atlant.gem;

import std.process: execute;
import std.file: DirEntry;
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

	abstract public void touch(); // Gentle touch
	abstract public void load();
}

class FileGem : CutGem
{
	private string fsPath;
	public DirEntry entry;

	private this(string reqPath)
	{
		uniqueHash = true;
		super(reqPath);
		payload = new GemData();
	}

	public this(string reqPath, string fsPath, DirEntry entry)
	{
		this(reqPath);
		this.fsPath = fsPath;
		this.entry = entry;
	}

	override
	public void load()
	{
		import std.string: strip;
		auto result = execute(["file", "-ib", fsPath]);
		payload.mime = strip(result.output);
		payload.data = cast(immutable(void)[]) read(fsPath);
	}

	override
	public void touch()
	{
		if (payload.mime is null)
		{
			import std.string: strip;
			auto result = execute(["file", "-ib", fsPath]);
			payload.mime = strip(result.output);
		}
	}
}

import std.container.slist;

class DirGem : FileGem
{
	// Filled only if scanner track directories enabled
	public SList!DirGem subdirectories;
	public SList!FileGem files;
	private bool track;

	public this(string reqPath, string fsPath, bool track, DirEntry entry)
	{
		super(reqPath);
		this,fsPath = fsPath;
		payload.dirty = true;
		this.track = track;
		this.entry = entry;
	}

	override
	public void load()
	{
		import std.file: exists;
        import std.string: strip;
		// index file
		// TODO: config indices files
		if (exists(fsPath ~ "/index.html"))
		{
			auto filename = fsPath ~ "/index.html";
			auto result = execute(["file", "-ib", filename]);
			payload.mime = strip(result.output);
			payload.data = cast(immutable(void)[]) read(filename);
			payload.dirty = false;
		}
		else
		{
			/*
				Track directory contents by default
			*/
			if (track)
			{
				import std.range: chain;
				import std.string: representation;
				import std.array: appender;
				auto contents = appender!string;
				contents.put("\x3c!doctype html>\x3chtml>\x3chead>\x3ctitle>Atlant ");
				contents.put(path);
				contents.put("\x3c/title>\x3cstyle>table { width: 100%; }\x3c/style>\x3c/head>\x3cbody>\x3ch2>Atlant File Explorer ");
				contents.put(path);
				contents.put("\x3c/h2>\x3ctable>\x3ctr>\x3ctd>\x3c/td>\x3ctd>Name\x3c/td>\x3ctd>Content-Type\x3c/td>\x3ctd>Request Path Hash\x3c/td>\x3ctd>Content-Length\x3c/td>\x3c/tr>");
				if (path != "/")
				{
					contents.put("\x3ctr>\x3ctd>d\x3c/td>\x3ctd>\x3ca href=\"..\">..\x3c/a>\x3c/td>\x3ctd>\x3c/td>\x3ctd>\x3c/td>\x3ctd>\x3c/td>\x3c/tr>");
				}

				//auto middle = appender!FileGem;
				//middle.put(files);
				auto x = chain(subdirectories[], files[]);
				//SList!FileGem x = (cast(SList!FileGem)subdirectories) ~ ;

				foreach (gem; x)
				{
					import std.path: baseName;
					import std.conv;

					auto flags = "-";
					auto reqHtml = gem.path;
					auto entry = gem.entry;
					if (entry.isDir())
					{
						flags = "d";
						reqHtml ~= "/";
					}
					if (entry.isSymlink())
					{
						flags = "l";
					}
					contents.put("\x3ctr>\x3ctd>");
					contents.put(flags);
					contents.put("\x3c/td>\x3ctd>\x3ca href=\"");
					contents.put(reqHtml);
					contents.put("\">");
					contents.put(baseName(entry));
					contents.put("\x3c/a>\x3c/td>\x3ctd>");
					contents.put(gem.payload.mime);
					contents.put("\x3c/td>\x3ctd>0x");
					contents.put(to!string(gem.hash, 16));
					contents.put("\x3c/td>\x3ctd>");
					contents.put(to!string(entry.size));
					contents.put("\x3c/td>\x3c/tr>");
				}

				contents.put("\x3c/table>\x3c/body>\x3c/html>");

				this.payload.dirty = false;
				this.payload.data = contents.data().representation();
				this.payload.mime = "text/html; charset=utf-8";
			}
			else
			{
				payload.dirty = true;
			}
		}
	}

	override
	public void touch()
	{
	}
}

class ProxyGem : CutGem
{
	public this(CutGem original, string reqPath)
	{
		uniqueHash = true;
		super(reqPath);
		payload = original.payload;
	}

	override
	public void load()
	{

	}

	override
	public void touch()
	{

	}
}
