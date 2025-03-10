module atlant.hash_table;

import std.container.slist;
import atlant.gem;

struct HashTable
{
	CutGem[string] hashMap;
	public this(long counter, SList!CutGem gems)
	{
		foreach (x; gems)
		{
			hashMap[x.path] = x;
		}
		rehash();
	}

	public void rehash()
	{
		hashMap.rehash;
	}

	public CutGem search(string path)
	{
		auto x = path in hashMap;
		if (x is null)
		{
			return null;
		}
		return *x;
	}
}
