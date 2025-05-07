module atlant.hash_table;

import atlant.utils.array;
import atlant.utils.list;
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

	public CutGem* find(long hash)
	{
		int i = 0;
		for (; i < length; i++)
		{
			if (gems.at(i).hash == hash)
			{
				break;
				// if (gems.at(i).uniqueHash)
				// {
				// 	break;
				// }
				// else if (gems.at(i).path == path)
				// {
				// 	break;
				// }
			}
		}
		return i != length ? gems.at(i) : null;
	}
}

struct HashTable
{
	private Array!(Bucket*) buckets;
	public long reducer;
	public this(List!(CutGem*) gems)
	{
		import core.stdc.stdlib;

		reducer = gems.length;
		buckets = Array!(Bucket*)(reducer);
		int* counts = cast(int*) malloc(int.sizeof * reducer);//new int[reducer];

		auto node = gems.front();
		while (node != null)
		{
			auto x = node.value;
			long index = x.hash % reducer;
			counts[index]++;
			node = node.next;
		}

		while (node != null)
		{
			auto x = node.value;
			long index = x.hash % reducer;
			Bucket* bucket = buckets.at(index);
			if (bucket is null)
			{
				bucket = cast(Bucket*) malloc(counts[index] * Bucket.sizeof); //new Bucket(counts[index]);
				buckets.put(index, bucket);
			}

			bucket.put(x);
			node = node.next;
		}

		free(counts);
		rehash();
	}

	public void rehash()
	{
		// hashMap.rehash;
	}

	public CutGem* search(char* path)
	{
		import atlant.utils.hash;

		long hash = hashOf!true(path);
		long index = hash%reducer;
		Bucket* bucket = buckets.at(index);
		if (bucket is null)
		{
			return null;
		}
		return bucket.find(hash);
	}
}
