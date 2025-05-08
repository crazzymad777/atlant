module atlant.cache.hash_table;

// Hash-table -> bucket* -> gem[m]

uint touch(uint number, uint N)
{
    int rem = number%N;
    return rem;
}

struct HashTable
{
    import atlant.cache.bucket;
    import atlant.utils.array;
	private Array!(Bucket*) buckets;
}
