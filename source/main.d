import std.file: DirEntry, SpanMode, getcwd, dirEntries;
import std.process: environment;
import std.container.slist;
import vibe.vibe;

import atlant.hash_table;
import atlant.bucket;
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

HashTable gold;
string workingDirectory;

void main()
{
	Scanner scanner = new Scanner();

	auto directory = environment.get("ATLANT_OVERRIDE_DIRECTORY");
	if (directory is null)
	{
		directory = getcwd();
	}

	workingDirectory = directory;
	scanner.setDirectory(directory);
	scanner.scan();
	// scanner.process();
	gold = new HashTable(scanner.getCounter(), scanner.getGems());
	// gold.kovalskiAnalyze();

	auto port = environment.get("ATLANT_HTTP_PORT", "80");
	listenHTTP(":" ~ port, &handleRequest);
	runApplication();
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	auto gem = gold.search(req.path);
	if (gem !is null)
	{
		res.writeBody(cast(ubyte[]) gem.data, gem.mime);
	}
}

