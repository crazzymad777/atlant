module atlant.scanner;

import std.file: DirEntry, SpanMode, dirEntries;
import std.container.slist;
import atlant.gem;

class Scanner
{
	private string directory;
	private SList!Gem gems;
	private long counter;

	public long getCounter()
	{
		return counter;
	}

	public auto getGems()
	{
		return gems;
	}

	public void setDirectory(string directory)
	{
		this.directory = directory;
	}

	protected void scanDirectory(string path, string reqPath)
	{
		import std.path: baseName;
		foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
		{
			string name = baseName(entry.name);
			string fullPath = entry.name;
			string req = reqPath ~ name;

			gems.insert(new Gem(req, fullPath, entry.isDir()));
			this.counter++;
			if (entry.isDir())
			{
				scanDirectory(fullPath, req ~ "/");
			}
		}
	}

	public void scan()
	{
		gems = SList!Gem();
		counter = 0;

		gems.insert(new Gem("/", directory, true));
		this.counter++;
		scanDirectory(directory, "/");
	}
}
