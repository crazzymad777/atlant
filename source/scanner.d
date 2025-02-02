module atlant.scanner;

import std.file: DirEntry, SpanMode, dirEntries;
import std.container.slist;
import atlant.hash_table;
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

			if (entry.isDir())
			{
				scanDirectory(fullPath, req ~ "/");
			}
			else
			{
				gems.insert(new Gem(req, fullPath, false));
				this.counter++;
			}
		}
		gems.insert(new Gem(reqPath, path, true));
		this.counter++;
	}

	public void scan()
	{
		gems = SList!Gem();
		counter = 0;
		scanDirectory(directory, "/");
	}

	public HashTable build()
	{
        return new HashTable(this.getCounter(), this.getGems());
	}
}
