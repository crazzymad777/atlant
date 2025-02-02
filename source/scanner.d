module atlant.scanner;

import std.file: DirEntry, SpanMode, dirEntries;
import std.container.slist;
import atlant.hash_table;
import atlant.gem;

class Scanner
{
	private bool trackDirectories = false;
	private string directory;
	private SList!CutGem gems;
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

	public void setDirectoryList(bool flag)
	{
		this.trackDirectories = flag;
	}

	protected DirGem scanDirectory(string path, string reqPath)
	{
		auto directoryGem = new DirGem(reqPath ~ "/", path, this.trackDirectories, DirEntry(path));
		auto proxyGem = new ProxyGem(directoryGem, reqPath);

		gems.insert(directoryGem);
		this.counter++;
		gems.insert(proxyGem);
		this.counter++;

		reqPath ~= "/";

		import std.path: baseName;
		foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
		{
			string name = baseName(entry.name);
			string fullPath = entry.name;
			string req = reqPath ~ name;

			try
			{
				if (entry.isDir())
				{
					DirGem child = scanDirectory(fullPath, req);
					if (this.trackDirectories)
					{
						directoryGem.subdirectories.insert(child);
					}
				}
				else
				{
					FileGem gem = new FileGem(req, fullPath, entry);
					gems.insert(gem);
					this.counter++;
					if (this.trackDirectories)
					{
						directoryGem.files.insert(gem);
					}
				}
			}
			catch (Exception e)
			{
			}
		}

		return directoryGem;
	}

	public void scan()
	{
		gems = SList!CutGem();
		counter = 0;
		scanDirectory(directory, "");
	}

	public HashTable build(bool lazyLoad)
	{
		if (!lazyLoad)
		{
			foreach (gem; this.getGems())
			{
				gem.load();
			}
		}
		return new HashTable(this.getCounter(), this.getGems());
	}
}
