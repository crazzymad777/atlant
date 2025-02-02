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

	protected Gem scanDirectory(string path, string reqPath)
	{
		import std.string: representation;
		import std.array: appender;
		auto contents = appender!string;
		auto directoryGem = new Gem(reqPath, path, true);
		gems.insert(directoryGem);
		this.counter++;

		if (directoryGem.track)
		{
			contents.put("<!doctype html><html><head><title>Atlant ");
			contents.put(reqPath);
			contents.put("</title><style>table { width: 100%; }</style></head><body><h2>Atlant File Explorer ");
			contents.put(reqPath);
			contents.put("</h2><table><tr><td></td><td>Name</td><td>Content-Type</td><td>Request Path Hash</td><td>Content-Length</td></tr>");
			if (reqPath != "/")
			{
				contents.put("<tr><td>d</td><td><a href=\"..\">..</a></td><td></td><td></td><td></td></tr>");
			}
		}

		import std.path: baseName;
		foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
		{
			string name = baseName(entry.name);
			string fullPath = entry.name;
			string req = reqPath ~ name;

			Gem gem;
			if (entry.isDir())
			{
				gem = scanDirectory(fullPath, req ~ "/");
			}
			else
			{
				gem = new Gem(req, fullPath, false);
				gems.insert(gem);
				this.counter++;
			}

			if (directoryGem.track)
			{
				import std.conv;
				auto flags = "-";
				auto reqHtml = req;
				if (entry.isDir())
				{
					flags = "d";
					reqHtml ~= "/";
				}
				if (entry.isSymlink())
				{
					flags = "l";
				}
				contents.put("<tr><td>");
				contents.put(flags);
				contents.put("</td><td><a href=\"");
				contents.put(reqHtml);
				contents.put("\">");
				contents.put(name);
				contents.put("</a></td><td>");
				contents.put(gem.mime);
				contents.put("</td><td>0x");
				contents.put(to!string(gem.hash, 16));
				contents.put("</td><td>");
				contents.put(to!string(entry.size));
				contents.put("</td></tr>");
			}
		}

		if (directoryGem.track)
		{
			contents.put("</table></body></html>");

			directoryGem.data = contents.data().representation();
			directoryGem.mime = "text/html; charset=utf8";
		}
		return directoryGem;
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
