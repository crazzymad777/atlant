module atlant.cache.bucket;

import atlant.utils.string;
import atlant.utils.array;
import atlant.cache.gem;

// Bucket contains gems with same perfect hash
struct Bucket
{
	static Bucket* of(long capacity)
	{
		import core.stdc.stdlib;
		Bucket* bucket = cast(Bucket*) malloc(Bucket.sizeof);
		bucket.gems = Array!(Gem*)(capacity);
		bucket.length = 0;
		return bucket;
	}

	public this(long capacity)
	{
		gems = Array!(Gem*)(capacity);
	}
	private long length;
	private Array!(Gem*) gems;

	public void put(Gem* newGem)
	{
		for (long i = 0; i < length; i++)
		{
            Gem* gem = gems.at(i);
			if (gem.hash == newGem.hash)
			{
				gem.uniqueHash = false;
				newGem.uniqueHash = false;
			}
		}

		gems.put(length, newGem);
		length++;
	}

	Gem* find(String* entry)
	{
        int i = 0;
		for (; i < length; i++)
		{
            Gem* gem = gems.at(i);
			if (gem.hash == entry.hashOf())
			{
				if (gem.uniqueHash)
				{
					break;
				}
				else if (entry.equals(&gem.node.uriPath))
				{
					break;
				}
			}
		}
		return i != length ? gems.at(i) : null;
	}

	public void show()
	{
		for (long i = 0; i < length; i++)
		{
            gems.at(i).show();
		}
	}

	public void drop()
	{
		for (long i = 0; i < length; i++)
		{
            gems.at(i).drop();
		}
	}
}
