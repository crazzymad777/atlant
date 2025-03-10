module atlant.hash_table;

import std.container.slist;
import atlant.gem;

struct Bucket
{
	public this(long capacity)
	{
		gems = new CutGem*[capacity];
	}
	private long length;
	private CutGem*[] gems;

	public void put(CutGem* newGem)
	{
		for (long i = 0; i < length; i++)
		{
			if (gems[i].hash == newGem.hash)
			{
				gems[i].uniqueHash = false;
				newGem.uniqueHash = false;
			}
		}

		gems[length] = newGem;
		length++;
	}

	public CutGem* find(string path, long hash)
	{
		int i = 0;
		for (; i < length; i++)
		{
			if (gems[i].hash == hash)
			{
				if (gems[i].uniqueHash)
				{
					break;
				}
				else if (gems[i].path == path)
				{
					break;
				}
			}
		}
		return i != length ? gems[i] : null;
	}
}

struct HashTable
{
	private Bucket*[] buckets;
	public long reducer;
	public this(long counter, SList!(CutGem*) gems)
	{
		reducer = counter;
		buckets = new Bucket*[reducer];
		int[] counts = new int[reducer];
		foreach (x; gems)
		{
			long index = x.hash % reducer;
			counts[index]++;
		}

		foreach (x; gems)
		{
			long index = x.hash % reducer;
			Bucket* bucket = buckets[index];
			if (bucket is null)
			{
				bucket = new Bucket(counts[index]);
				buckets[index] = bucket;
			}

			bucket.put(x);
		}

		rehash();
	}

	public void rehash()
	{
		// hashMap.rehash;
	}

	public CutGem* search(string path)
	{
		if (path[path.length-1] != '/')
		{
			path ~= '/';
		}

		long hash = object.hashOf(path);
		long index = hash%reducer;
		Bucket* bucket = buckets[index];
		if (bucket is null)
		{
			return null;
		}
		return bucket.find(path, hash);
	}
}
