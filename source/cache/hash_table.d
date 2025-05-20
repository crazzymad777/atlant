module atlant.cache.hash_table;

import atlant.filesystem.tree;
import atlant.utils.string;
import atlant.cache.gem;

// Hash-table -> bucket* -> gem[m]

struct HashTable
{
    private size_t count;
    private int* capacity;
    this(TreeNode* root)
    {
        import core.stdc.stdlib;
        count = root.childsNumber + 1; // +1 for root itself
        buckets = Array!(Bucket*)(count);

        capacity = fillCapacity(root);
        capacity[findBucketIndex(root.uriPath.hashOf())]++;

        put(root);
        free(capacity);
    }

    private void put(TreeNode* root)
    {
        putNode(root);
        if (root.index !is null)
        {
            putLink(root, root.index);
        }
    }

    private void putLink(TreeNode* node, TreeNode* link)
    {
        auto index = findBucketIndex(node.uriPath.hashOf());
        Bucket* bucket = buckets.at(index);
        if (bucket is null)
        {
            bucket = Bucket.of(capacity[index]);
            buckets.put(index, bucket);
        }
        Gem* gem = Gem.of(node, link);

        if (gem !is null)
        {
            bucket.put(gem);
        }
        else
        {
            import core.stdc.stdio;
            if (node != link)
            {
                printf("Load of gem /%s (linked to /%s) failed\n", node.uriPath.data, link.uriPath.data);
            }
            else
            {
                printf("Load of gem /%s failed\n", node.uriPath.data, link.uriPath.data);
            }
        }
    }

    private void putNode(TreeNode* parent)
    {
        TreeNode* sibling = parent.firstChild;
        while (sibling !is null)
        {
            if (sibling.type == TreeNode.Type.file || sibling.type == TreeNode.Type.link)
            {
                putLink(sibling, sibling);
            }
            if (sibling.type == TreeNode.Type.directory)
            {
                putNode(sibling);
                if (sibling.index !is null)
                {
                    putLink(sibling, sibling.index);
                }
            }
            sibling = sibling.nextSibling;
        }
    }

    private int* fillCapacity(TreeNode* root)
    {
        import core.stdc.stdlib;
        import core.stdc.string;
        int *bucketCapacity = cast(int*) malloc(int.sizeof * count);
        memset(bucketCapacity, 0, int.sizeof * count);

        capacity = bucketCapacity;
        fillCapacityNode(root);
        return bucketCapacity;
    }

    void fillCapacityNode(TreeNode* parent)
    {
        import core.stdc.stdio;
        TreeNode* sibling = parent.firstChild;
        while (sibling !is null)
        {
            if (sibling.type == TreeNode.Type.file || sibling.type == TreeNode.Type.link)
            {
                capacity[findBucketIndex(sibling.uriPath.hashOf())]++;
            }
            if (sibling.type == TreeNode.Type.directory)
            {
                capacity[findBucketIndex(sibling.uriPath.hashOf())]++;
                fillCapacityNode(sibling);
            }
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

    void show()
    {
        for (int i = 0; i < count; i++)
        {
            auto bucket = getBucketByIndex(i);
            if (bucket !is null)
            {
                bucket.show();
            }
        }
    }

    void drop()
    {
        for (int i = 0; i < count; i++)
        {
            auto bucket = getBucketByIndex(i);
            if (bucket !is null)
            {
                bucket.drop();
            }
        }
    }
}
