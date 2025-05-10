module atlant.cache.hash_table;

import atlant.filesystem.tree;

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

	uint findBucketIndex(uint number)
	{
        uint rem = number%count;
        return rem;
	}

	Bucket* getBucketByIndex(uint index)
	{
        return buckets.at(index);
	}
}
