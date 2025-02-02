module atlant.gem;

import std.process: execute;
import std.file: read;

class Gem
{
	public this(string reqPath, string fsPath, bool isDir)
	{
        import std.string: strip;
		import std.file: exists;
		this.path = reqPath;
		this.hash = object.hashOf(reqPath);

		if (isDir)
		{
			// index file
			// TODO: config indices files
			if (exists(fsPath ~ "/index.html"))
			{
				auto filename = fsPath ~ "/index.html";
				auto result = execute(["file", "-ib", filename]);
				mime = strip(result.output);
				data = read(filename);
			}
			/*
				Show directory contents by default?
			*/
		}
		else
		{
			auto result = execute(["file", "-ib", fsPath]);
			mime = strip(result.output);
			data = read(fsPath);
		}
	}
	public string mime;
	public ulong reducedHash;
	public string path;
	public ulong hash;
	void[] data;

	public void analyze()
	{
		import std.stdio;
		writeln("\tGem #", hash, ',', path, ',', mime);
	}
}
