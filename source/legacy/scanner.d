module atlant.scanner;

// import std.file: DirEntry, SpanMode, dirEntries;
import atlant.utils.configuration;
import atlant.utils.list;
import atlant.hash_table;
import atlant.gem;

struct Scanner
{
	private Configuration* conf;
	private List!(CutGem*) gems;
	private long counter;

	public void configure(Configuration* conf)
	{
		this.conf = conf;
	}

	public long getCounter()
	{
		return counter;
	}

	public auto getGems()
	{
		return gems;
	}

	protected CutGem* scanDirectory(char* path, string reqPath)
	{
		return null;
	}

	public void scan()
	{
		//gems = SList!(CutGem*)();
		counter = 0;
		// scanDirectory(conf.workingDirectory, "");
	}

	public HashTable build(bool lazyLoad)
	{
		// if (!lazyLoad)
		// {
		// 	foreach (gem; this.getGems())
		// 	{
		// 		gem.load();
		// 	}
		// }
		return HashTable(this.getGems());
		// return HashTable();
	}
}
