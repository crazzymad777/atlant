import std.file: DirEntry, SpanMode, getcwd, dirEntries, read;
import std.process: environment, execute;
import std.container.slist;
import vibe.vibe;

class Gem
{
	public this(string reqPath, string fsPath, bool isDir)
	{
		this.path = reqPath;
		this.hash = object.hashOf(reqPath);

		if (isDir)
		{
			// index file
		}
		else
		{
			import std.string: strip;
			auto result = execute(["file", "-ib", fsPath]);
			auto mime = strip(result.output);
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

class Bucket
{
	private long length;
	public this(long capacity)
	{
		gems = new Gem[capacity];
	}
	private bool collision;
	private Gem[] gems;

	public void put(Gem newGem)
	{
		if (!this.collision)
		{
			for (long i = 0; i < length; i++)
			{
				if (gems[i].hash == newGem.hash)
				{
					this.collision = true;
				}
			}
		}

		gems[length] = newGem;
		length++;
	}

	public void analyze()
	{
		import std.stdio;
		writeln("Bucket #", this.hashOf());
		writeln("\tHash coliision: ", collision);
		foreach (x; gems)
		{
			if (x !is null)
			{
				x.analyze();
			}
		}
	}

	public Gem findByPath(string path, long hash)
	{
		if (collision)
		{
			for (int i = 0; i < length; i++)
			{
				if (gems[i].path == path)
				{
					return gems[i];
				}
			}
		}

		for (int i = 0; i < length; i++)
		{
			if (gems[i].hash == hash)
			{
				return gems[i];
			}
		}
		return null;
	}
}

class HashTable
{
	public long reducer;
	public this(long counter, SList!Gem gems)
	{
		reducer = counter;
		buckets = new Bucket[reducer];
		int[] counts = new int[reducer];
		foreach (x; gems)
		{
			long index = x.hash % reducer;
			x.reducedHash = index;
			counts[index]++;
		}

		foreach (x; gems)
		{
			long index = x.reducedHash;
			Bucket bucket = buckets[index];
			if (bucket is null)
			{
				bucket = new Bucket(counts[index]);
				buckets[index] = bucket;
			}

			bucket.put(x);
		}
	}
	private Bucket[] buckets;

	void kovalskiAnalyze()
	{
		import std.stdio;
		foreach (bucket; buckets)
		{
			if (bucket is null)
			{
				writeln("(Empty bucket)");
			}
			else
			{
				bucket.analyze();
			}
		}
	}

	public Gem search(string path)
	{
		import std.stdio;
		long hash = object.hashOf(path);
		//writeln(workingDirectory ~ path);
		//writeln(hash);

		long index = hash%reducer;
		Bucket bucket = buckets[index];
		if (bucket is null)
		{
			return null;
		}
		return bucket.findByPath(path, hash);
	}
}

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
		scanDirectory(directory, "/");
	}

	// public void process()
	// {
	// 	import std.stdio;
	// 	foreach(x; gems)
	// 	{
	// 		writeln(x.hash, ',', x.path);
	// 	}
	// }
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
	gold.kovalskiAnalyze();

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

