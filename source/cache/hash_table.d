module atlant.cache.hash_table;

import atlant.filesystem.tree;
import atlant.utils.string;
import atlant.cache.gem;

// Hash-table -> bucket* -> gem[m]

struct HashTable
{
    private ulong count;
    this(TreeNode root)
    {
        count = root.childsNumber;
    }

    import atlant.cache.bucket;
    import atlant.utils.array;
	private Array!(Bucket*) buckets;

	Bucket* findBucket(String* entry)
	{
        return getBucketByIndex(findBucketIndex(entry.hashOf()));
	}

	uint findBucketIndex(uint number)
	{
        uint rem = number%count;
        return rem;
	}

	Bucket* getBucketByIndex(uint index)
	{
        return buckets.at(index);
	}

	Gem* getGem(String* entry)
	{
		Bucket* bucket = findBucket(entry);
		if (bucket is null)
		{
			return null;
		}
		return bucket.find(entry);
	}
}
