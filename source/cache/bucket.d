module atlant.cache.bucket;

import atlant.utils.string;
import atlant.utils.array;
import atlant.cache.gem;

// Bucket contains gems with same perfect hash
struct Bucket
{
	static Bucket* of(size_t capacity)
	{
		import core.stdc.stdlib;
		Bucket* bucket = cast(Bucket*) malloc(Bucket.sizeof);
		bucket.gems = Array!(Gem*)(capacity);
		bucket.length = 0;
		return bucket;
	}

	public this(size_t capacity)
	{
		gems = Array!(Gem*)(capacity);
	}
	private size_t length;
	private Array!(Gem*) gems;

	public void put(Gem* newGem)
	{
		for (size_t i = 0; i < length; i++)
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
		Gem* gem;
		for (; i < length; i++)
		{
            gem = gems.at(i);
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
		return i != length ? gem : null;
	}

	public void show()
	{
		for (size_t i = 0; i < length; i++)
		{
            gems.at(i).show();
		}
	}

	public void drop()
	{
		for (size_t i = 0; i < length; i++)
		{
            gems.at(i).drop();
		}
	}
}
