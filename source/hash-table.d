module atlant.hash_table;

import std.container.slist;
import atlant.bucket;
import atlant.gem;

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
