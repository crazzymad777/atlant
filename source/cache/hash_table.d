module atlant.cache.hash_table;

import atlant.filesystem.tree;
import atlant.utils.string;
import atlant.cache.gem;

// Hash-table -> bucket* -> gem[m]

struct HashTable
{
    private ulong count;
    this(TreeNode* root)
    {
        count = root.childsNumber;
        buckets = Array!(Bucket*)(count);

        int* capacity = fillCapacity(root);
        capacity[findBucketIndex(root.filename.hashOf())]++;
    }

    private int* fillCapacity(TreeNode* root)
    {
        import core.stdc.stdlib;
        import core.stdc.string;
        int *bucketCapacity = cast(int*) malloc(int.sizeof * count);
        memset(bucketCapacity, 0, int.sizeof * count);
        fillCapacityNode(root, bucketCapacity);
        return bucketCapacity;
    }

    void fillCapacityNode(TreeNode* parent, int *capacity)
    {
        import core.stdc.stdio;
        TreeNode* sibling = parent.firstChild;
        while (sibling !is null)
        {
            if (sibling.type == TreeNode.Type.file)
            {
                capacity[findBucketIndex(sibling.filename.hashOf())]++;
            }
            if (sibling.type == TreeNode.Type.directory)
            {
                capacity[findBucketIndex(sibling.filename.hashOf())]++;
                fillCapacityNode(sibling, capacity);
            }
            // if (sibling.type == TreeNode.Type.link)
            // {
            //     printf("l %s\n", sibling.uriPath.data);
            // }
            sibling = sibling.nextSibling;
        }
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
