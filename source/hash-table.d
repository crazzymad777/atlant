module atlant.hash_table;

import std.container.slist;
import atlant.utils.array;
import atlant.gem;

struct Bucket
{
	public this(long capacity)
	{
		gems = Array!(CutGem*)(capacity);
	}
	private long length;
	private Array!(CutGem*) gems;

	public void put(CutGem* newGem)
	{
		for (long i = 0; i < length; i++)
		{
			if (gems.at(i).hash == newGem.hash)
			{
				gems.at(i).uniqueHash = false;
				newGem.uniqueHash = false;
			}
		}

		gems.put(length, newGem);
		length++;
	}

	public CutGem* find(string path, long hash)
	{
		int i = 0;
		for (; i < length; i++)
		{
			if (gems.at(i).hash == hash)
			{
				if (gems.at(i).uniqueHash)
				{
					break;
				}
				else if (gems.at(i).path == path)
				{
					break;
				}
			}
		}
		return i != length ? gems.at(i) : null;
	}
}

struct HashTable
{
	private Array!(Bucket*) buckets;
	public long reducer;
	public this(long counter, SList!(CutGem*) gems)
	{
		reducer = counter;
		buckets = Array!(Bucket*)(reducer);
		int[] counts = new int[reducer];
		foreach (x; gems)
		{
			long index = x.hash % reducer;
			counts[index]++;
		}

		foreach (x; gems)
		{
			long index = x.hash % reducer;
			Bucket* bucket = buckets.at(index);
			if (bucket is null)
			{
				bucket = new Bucket(counts[index]);
				buckets.put(index, bucket);
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
		Bucket* bucket = buckets.at(index);
		if (bucket is null)
		{
			return null;
		}
		return bucket.find(path, hash);
	}
}
