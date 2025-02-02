module atlant.bucket;

import atlant.gem;

class Bucket
{
	private long length;
	public this(long capacity)
	{
		gems = new Gem[capacity];
	}
	private bool collision;
	private Gem[] gems;

	public void put(Gem newGem)
	{
		if (!this.collision)
		{
			for (long i = 0; i < length; i++)
			{
				if (gems[i].hash == newGem.hash)
				{
					this.collision = true;
				}
			}
		}

		gems[length] = newGem;
		length++;
	}

	public void analyze()
	{
		import std.stdio;
		writeln("Bucket #", this.hashOf());
		writeln("\tHash coliision: ", collision);
		foreach (x; gems)
		{
			if (x !is null)
			{
				x.analyze();
			}
		}
	}

	public Gem findByPath(string path, long hash)
	{
		if (collision)
		{
			for (int i = 0; i < length; i++)
			{
				if (gems[i].path == path)
				{
					return gems[i];
				}
			}
		}

		for (int i = 0; i < length; i++)
		{
			if (gems[i].hash == hash)
			{
				return gems[i];
			}
		}
		return null;
	}
}
