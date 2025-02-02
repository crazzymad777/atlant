import std.file: DirEntry, SpanMode, getcwd, dirEntries;
import std.process: environment;
import std.container.slist;
import vibe.vibe;

class Gem
{
	public this(string path)
	{
		this.path = path;
		this.hash = object.hashOf(path);
	}
	public ulong reducedHash;
	public string path;
	public ulong hash;
}

class Bucket
{
	private bool collision;
	private Gem[] gems;
}

class HashTable
{
	public long reducer;
	public this(long counter, SList!Gem gems)
	{
		reducer = counter;
		buckets = new Bucket[counter];
		int[] counts = new int[counter];
		foreach (x; gems)
		{
			long index = x.hash % reducer;
			x.reducedHash = index;
			counts[index]++;
		}

		import std.stdio;
		bool perfect = true;
		for (int i = 0; i < counter; i++)
		{
			if(counts[i] != 1)
			{
				perfect = false;
				break;
			}
		}

		stderr.writeln("The Best Random Access: ", perfect);

		// Bucket bucket = buckets[index];
		// if (bucket is null)
		// {
		// 	bucket = new Bucket();
		// 	buckets[index] = bucket;
		// }
  //
		// if (!bucket.collision)
		// {
		// 	if (bucket.gems !is null)
		// 	{
		// 		foreach (y; bucket.gems)
		// 		{
		// 			if (y.hash == x.hash)
		// 			{
		// 				bucket.collision = true;
		// 			}
		// 		}
		// 	}
		// }
  //
		// auto bucketGems = bucket.gems;
		// if (bucketGems !is null)
		// {
		// 	bucketGems = new Gem[0]();
		// }
	}
	private Bucket[] buckets;
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

	protected void scanDirectory(string path)
	{
		foreach(DirEntry entry; dirEntries(path, SpanMode.shallow))
		{
			string fullPath = entry.name;
			gems.insert(new Gem(fullPath));
			this.counter++;
			if (entry.isDir())
			{
				scanDirectory(fullPath);
			}
		}
	}

	public void scan()
	{
		gems = SList!Gem();
		counter = 0;
		scanDirectory(directory);
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

void main()
{
	Scanner scanner = new Scanner();

	auto directory = environment.get("ATLANT_OVERRIDE_DIRECTORY");
	if (directory is null)
	{
		directory = getcwd();
	}

	scanner.setDirectory(directory);
	scanner.scan();
	// scanner.process();
	gold = new HashTable(scanner.getCounter(), scanner.getGems());

	auto port = environment.get("ATLANT_HTTP_PORT", "80");
	listenHTTP(":" ~ port, &handleRequest);
	runApplication();
}

void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
{
	if (req.path == "/")
		res.writeBody("Hello, World!");
}

