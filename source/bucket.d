module atlant.bucket;

import atlant.gem;

class Bucket
{
	public this(long capacity)
	{
		gems = new CutGem[capacity];
	}
	private long length;
	private CutGem[] gems;

	public void put(CutGem newGem)
	{
		for (long i = 0; i < length; i++)
		{
			if (gems[i].hash == newGem.hash)
			{
				gems[i].uniqueHash = false;
				newGem.uniqueHash = false;
			}
		}

		gems[length] = newGem;
		length++;
	}

	public void analyze()
	{
		import std.stdio;
		writeln("Bucket #", this.hashOf());
		// writeln("\tHash coliision: ", collision);
		foreach (x; gems)
		{
			if (x !is null)
			{
				x.analyze();
			}
		}
	}

	public CutGem findByPath(string path, long hash)
	{
        int i = 0;
		for (; i < length; i++)
		{
			if (gems[i].hash == hash)
			{
				if (gems[i].uniqueHash)
				{
					break;
				}
				else if (gems[i].path == path)
				{
					break;
				}
			}
		}
		return i != length ? gems[i] : null;
	}
}
