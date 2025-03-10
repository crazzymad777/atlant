module atlant.gem;

import std.file: FileException;
import std.process: execute;
import std.file: DirEntry;
import std.file: read;

import atlant.utils.configuration;
__gshared Configuration* gemConf;

struct GemData
{
	public string mime;
	immutable(void)[] data;
	public bool dirty;
	public bool loaded;
	// public bool forbidden;
}

import std.container.slist;

struct CutGem
{
	enum Type
	{
		Directory,
		File
	}
	Type type;

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

	public void touch() // Gentle touch
	{
		if (type == Type.File)
		{
			if (payload.mime is null)
			{
				import std.string: strip;
				auto result = execute(["file", "-ibL", fsPath]);
				payload.mime = strip(result.output);
			}
		}
	}

	public void load()
	{
		if (type == Type.File)
		{
			import std.string: strip;
			auto result = execute(["file", "-ibL", fsPath]);
			payload.mime = strip(result.output);
			try
			{
				payload.data = cast(immutable(void)[]) read(fsPath);
				// payload.dirty = false;
			}
			catch (FileException e)
			{
				payload.dirty = true;
			}
			payload.loaded = true;
		}
		else if (type == Type.Directory)
		{
			import std.file: exists;
			import std.string: strip;
			// index file
			string[] index = gemConf.index;
			payload.dirty = true;
			for (int i = 0; i < index.length; i++) //
			{
				if (exists(entry.name ~ "/" ~ index[i]))
				{
					auto filename = entry.name ~ "/" ~ index[i];
					auto result = execute(["file", "-ibL", filename]);
					payload.mime = strip(result.output);
					try
					{
						payload.data = cast(immutable(void)[]) read(filename);
						payload.dirty = false;
						break;
					}
					catch (FileException e)
					{
						payload.dirty = true;
					}
				}
			}

			if (payload.dirty)
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

					auto x = chain(subdirectories[], files[]);
					foreach (gem; x)
					{
						import std.path: baseName;
						import std.conv;
						gem.touch();

						auto flags = "-";
						auto entry = gem.entry;
						if (entry.isDir())
						{
							flags = "d";
						}
						if (entry.isSymlink())
						{
							flags ~= "l";
						}
						else
						{
							flags ~= "-";
						}

						contents.put("\x3ctr>\x3ctd>");
						contents.put(flags);
						contents.put("\x3c/td>\x3ctd>\x3ca href=\"");
						contents.put(gem.path);
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
			payload.loaded = true;
		}
	}

	private string fsPath;
	public DirEntry entry;

	public static CutGem* fileOf(string reqPath, string fsPath, DirEntry entry)
	{
		if (reqPath[reqPath.length-1] != '/')
		{
			reqPath ~= '/';
		}

		auto gem = new CutGem(reqPath);
		gem.uniqueHash = true;
		gem.payload = new GemData();
		gem.fsPath = fsPath;
		gem.entry = entry;
		gem.type = Type.File;
		return gem;
	}

	public SList!(CutGem*) subdirectories;
	public SList!(CutGem*) files;
	private bool track;

	public static CutGem* directoryOf(string reqPath, string fsPath, bool track, DirEntry entry)
	{
		auto gem = new CutGem(reqPath);
		gem.uniqueHash = true;
		gem.payload = new GemData();
		gem,fsPath = fsPath;
		gem.track = track;
		gem.entry = entry;
		gem.type = Type.Directory;
		return gem;
	}
}
